import 'dart:convert';
import 'package:agendo/models/appointment_model.dart';
import 'package:agendo/services/api_service.dart';

class AppointmentRepository {
  final ApiService apiService;

  AppointmentRepository({required this.apiService});

  Future<List<AppointmentModel>> fetchAppointments({String? role}) async {
    final queryParams = <String, String>{};
    if (role != null) queryParams['role'] = role;

    final response = await apiService.get('/appointments', queryParams: queryParams.isNotEmpty ? queryParams : null);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AppointmentModel.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao buscar agendamentos');
    }
  }

  Future<AppointmentModel> createAppointment({
    required int professionalId,
    required int clientId,
    required int serviceTypeId,
    required int valueInCents,
    required DateTime scheduleDate,
  }) async {
    final response = await apiService.post('/appointments', body: {
      'professionalId': professionalId,
      'clientId': clientId,
      'serviceTypeId': serviceTypeId,
      'valueInCents': valueInCents,
      'scheduleDate': scheduleDate.toIso8601String(),
    });

    if (response.statusCode == 201) {
      return AppointmentModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erro ao criar agendamento');
    }
  }
}
