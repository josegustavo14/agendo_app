import 'package:agendo/models/user_model.dart';
import 'package:agendo/repositories/auth_repository.dart';
import 'package:agendo/repositories/user_repository.dart';
import 'package:agendo/services/api_service.dart';
import 'package:agendo/services/token_storage.dart';
import 'package:agendo/view_models/auth_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockTokenStorage extends Mock implements TokenStorage {}

UserModel _user({String token = 'tk', String role = 'CLIENT'}) => UserModel(
      id: 1,
      name: 'Alice',
      email: 'alice@example.com',
      role: role,
      token: token,
    );

void main() {
  late MockAuthRepository authRepo;
  late MockUserRepository userRepo;
  late MockTokenStorage tokenStorage;
  late ApiService apiService;
  late AuthViewModel viewModel;

  setUp(() {
    apiService = ApiService();
    authRepo = MockAuthRepository();
    userRepo = MockUserRepository();
    tokenStorage = MockTokenStorage();

    when(() => authRepo.apiService).thenReturn(apiService);
    when(() => authRepo.tokenStorage).thenReturn(tokenStorage);

    viewModel = AuthViewModel(repository: authRepo, userRepository: userRepo);
  });

  group('AuthViewModel.login', () {
    test('success: stores user from getMe and clears error', () async {
      final loginUser = _user();
      final fullUser = _user(token: 'tk2');
      when(() => authRepo.login('a@b.com', 'pw'))
          .thenAnswer((_) async => loginUser);
      when(() => userRepo.getMe()).thenAnswer((_) async => fullUser);

      final ok = await viewModel.login('a@b.com', 'pw');

      expect(ok, isTrue);
      expect(viewModel.user, fullUser);
      expect(viewModel.isLoggedIn, isTrue);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.isLoading, isFalse);
    });

    test('failure: surfaces friendly error and keeps user null', () async {
      when(() => authRepo.login(any(), any())).thenThrow(Exception('401'));

      final ok = await viewModel.login('a@b.com', 'pw');

      expect(ok, isFalse);
      expect(viewModel.user, isNull);
      expect(viewModel.isLoggedIn, isFalse);
      expect(viewModel.errorMessage, 'Email ou senha inválidos');
    });

    test('login notifies listeners at least twice (loading + finished)',
        () async {
      when(() => authRepo.login(any(), any())).thenAnswer((_) async => _user());
      when(() => userRepo.getMe()).thenAnswer((_) async => _user());

      var notifications = 0;
      viewModel.addListener(() => notifications++);

      await viewModel.login('a@b.com', 'pw');

      expect(notifications, greaterThanOrEqualTo(2));
    });
  });

  group('AuthViewModel.register', () {
    test('success: stores user', () async {
      final user = _user(role: 'PROFESSIONAL');
      when(() => authRepo.register(
            name: any(named: 'name'),
            email: any(named: 'email'),
            phone: any(named: 'phone'),
            password: any(named: 'password'),
            role: any(named: 'role'),
          )).thenAnswer((_) async => user);

      final ok = await viewModel.register(
        name: 'Alice',
        email: 'a@b.com',
        phone: '11999',
        password: 'pw',
        role: 'PROFESSIONAL',
      );

      expect(ok, isTrue);
      expect(viewModel.user, user);
    });

    test('failure: errorMessage set', () async {
      when(() => authRepo.register(
            name: any(named: 'name'),
            email: any(named: 'email'),
            phone: any(named: 'phone'),
            password: any(named: 'password'),
            role: any(named: 'role'),
          )).thenThrow(Exception('boom'));

      final ok = await viewModel.register(
        name: 'X',
        email: 'x@y.com',
        phone: 'p',
        password: 'pw',
        role: 'CLIENT',
      );

      expect(ok, isFalse);
      expect(viewModel.errorMessage, 'Erro ao criar conta');
    });
  });

  group('AuthViewModel.tryAutoLogin', () {
    test('returns false when there is no saved session', () async {
      when(() => tokenStorage.getLastSession()).thenAnswer((_) async => null);

      final restored = await viewModel.tryAutoLogin();

      expect(restored, isFalse);
      expect(viewModel.user, isNull);
    });

    test('returns true and loads profile when a session exists', () async {
      when(() => tokenStorage.getLastSession())
          .thenAnswer((_) async => (email: 'a@b.com', token: 'tk'));
      final fullUser = _user();
      when(() => userRepo.getMe()).thenAnswer((_) async => fullUser);

      final restored = await viewModel.tryAutoLogin();

      expect(restored, isTrue);
      expect(viewModel.user, fullUser);
      expect(apiService.token, 'tk');
    });

    test('returns false when getMe fails and clears any restored token',
        () async {
      when(() => tokenStorage.getLastSession())
          .thenAnswer((_) async => (email: 'a@b.com', token: 'tk'));
      when(() => userRepo.getMe()).thenThrow(Exception('expired'));

      final restored = await viewModel.tryAutoLogin();

      expect(restored, isFalse);
      expect(apiService.token, isNull);
    });
  });

  group('AuthViewModel.logout', () {
    test('clears user and delegates to repository', () async {
      when(() => authRepo.login(any(), any())).thenAnswer((_) async => _user());
      when(() => userRepo.getMe()).thenAnswer((_) async => _user());
      when(() => authRepo.logout(any())).thenAnswer((_) async {});
      await viewModel.login('a@b.com', 'pw');

      await viewModel.logout();

      expect(viewModel.user, isNull);
      expect(viewModel.isLoggedIn, isFalse);
      verify(() => authRepo.logout('alice@example.com')).called(1);
    });

    test('no-op when there is no current user', () async {
      await viewModel.logout();
      expect(viewModel.user, isNull);
      verifyNever(() => authRepo.logout(any()));
    });
  });
}
