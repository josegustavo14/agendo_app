import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../repositories/appointment_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final AppointmentRepository repository;

  HomeViewModel({required this.repository});

  List<AppointmentModel> appointments = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadAppointments({bool isProfessional = false}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (isProfessional) {
        appointments = await repository.fetchProfessionalAppointments();
      } else {
        appointments = await repository.fetchAppointments();
      }
    } catch (e) {
      errorMessage = 'Erro ao carregar agendamentos';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveAppointment(int id) async {
    try {
      final updated = await repository.approveAppointment(id);
      final index = appointments.indexWhere((a) => a.id == id);
      if (index != -1) {
        appointments[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rejectAppointment(int id) async {
    try {
      final updated = await repository.rejectAppointment(id);
      final index = appointments.indexWhere((a) => a.id == id);
      if (index != -1) {
        appointments[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
