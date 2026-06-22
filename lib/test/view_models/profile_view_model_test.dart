import 'package:agendo/models/user_model.dart';
import 'package:agendo/repositories/user_repository.dart';
import 'package:agendo/view_models/profile_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockUserRepository repository;
  late ProfileViewModel viewModel;

  setUp(() {
    repository = MockUserRepository();
    viewModel = ProfileViewModel(repository: repository);
  });

  test('starts empty and idle', () {
    expect(viewModel.profile, isNull);
    expect(viewModel.isLoading, isFalse);
    expect(viewModel.errorMessage, isNull);
  });

  test('loadProfile success populates profile', () async {
    final user = UserModel(
      id: 1,
      name: 'Alice',
      email: 'a@b.com',
      role: 'CLIENT',
    );
    when(() => repository.getMe()).thenAnswer((_) async => user);

    await viewModel.loadProfile();

    expect(viewModel.profile, user);
    expect(viewModel.errorMessage, isNull);
    expect(viewModel.isLoading, isFalse);
  });

  test('loadProfile failure sets errorMessage', () async {
    when(() => repository.getMe()).thenThrow(Exception('401'));

    await viewModel.loadProfile();

    expect(viewModel.profile, isNull);
    expect(viewModel.errorMessage, 'Erro ao carregar perfil');
    expect(viewModel.isLoading, isFalse);
  });

  test('loadProfile notifies listeners at least twice', () async {
    when(() => repository.getMe()).thenAnswer(
        (_) async => UserModel(id: 1, name: 'A', email: 'a@b.com'));
    var notifications = 0;
    viewModel.addListener(() => notifications++);

    await viewModel.loadProfile();

    expect(notifications, greaterThanOrEqualTo(2));
  });
}
