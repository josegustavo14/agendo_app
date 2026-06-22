import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../repositories/appointment_repository.dart';

class AppointmentsViewModel extends ChangeNotifier {
  final AppointmentRepository repository;

  AppointmentsViewModel({required this.repository});

  List<AppointmentModel> appointments = [];
  bool isLoading = false;
  String? errorMessage;

  List<AppointmentModel> get pending =>
      appointments.where((a) => a.isPending).toList();

  List<AppointmentModel> get history =>
      appointments.where((a) => !a.isPending).toList();

  Future<void> loadAppointments(String role) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (role == 'professional') {
        appointments = await repository.fetchProfessionalAppointments();
      } else {
        appointments = await repository.fetchActive();
      }
    } catch (_) {
      errorMessage = 'Erro ao carregar agendamentos';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approve(int id) => _action(() => repository.approveAppointment(id));
  Future<bool> reject(int id) => _action(() => repository.rejectAppointment(id));
  Future<bool> cancel(int id) => _action(() => repository.cancelAppointment(id));
  Future<bool> complete(int id) => _action(() => repository.completeAppointment(id));

  Future<bool> _action(Future<AppointmentModel> Function() call) async {
    try {
      final updated = await call();
      final idx = appointments.indexWhere((a) => a.id == updated.id);
      if (idx != -1) {
        appointments[idx] = updated;
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
