import 'package:agendo/main.dart' show navigatorKey;
import 'package:agendo/view/login_view.dart';
import 'package:flutter/material.dart';
import 'package:agendo/models/user_model.dart';
import 'package:agendo/repositories/auth_repository.dart';
import 'package:agendo/repositories/user_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository repository;
  final UserRepository userRepository;

  AuthViewModel({required this.repository, required this.userRepository}) {
    // Quando o ApiService detectar 401, faz logout e redireciona ao login
    repository.apiService.onUnauthorized = () {
      _user = null;
      notifyListeners();
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginView()),
        (_) => false,
      );
    };
  }

  UserModel? _user;
  bool isLoading = false;
  String? errorMessage;

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      _user = await repository.login(email, password);
      // Busca perfil completo com professionalProfile/clientProfile
      _user = await userRepository.getMe();
      return true;
    } catch (e) {
      errorMessage = 'Email ou senha inválidos';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      _user = await repository.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: role,
      );
      return true;
    } catch (e) {
      debugPrint('Erro ao criar conta: ${e.toString()}');
      errorMessage = 'Erro ao criar conta';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Tries to restore the last session from secure storage.
  /// Returns true if a valid session was found and restored.
  Future<bool> tryAutoLogin() async {
    try {
      final session = await repository.tokenStorage.getLastSession();
      if (session == null) return false;
      repository.apiService.setToken(session.token);
      _user = await userRepository.getMe();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[AuthViewModel] Auto-login falhou: $e');
      repository.apiService.clearToken();
      return false;
    }
  }

  Future<void> logout() async {
    if (_user != null) {
      await repository.logout(_user!.email);
    }
    _user = null;
    notifyListeners();
  }
}
