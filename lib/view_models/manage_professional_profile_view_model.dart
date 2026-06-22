import 'package:flutter/foundation.dart';
import '../models/profession_model.dart';
import '../models/service_type_model.dart';
import '../models/user_model.dart';
import '../repositories/professional_repository.dart';
import '../repositories/service_type_repository.dart';
import '../repositories/user_repository.dart';

/// Estado da tela "Perfil profissional" — combina:
///  - lista de profissões disponíveis (GET /professions)
///  - perfil profissional do usuário autenticado (GET /users/me + PATCH)
///  - serviços que o profissional oferece (GET/POST/DELETE /service-types)
///
/// As três fontes vivem juntas porque a tela edita as três em conjunto.
class ManageProfessionalProfileViewModel extends ChangeNotifier {
  final ProfessionalRepository professionalRepository;
  final UserRepository userRepository;
  final ServiceTypeRepository serviceTypeRepository;

  ManageProfessionalProfileViewModel({
    required this.professionalRepository,
    required this.userRepository,
    required this.serviceTypeRepository,
  });

  List<ProfessionModel> professions = [];
  List<ServiceTypeModel> services = [];
  UserModel? me;

  bool isLoading = false;
  bool isSavingProfile = false;
  bool isSavingService = false;
  String? errorMessage;
  String? successMessage;

  int? get selectedProfessionId => me?.professionalProfile?.professionId;
  String? get bio => me?.professionalProfile?.bio;

  /// Carrega tudo em paralelo. Falha individual em /service-types não impede
  /// o resto (perfil novo pode ainda não ter serviços e o endpoint pode
  /// retornar lista vazia normalmente).
  Future<void> loadAll() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        professionalRepository.fetchProfessions(),
        userRepository.getMe(),
        _safeFetchServices(),
      ]);
      professions = results[0] as List<ProfessionModel>;
      me = results[1] as UserModel;
      services = results[2] as List<ServiceTypeModel>;
    } catch (e) {
      debugPrint('[ManageProfessional] loadAll erro: $e');
      errorMessage = 'Erro ao carregar dados do perfil';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// PATCH profession/bio. Recarrega `me` com a resposta do backend.
  Future<bool> saveProfile({
    required int? professionId,
    required String? bio,
  }) async {
    isSavingProfile = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      final updated = await userRepository.updateProfessionalProfile(
        professionId: professionId,
        bio: bio,
      );
      me = updated;
      successMessage = 'Perfil atualizado';
      return true;
    } catch (e) {
      debugPrint('[ManageProfessional] saveProfile erro: $e');
      errorMessage = 'Erro ao salvar perfil';
      return false;
    } finally {
      isSavingProfile = false;
      notifyListeners();
    }
  }

  /// Cria um serviço e adiciona à lista local.
  Future<bool> createService({
    required String name,
    required double price,
    String? description,
  }) async {
    isSavingService = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      final created = await serviceTypeRepository.createServiceType(
        name: name,
        price: price,
        description: description,
      );
      services = [...services, created];
      successMessage = 'Serviço cadastrado';
      return true;
    } catch (e) {
      debugPrint('[ManageProfessional] createService erro: $e');
      errorMessage = 'Erro ao cadastrar serviço';
      return false;
    } finally {
      isSavingService = false;
      notifyListeners();
    }
  }

  /// Remove um serviço (soft local: tira da lista se o backend confirmar 204).
  Future<bool> deleteService(int id) async {
    try {
      await serviceTypeRepository.deleteServiceType(id);
      services = services.where((s) => s.id != id).toList();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[ManageProfessional] deleteService erro: $e');
      errorMessage = 'Erro ao remover serviço';
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }

  /// Envolve a chamada para que tanto uma exception síncrona quanto um
  /// Future rejeitado virem `[]`, sem derrubar o `Future.wait` do loadAll.
  Future<List<ServiceTypeModel>> _safeFetchServices() async {
    try {
      return await serviceTypeRepository.fetchServiceTypes();
    } catch (_) {
      return <ServiceTypeModel>[];
    }
  }
}
