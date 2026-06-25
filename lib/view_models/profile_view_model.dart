import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  final UserRepository repository;

  ProfileViewModel({required this.repository});

  UserModel? profile;
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadProfile() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      profile = await repository.getMe();
    } catch (e) {
      errorMessage = 'Erro ao carregar perfil';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
