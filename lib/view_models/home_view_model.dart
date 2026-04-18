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
      appointments = isProfessional
          ? await repository.fetchProfessionalAppointments()
          : await repository.fetchActive();
    } catch (e) {
      errorMessage = 'Erro ao carregar agendamentos';
      debugPrint('Error fetching appointments: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelAppointment(int id) async {
    try {
      final updated = await repository.cancelAppointment(id);
      final idx = appointments.indexWhere((a) => a.id == updated.id);
      if (idx != -1) {
        appointments[idx] = updated;
        notifyListeners();
      }
    } catch (_) {}
  }
}
