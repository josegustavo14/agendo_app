import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../repositories/appointment_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final AppointmentRepository repository;

  HomeViewModel({required this.repository});

  List<AppointmentModel> appointments = [];
  bool isLoading = false;

  Future<void> loadAppointments() async {
    isLoading = true;
    notifyListeners();

    try {
      appointments = await repository.fetchAppointments();
    } catch (e) {
      // Tratar erro aqui
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}