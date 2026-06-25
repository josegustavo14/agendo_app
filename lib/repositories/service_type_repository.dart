import 'dart:convert';
import 'package:agendo/models/service_type_model.dart';
import 'package:agendo/services/api_service.dart';

class ServiceTypeRepository {
  final ApiService apiService;

  ServiceTypeRepository({required this.apiService});

  Future<List<ServiceTypeModel>> fetchServiceTypes() async {
    final response = await apiService.get('/service-types');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ServiceTypeModel.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao buscar tipos de serviço');
    }
  }

  Future<ServiceTypeModel> createServiceType({
    required String name,
    required double price,
    String? description,
  }) async {
    final response = await apiService.post('/service-types', body: {
      'name': name,
      'price': price,
      'description': description,
    });

    if (response.statusCode == 201) {
      return ServiceTypeModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erro ao criar tipo de serviço');
    }
  }

  Future<void> deleteServiceType(int id) async {
    final response = await apiService.delete('/service-types/$id');
    if (response.statusCode != 204) {
      throw Exception('Erro ao remover serviço: ${response.statusCode}');
    }
  }
}
