import 'package:flutter/material.dart';
import 'package:agendo/models/user_model.dart';
import 'package:agendo/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository repository;

  AuthViewModel({required this.repository});

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

  void logout() {
    repository.logout();
    _user = null;
    notifyListeners();
  }
}
