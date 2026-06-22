import 'package:agendo/models/appointment_model.dart';
import 'package:agendo/repositories/appointment_repository.dart';
import 'package:agendo/view_models/home_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppointmentRepository extends Mock implements AppointmentRepository {}

AppointmentModel _appt({int id = 1, String status = 'PENDING'}) =>
    AppointmentModel(
      id: id,
      professionalId: 10,
      professionalName: 'Bob',
      clientId: 20,
      clientName: 'Alice',
      services: const ['Corte'],
      totalAmount: 50,
      scheduleDate: DateTime(2026, 7, 1, 10),
      requestDate: DateTime(2026, 6, 1, 10),
      status: status,
    );

void main() {
  late MockAppointmentRepository repository;
  late HomeViewModel viewModel;

  setUp(() {
    repository = MockAppointmentRepository();
    viewModel = HomeViewModel(repository: repository);
  });

  group('HomeViewModel.loadAppointments', () {
    test('client flow calls fetchActive', () async {
      when(() => repository.fetchActive())
          .thenAnswer((_) async => [_appt(id: 1)]);

      await viewModel.loadAppointments();

      expect(viewModel.appointments, hasLength(1));
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.isLoading, isFalse);
      verify(() => repository.fetchActive()).called(1);
      verifyNever(() => repository.fetchProfessionalAppointments());
    });

    test('professional flow calls fetchProfessionalAppointments', () async {
      when(() => repository.fetchProfessionalAppointments())
          .thenAnswer((_) async => [_appt(id: 1), _appt(id: 2)]);

      await viewModel.loadAppointments(isProfessional: true);

      expect(viewModel.appointments, hasLength(2));
      verify(() => repository.fetchProfessionalAppointments()).called(1);
      verifyNever(() => repository.fetchActive());
    });

    test('sets errorMessage on failure', () async {
      when(() => repository.fetchActive()).thenThrow(Exception('boom'));

      await viewModel.loadAppointments();

      expect(viewModel.errorMessage, 'Erro ao carregar agendamentos');
      expect(viewModel.isLoading, isFalse);
    });
  });

  group('HomeViewModel.cancelAppointment', () {
    test('replaces appointment in the list with updated entity', () async {
      final original = _appt(id: 5, status: 'APPROVED');
      final cancelled = _appt(id: 5, status: 'CANCELLED');
      when(() => repository.fetchActive()).thenAnswer((_) async => [original]);
      when(() => repository.cancelAppointment(5))
          .thenAnswer((_) async => cancelled);
      await viewModel.loadAppointments();

      await viewModel.cancelAppointment(5);

      expect(viewModel.appointments.single.status, 'CANCELLED');
    });

    test('swallows errors and keeps original list', () async {
      final original = _appt(id: 5, status: 'APPROVED');
      when(() => repository.fetchActive()).thenAnswer((_) async => [original]);
      when(() => repository.cancelAppointment(5)).thenThrow(Exception('boom'));
      await viewModel.loadAppointments();

      await viewModel.cancelAppointment(5);

      expect(viewModel.appointments.single.status, 'APPROVED');
    });
  });
}
