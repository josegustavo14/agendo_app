# Testes de ViewModels

Suíte de testes unitários que cobre cada `ChangeNotifier` em `lib/view_models/`.
Padrão: **1 viewmodel = 1 arquivo de teste** com o mesmo nome + sufixo `_test`.

## Convenção comum

Todos os arquivos seguem o mesmo formato:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:agendo/repositories/x_repository.dart';
import 'package:agendo/view_models/x_view_model.dart';

class MockXRepository extends Mock implements XRepository {}

void main() {
  late MockXRepository repository;
  late XViewModel viewModel;

  setUp(() {
    repository = MockXRepository();
    viewModel = XViewModel(repository: repository);
  });

  test('starts in idle state', () { /* ... */ });
  test('success path', () async { /* ... */ });
  test('failure path', () async { /* ... */ });
}
```

- **Sem HTTP de verdade.** O `repository` é mockado com `mocktail`. Nenhum
  teste depende de servidor de pé.
- **Sem `SharedPreferences` ou Firebase reais.** O `TokenStorage` e tudo
  que vier do device é mockado.
- **Asserções olham estado público do viewmodel** (`isLoading`, `errorMessage`,
  campos de dado) e eventos do `ChangeNotifier` (registrando um listener).

---

## Inventário dos arquivos

### `appointments_view_model_test.dart`

Cobre `AppointmentsViewModel` — usada na tela do profissional para listar
pendentes/histórico e aprovar/rejeitar.

Testa:
- `loadAppointments('professional')` usa `fetchProfessionalAppointments`
- `loadAppointments('client')` usa `fetchActive`
- Falha de fetch seta `errorMessage`
- `pending` / `history` getters filtram por status
- `approve`, `reject`, `cancel`, `complete` substituem o item correto na
  lista e retornam `true`
- Quando o repositório lança exception, ação retorna `false` e a lista
  fica intacta

### `auth_view_model_test.dart`

Cobre `AuthViewModel` — login, registro, auto-login com `TokenStorage`,
logout e callback de 401.

Testa:
- `login` sucesso: chama `repo.login` + busca perfil completo com
  `userRepository.getMe` e armazena
- `login` falha: `errorMessage = 'Email ou senha inválidos'`, `user = null`
- `register` sucesso/falha
- `tryAutoLogin`:
  - retorna `false` quando não há sessão salva
  - retorna `true` quando há sessão válida; injeta token na `ApiService` e
    busca perfil
  - retorna `false` e limpa token se `getMe` falhar
- `refreshMe`: atualiza `user` com `getMe`; falha silenciosa
- `logout`: delega para o repositório e zera o user; no-op quando não há user

> Detalhe: este teste injeta uma `ApiService` real (não mockada) porque o
> construtor do `AuthViewModel` configura `apiService.onUnauthorized`. É
> seguro — `ApiService` só faz HTTP quando seus métodos são chamados.

### `history_view_model_test.dart`

Cobre `HistoryViewModel` — tela de histórico de agendamentos do cliente.

Testa:
- Estado inicial vazio
- `loadArchive` popula a lista em sucesso
- `loadArchive` mantém lista vazia em falha (engole o erro)
- Notifica pelo menos 2x (loading + completion)

### `home_view_model_test.dart`

Cobre `HomeViewModel` — home do cliente e do profissional (compartilhado).

Testa:
- `loadAppointments()` (default) usa `fetchActive`
- `loadAppointments(isProfessional: true)` usa `fetchProfessionalAppointments`
- Falha seta `errorMessage`
- `cancelAppointment` substitui o item na lista pela versão atualizada
- Falha de `cancelAppointment` é engolida sem alterar a lista

### `manage_professional_profile_view_model_test.dart`

Cobre `ManageProfessionalProfileViewModel` — tela do profissional para
escolher profissão, escrever bio e cadastrar/remover serviços.

Testa:
- `loadAll`:
  - sucesso: popula `professions`, `me` e `services` em paralelo
  - falha de `fetchServiceTypes` não impede carregar o resto (services
    fica vazio)
  - falha de `fetchProfessions` seta `errorMessage`
- `saveProfile`:
  - sucesso: atualiza `me` e seta `successMessage = 'Perfil atualizado'`
  - falha: `errorMessage = 'Erro ao salvar perfil'`
- `createService`:
  - sucesso: adiciona o serviço à lista local
  - falha: lista intacta + `errorMessage`
- `deleteService`:
  - sucesso: remove da lista
  - falha: lista intacta + `errorMessage`
- `clearMessages` zera ambas mensagens

### `payment_view_model_test.dart`

Cobre `PaymentViewModel` — fluxo de cobrança PIX (AbacatePay).

Testa:
- Estado inicial: `state = idle`, sem `currentPayment`
- `startBilling`:
  - **GET retorna cobrança existente** → state=ready, cacheia, não tenta POST
  - **GET retorna 404** → cai pra POST e cria
  - **POST retorna 409** (race condition) → re-tenta GET e usa o resultado
  - **erro genérico** → state=error, `errorMessage` set
- `refreshStatus`: atualiza cache (ex: PENDING → PAID)
- `reset` limpa estado transiente mas mantém cache
- `loadBillings` (listagem administrativa): popula lista em sucesso,
  zera em falha
- `PaymentModel.fromJson` aceita 3 formatos:
  - envelope da AbacatePay (`{"data": {id, url, ...}}`)
  - AbacatePay plano (`{id, url, ...}`)
  - `PaymentSummaryResponse` do nosso backend (`{id, billingId, paymentUrl,
    status, amountInCents, appointmentId}`)
- `formattedAmount` formata centavos como `R$ X,YZ`

### `profile_view_model_test.dart`

Cobre `ProfileViewModel` — tela de perfil do usuário (cliente ou profissional).

Testa:
- Estado inicial vazio
- `loadProfile` sucesso popula `profile`
- `loadProfile` falha seta `errorMessage = 'Erro ao carregar perfil'`
- Notifica pelo menos 2x

### `rating_view_model_test.dart`

Cobre `RatingViewModel` — sistema de avaliação por profissional, com
cache em memória por `professionalId`.

Testa:
- `loadRatings` cacheia ratings por profissional
- `loadRatings` mantém lista vazia em falha
- **Não dispara duas requests** se outra já está em andamento para o mesmo
  profissional (debounce)
- `averageFor` retorna `null` sem ratings, ou média aritmética
- `loadMyRatings` popula `myRatings` em sucesso, lista vazia em falha
- `submitRating` sucesso: cria a avaliação, invalida o cache e re-faz fetch
- `submitRating` falha: `submitError` set, `isSubmitting = false`

---

## Como executar

A partir da raiz do projeto Flutter (`agendo/`):

```bash
# instala mocktail (uma vez)
flutter pub get

# roda TODA a suíte
flutter test

# roda só os de viewmodel
flutter test lib/test/view_models

# roda um único arquivo
flutter test lib/test/view_models/payment_view_model_test.dart

# roda um único teste pelo nome
flutter test --plain-name "startBilling: GET retorna cobrança existente"

# com cobertura
flutter test --coverage

# saída detalhada
flutter test --reporter expanded
```

---

## Adicionando um novo viewmodel

1. Cria o arquivo `lib/view_models/x_view_model.dart`.
2. Cria o teste equivalente em `lib/test/view_models/x_view_model_test.dart`
   seguindo o template acima.
3. Cobertura mínima esperada:
   - Estado inicial
   - Caminho feliz (sucesso de cada operação pública)
   - Caminho de erro (cada exception possível do repositório)
   - Side effects relevantes (`notifyListeners`, mutação de listas, cache)
4. Se a operação receber objetos não-primitivos (DateTime, enums, etc.),
   registrar fallback no `setUpAll`:

   ```dart
   setUpAll(() {
     registerFallbackValue(DateTime(2026));
   });
   ```
