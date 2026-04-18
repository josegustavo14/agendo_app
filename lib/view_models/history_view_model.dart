import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../repositories/appointment_repository.dart';

class HistoryViewModel extends ChangeNotifier {
  final AppointmentRepository repository;

  HistoryViewModel({required this.repository});

  List<AppointmentModel> archive = [];
  bool isLoading = false;

  Future<void> loadArchive() async {
    isLoading = true;
    notifyListeners();

    try {
      archive = await repository.fetchArchive();
    } catch (e) {
      debugPrint('Error fetching archive: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
