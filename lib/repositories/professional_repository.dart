import 'dart:convert';
import 'package:agendo/models/profession_model.dart';
import 'package:agendo/models/professional_model.dart';
import 'package:agendo/models/service_type_model.dart';
import 'package:agendo/services/api_service.dart';

class ProfessionalRepository {
  final ApiService apiService;

  ProfessionalRepository({required this.apiService});

  Future<List<ProfessionModel>> fetchProfessions() async {
    final response = await apiService.get('/professions');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ProfessionModel.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao buscar profissões');
    }
  }

  Future<List<ProfessionalModel>> searchProfessionals({
    String? name,
    int? professionId,
    String? serviceTypeName,
  }) async {
    final queryParams = <String, String>{};
    if (name != null && name.isNotEmpty) queryParams['name'] = name;
    if (professionId != null) queryParams['professionId'] = professionId.toString();
    if (serviceTypeName != null && serviceTypeName.isNotEmpty) {
      queryParams['serviceTypeName'] = serviceTypeName;
    }

    try {
      final response = await apiService.get(
        '/professionals',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );
      if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ProfessionalModel.fromJson(json)).toList();
    } else {
      print('Error searching professionals: ${response.statusCode} - ${response.body}');
      throw Exception('Erro ao buscar profissionais');
    }
    } catch (e) {
      print('Error searching professionals: $e');
      throw Exception('Erro ao buscar profissionais');
    }

  }

  Future<ProfessionalModel> getProfessional(int id) async {
    final response = await apiService.get('/professionals/$id');

    if (response.statusCode == 200) {
      return ProfessionalModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Profissional não encontrado');
    }
  }

  Future<List<ServiceTypeModel>> getProfessionalServices(int id) async {
    final response = await apiService.get('/professionals/$id/services');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ServiceTypeModel.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao buscar serviços do profissional');
    }
  }
}
