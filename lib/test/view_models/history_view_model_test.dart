import 'package:agendo/models/appointment_model.dart';
import 'package:agendo/repositories/appointment_repository.dart';
import 'package:agendo/view_models/history_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppointmentRepository extends Mock implements AppointmentRepository {}

AppointmentModel _appt({int id = 1, String status = 'COMPLETED'}) =>
    AppointmentModel(
      id: id,
      professionalId: 10,
      professionalName: 'Bob',
      clientId: 20,
      clientName: 'Alice',
      services: const ['Corte'],
      totalAmount: 50,
      scheduleDate: DateTime(2026, 1, 1),
      requestDate: DateTime(2025, 12, 1),
      status: status,
    );

void main() {
  late MockAppointmentRepository repository;
  late HistoryViewModel viewModel;

  setUp(() {
    repository = MockAppointmentRepository();
    viewModel = HistoryViewModel(repository: repository);
  });

  test('starts empty and not loading', () {
    expect(viewModel.archive, isEmpty);
    expect(viewModel.isLoading, isFalse);
  });

  test('loadArchive populates archive on success', () async {
    when(() => repository.fetchArchive())
        .thenAnswer((_) async => [_appt(id: 1), _appt(id: 2, status: 'CANCELLED')]);

    await viewModel.loadArchive();

    expect(viewModel.archive, hasLength(2));
    expect(viewModel.isLoading, isFalse);
  });

  test('loadArchive keeps archive empty on failure', () async {
    when(() => repository.fetchArchive()).thenThrow(Exception('boom'));

    await viewModel.loadArchive();

    expect(viewModel.archive, isEmpty);
    expect(viewModel.isLoading, isFalse);
  });

  test('notifies listeners on loading and completion', () async {
    when(() => repository.fetchArchive()).thenAnswer((_) async => []);
    var notifications = 0;
    viewModel.addListener(() => notifications++);

    await viewModel.loadArchive();

    expect(notifications, greaterThanOrEqualTo(2));
  });
}
