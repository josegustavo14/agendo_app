import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:agendo/models/appointment_model.dart';
import 'package:agendo/services/api_service.dart';

class AppointmentRepository {
  final ApiService apiService;

  AppointmentRepository({required this.apiService});

  Future<List<AppointmentModel>> fetchActive() async {
    final response = await apiService.get('/appointments');

    if (response.statusCode == 200) {
      debugPrint('Appointments fetched successfully: ${response.body}');
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AppointmentModel.fromJson(json)).toList();
    } else {
      debugPrint('Error fetching appointments: ${response.statusCode} - ${response.body}');
      throw Exception('Erro ao buscar agendamentos');
    }
  }

  Future<List<AppointmentModel>> fetchArchive() async {
    final response = await apiService.get('/appointments/archive');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AppointmentModel.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao buscar histórico de agendamentos');
    }
  }

  Future<AppointmentModel> getById(int id) async {
    final response = await apiService.get('/appointments/$id');

    if (response.statusCode == 200) {
      return AppointmentModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Agendamento não encontrado');
    }
  }

  Future<List<AppointmentModel>> getTimeline() async {
    final response = await apiService.get('/appointments/timeline');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AppointmentModel.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao buscar timeline de agendamentos');
    }
  }

  Future<List<AppointmentModel>> fetchProfessionalAppointments() async {
    final response = await apiService.get('/appointments/professional');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AppointmentModel.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao buscar agendamentos do profissional');
    }
  }

  Future<AppointmentModel> createAppointment({
    required int professionalId,
    required int clientId,
    required List<int> serviceTypeIds,
    required DateTime scheduleDate,
  }) async {
    final response = await apiService.post('/appointments', body: {
      'professionalId': professionalId,
      'clientId': clientId,
      'serviceTypeIds': serviceTypeIds,
      'scheduleDate': scheduleDate.toIso8601String(),
    });

    if (response.statusCode == 201) {
      return AppointmentModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erro ao criar agendamento');
    }
  }

  Future<AppointmentModel> approveAppointment(int id) async {
    final response = await apiService.patch('/appointments/$id/approve');
    if (response.statusCode == 200) {
      return AppointmentModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Erro ao aprovar agendamento');
  }

  Future<AppointmentModel> rejectAppointment(int id) async {
    final response = await apiService.patch('/appointments/$id/reject');
    if (response.statusCode == 200) {
      return AppointmentModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Erro ao rejeitar agendamento');
  }

  Future<AppointmentModel> cancelAppointment(int id) async {
    final response = await apiService.patch('/appointments/$id/cancel');
    if (response.statusCode == 200) {
      return AppointmentModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Erro ao cancelar agendamento');
  }

  Future<AppointmentModel> completeAppointment(int id) async {
    final response = await apiService.patch('/appointments/$id/complete');
    if (response.statusCode == 200) {
      return AppointmentModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Erro ao concluir agendamento');
  }
}
