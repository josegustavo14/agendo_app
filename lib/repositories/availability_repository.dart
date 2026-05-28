import 'dart:convert';
import 'package:agendo/models/day_schedule_model.dart';
import 'package:agendo/models/time_slot_model.dart';
import 'package:agendo/services/api_service.dart';

class AvailabilityRepository {
  final ApiService apiService;

  AvailabilityRepository({required this.apiService});

  Future<List<DayScheduleModel>> getWeeklySchedule() async {
    final response = await apiService.get('/availability/schedule');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((j) => DayScheduleModel.fromJson(j)).toList();
    }
    throw Exception('Erro ao buscar grade de horários');
  }

  Future<List<DayScheduleModel>> saveWeeklySchedule(List<DayScheduleModel> schedule) async {
    final response = await apiService.post('/availability/schedule', body: {
      'schedule': schedule.map((d) => d.toJson()).toList(),
    });
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((j) => DayScheduleModel.fromJson(j)).toList();
    }
    throw Exception('Erro ao salvar grade de horários');
  }

  Future<void> deleteDay(String dayOfWeek) async {
    final response = await apiService.delete('/availability/schedule/$dayOfWeek');
    if (response.statusCode != 204) {
      throw Exception('Erro ao remover dia da grade');
    }
  }

  Future<List<TimeSlotModel>> getSlots(int professionalId, DateTime date) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final response =
        await apiService.get('/availability/$professionalId/slots?date=$dateStr');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((j) => TimeSlotModel.fromJson(j)).toList();
    }
    throw Exception('Erro ao buscar horários disponíveis');
  }
}
