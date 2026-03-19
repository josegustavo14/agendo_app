import 'dart:convert';
import 'package:agendo/models/user_model.dart';
import 'package:agendo/services/api_service.dart';

class UserRepository {
  final ApiService apiService;

  UserRepository({required this.apiService});

  Future<List<UserModel>> fetchUsers({String? role}) async {
    final queryParams = <String, String>{};
    if (role != null) queryParams['role'] = role;

    final response = await apiService.get(
      '/users',
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => UserModel.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao buscar usuários');
    }
  }

  Future<UserModel> getMe() async {
    final response = await apiService.get('/users/me');

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erro ao buscar perfil');
    }
  }
}
