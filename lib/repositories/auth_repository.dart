import 'dart:convert';
import 'package:agendo/models/user_model.dart';
import 'package:agendo/services/api_service.dart';
import 'package:agendo/services/token_storage.dart';
import 'package:flutter/material.dart';

class AuthRepository {
  final ApiService apiService;
  final TokenStorage tokenStorage;

  AuthRepository({required this.apiService, required this.tokenStorage});

  Future<UserModel> login(String email, String password) async {
    final response = await apiService.post('/users/login', body: {
      'email': email,
      'password': password,
    });

    if (response.statusCode == 200) {
      final user = UserModel.fromJson(jsonDecode(response.body));
      if (user.token != null) {
        apiService.setToken(user.token!);
        try {
          await tokenStorage.saveToken(email, user.token!);
        } catch (e) {
          debugPrint('[AuthRepository] Falha ao persistir token: $e');
        }
      }
      return user;
    } else {
      throw Exception('Email ou senha inválidos');
    }
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    final response = await apiService.post('/users', body: {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role,
    });

    if (response.statusCode == 201) {
      final user = UserModel.fromJson(jsonDecode(response.body));
      if (user.token != null) apiService.setToken(user.token!);
      return user;
    } else {
      debugPrint('Erro ao criar conta: ${response.body}');
      throw Exception('Erro ao criar conta');
    }
  }

  Future<void> logout(String email) async {
    try {
      await tokenStorage.clearToken(email);
    } catch (e) {
      debugPrint('[AuthRepository] Falha ao limpar token: $e');
    }
    apiService.clearToken();
  }
}
