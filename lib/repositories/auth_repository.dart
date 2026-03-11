import 'dart:convert';
import 'package:agendo/models/user_model.dart';
import 'package:agendo/services/api_service.dart';
import 'package:flutter/material.dart';

class AuthRepository {
  final ApiService apiService;

  AuthRepository({required this.apiService});

  Future<UserModel> login(String email, String password) async {
    final response = await apiService.post('/users/login', body: {
      'email': email,
      'password': password,
    });

    if (response.statusCode == 200) {
      final user = UserModel.fromJson(jsonDecode(response.body));
      if (user.token != null) apiService.setToken(user.token!);
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

  void logout() {
    apiService.clearToken();
  }
}
