import 'package:flutter/foundation.dart';
import '../models/payment_model.dart';
import '../repositories/payment_repository.dart';

/// Estados possíveis do fluxo de geração/abertura da cobrança PIX.
enum PaymentRequestState { idle, loading, ready, alreadyExists, error }

/// Coordena a geração da cobrança PIX (`POST /payments/billing/appointment/:id`)
/// e mantém o estado pronto para a UI consumir.
///
/// Fluxo típico na tela:
///   1. cliente toca "Pagar agora" → `startBilling(appointmentId)`
///   2. viewmodel chama o repositório, recebe a [PaymentModel] e expõe em
///      [currentPayment] com [state] = [PaymentRequestState.ready]
///   3. UI abre `currentPayment!.paymentUrl` via url_launcher
///   4. cache em [paymentByAppointment] evita re-chamadas para o mesmo agendamento
class PaymentViewModel extends ChangeNotifier {
  final PaymentRepository repository;

  PaymentViewModel({required this.repository});

  /// Cache: appointmentId -> cobrança gerada nesta sessão.
  final Map<int, PaymentModel> paymentByAppointment = {};

  PaymentRequestState state = PaymentRequestState.idle;
  PaymentModel? currentPayment;
  String? errorMessage;
  int? lastAppointmentId;

  /// Lista administrativa (usada em telas de suporte/relatório).
  List<PaymentModel> billings = [];
  bool isLoadingBillings = false;

  bool get isLoading => state == PaymentRequestState.loading;
  bool get hasError => state == PaymentRequestState.error;

  PaymentModel? paymentFor(int appointmentId) =>
      paymentByAppointment[appointmentId];

  /// Limpa o estado transiente (mantém o cache).
  void reset() {
    state = PaymentRequestState.idle;
    currentPayment = null;
    errorMessage = null;
    lastAppointmentId = null;
    notifyListeners();
  }

  /// Carrega a cobrança de um agendamento.
  /// Estratégia: tenta GET (a cobrança já foi criada automaticamente na
  /// aprovação); se 404, faz POST como fallback (caso o listener tenha
  /// falhado por indisponibilidade do gateway). Retorna `true` se há uma
  /// URL pronta em [currentPayment].
  Future<bool> startBilling(int appointmentId) async {
    state = PaymentRequestState.loading;
    errorMessage = null;
    lastAppointmentId = appointmentId;
    notifyListeners();

    try {
      // 1) tenta ler cobrança existente
      final existing = await repository.getByAppointment(appointmentId);
      if (existing != null) {
        paymentByAppointment[appointmentId] = existing;
        currentPayment = existing;
        state = PaymentRequestState.ready;
        return true;
      }

      // 2) sem cobrança ainda — tenta criar (fallback raro: listener falhou)
      final created = await repository.createBillingForAppointment(appointmentId);
      paymentByAppointment[appointmentId] = created;
      currentPayment = created;
      state = PaymentRequestState.ready;
      return true;
    } on PaymentAlreadyExistsException catch (e) {
      // Race condition: alguém criou entre o GET e o POST. Tenta ler de novo.
      try {
        final payment = await repository.getByAppointment(appointmentId);
        if (payment != null) {
          paymentByAppointment[appointmentId] = payment;
          currentPayment = payment;
          state = PaymentRequestState.ready;
          return true;
        }
      } catch (_) {/* cai no errorMessage abaixo */}
      errorMessage = e.message;
      state = PaymentRequestState.alreadyExists;
      return false;
    } catch (e) {
      debugPrint('[PaymentViewModel] Erro ao gerar cobrança: $e');
      errorMessage = 'Erro ao gerar cobrança';
      state = PaymentRequestState.error;
      return false;
    } finally {
      notifyListeners();
    }
  }

  /// Re-busca o status do pagamento (útil após o usuário voltar do navegador).
  Future<void> refreshStatus(int appointmentId) async {
    try {
      final payment = await repository.getByAppointment(appointmentId);
      if (payment != null) {
        paymentByAppointment[appointmentId] = payment;
        if (lastAppointmentId == appointmentId) currentPayment = payment;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[PaymentViewModel] refreshStatus erro: $e');
    }
  }

  /// Carrega a listagem global de cobranças (uso administrativo).
  Future<void> loadBillings() async {
    isLoadingBillings = true;
    notifyListeners();

    try {
      billings = await repository.listBillings();
    } catch (e) {
      debugPrint('[PaymentViewModel] Erro ao listar cobranças: $e');
      billings = [];
    } finally {
      isLoadingBillings = false;
      notifyListeners();
    }
  }
}
