import 'package:agendo/models/appointment_model.dart';
import 'package:agendo/repositories/appointment_repository.dart';
import 'package:agendo/view_models/appointments_view_model.dart';
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
  late AppointmentsViewModel viewModel;

  setUp(() {
    repository = MockAppointmentRepository();
    viewModel = AppointmentsViewModel(repository: repository);
  });

  group('loadAppointments', () {
    test('professional uses fetchProfessionalAppointments', () async {
      when(() => repository.fetchProfessionalAppointments())
          .thenAnswer((_) async => [_appt()]);

      await viewModel.loadAppointments('professional');

      expect(viewModel.appointments, hasLength(1));
      verify(() => repository.fetchProfessionalAppointments()).called(1);
      verifyNever(() => repository.fetchActive());
    });

    test('client uses fetchActive', () async {
      when(() => repository.fetchActive()).thenAnswer((_) async => [_appt()]);

      await viewModel.loadAppointments('client');

      verify(() => repository.fetchActive()).called(1);
      verifyNever(() => repository.fetchProfessionalAppointments());
    });

    test('sets errorMessage on failure', () async {
      when(() => repository.fetchActive()).thenThrow(Exception('boom'));

      await viewModel.loadAppointments('client');

      expect(viewModel.errorMessage, 'Erro ao carregar agendamentos');
      expect(viewModel.isLoading, isFalse);
    });
  });

  group('pending / history getters', () {
    test('separates by status correctly', () async {
      final list = [
        _appt(id: 1, status: 'PENDING'),
        _appt(id: 2, status: 'PENDING'),
        _appt(id: 3, status: 'APPROVED'),
        _appt(id: 4, status: 'COMPLETED'),
      ];
      when(() => repository.fetchActive()).thenAnswer((_) async => list);
      await viewModel.loadAppointments('client');

      expect(viewModel.pending.map((a) => a.id), [1, 2]);
      expect(viewModel.history.map((a) => a.id), [3, 4]);
    });
  });

  group('status transitions', () {
    setUp(() {
      when(() => repository.fetchActive()).thenAnswer((_) async => [
            _appt(id: 1, status: 'PENDING'),
            _appt(id: 2, status: 'APPROVED'),
          ]);
    });

    test('approve replaces the matching appointment', () async {
      await viewModel.loadAppointments('client');
      when(() => repository.approveAppointment(1))
          .thenAnswer((_) async => _appt(id: 1, status: 'APPROVED'));

      final ok = await viewModel.approve(1);

      expect(ok, isTrue);
      expect(
        viewModel.appointments.firstWhere((a) => a.id == 1).status,
        'APPROVED',
      );
    });

    test('reject replaces the matching appointment', () async {
      await viewModel.loadAppointments('client');
      when(() => repository.rejectAppointment(1))
          .thenAnswer((_) async => _appt(id: 1, status: 'REJECTED'));

      final ok = await viewModel.reject(1);

      expect(ok, isTrue);
      expect(
        viewModel.appointments.firstWhere((a) => a.id == 1).status,
        'REJECTED',
      );
    });

    test('cancel replaces the matching appointment', () async {
      await viewModel.loadAppointments('client');
      when(() => repository.cancelAppointment(2))
          .thenAnswer((_) async => _appt(id: 2, status: 'CANCELLED'));

      final ok = await viewModel.cancel(2);

      expect(ok, isTrue);
      expect(
        viewModel.appointments.firstWhere((a) => a.id == 2).status,
        'CANCELLED',
      );
    });

    test('complete replaces the matching appointment', () async {
      await viewModel.loadAppointments('client');
      when(() => repository.completeAppointment(2))
          .thenAnswer((_) async => _appt(id: 2, status: 'COMPLETED'));

      final ok = await viewModel.complete(2);

      expect(ok, isTrue);
      expect(
        viewModel.appointments.firstWhere((a) => a.id == 2).status,
        'COMPLETED',
      );
    });

    test('action returns false and keeps list intact when repo throws',
        () async {
      await viewModel.loadAppointments('client');
      when(() => repository.approveAppointment(1)).thenThrow(Exception('boom'));

      final ok = await viewModel.approve(1);

      expect(ok, isFalse);
      expect(
        viewModel.appointments.firstWhere((a) => a.id == 1).status,
        'PENDING',
      );
    });
  });
}
