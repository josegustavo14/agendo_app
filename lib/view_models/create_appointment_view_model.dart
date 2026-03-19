import 'package:flutter/material.dart';
import 'package:agendo/models/user_model.dart';
import 'package:agendo/models/service_type_model.dart';
import 'package:agendo/repositories/appointment_repository.dart';
import 'package:agendo/repositories/user_repository.dart';
import 'package:agendo/repositories/service_type_repository.dart';

class CreateAppointmentViewModel extends ChangeNotifier {
  final AppointmentRepository appointmentRepository;
  final UserRepository userRepository;
  final ServiceTypeRepository serviceTypeRepository;

  CreateAppointmentViewModel({
    required this.appointmentRepository,
    required this.userRepository,
    required this.serviceTypeRepository,
  });

  List<UserModel> professionals = [];
  List<UserModel> clients = [];
  List<ServiceTypeModel> serviceTypes = [];

  bool isLoadingData = false;
  bool isSubmitting = false;
  String? errorMessage;

  Future<void> loadFormData(String userRole) async {
    isLoadingData = true;
    errorMessage = null;
    notifyListeners();

    try {
      final futures = <Future>[];

      if (userRole == 'PROFESSIONAL') {
        futures.add(
          userRepository.fetchUsers(role: 'CLIENT').then((v) => clients = v),
        );
      } else {
        futures.add(
          userRepository.fetchUsers(role: 'PROFESSIONAL').then((v) => professionals = v),
        );
      }

      futures.add(
        serviceTypeRepository.fetchServiceTypes().then((v) => serviceTypes = v),
      );

      await Future.wait(futures);
    } catch (e) {
      errorMessage = 'Erro ao carregar dados';
    } finally {
      isLoadingData = false;
      notifyListeners();
    }
  }

  Future<bool> createAppointment({
    required int professionalId,
    required int clientId,
    required List<int> serviceTypeIds,
    required DateTime scheduleDate,
  }) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      await appointmentRepository.createAppointment(
        professionalId: professionalId,
        clientId: clientId,
        serviceTypeIds: serviceTypeIds,
        scheduleDate: scheduleDate,
      );
      return true;
    } catch (e) {
      errorMessage = 'Erro ao criar agendamento';
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
