import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../repositories/appointment_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final AppointmentRepository repository;

  HomeViewModel({required this.repository});

  List<AppointmentModel> appointments = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadAppointments() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      appointments = await repository.fetchAppointments();
    } catch (e) {
      errorMessage = 'Erro ao carregar agendamentos';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
