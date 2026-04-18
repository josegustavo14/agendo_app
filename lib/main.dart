import 'package:agendo/services/token_storage.dart';
import 'package:agendo/view/bottom_navigation_bar_page.dart';
import 'package:agendo/view/components/color_app.dart';
import 'package:agendo/view/login_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'repositories/auth_repository.dart';
import 'repositories/appointment_repository.dart';
import 'repositories/user_repository.dart';
import 'repositories/service_type_repository.dart';
import 'repositories/professional_repository.dart';
import 'repositories/rating_repository.dart';
import 'view_models/auth_view_model.dart';
import 'view_models/home_view_model.dart';
import 'view_models/history_view_model.dart';
import 'view_models/profile_view_model.dart';
import 'view_models/appointments_view_model.dart';
import 'view_models/rating_view_model.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final apiService = ApiService();
  final tokenStorage = TokenStorage();

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => apiService),
        Provider(create: (_) => tokenStorage),
        Provider(create: (_) => AuthRepository(apiService: apiService, tokenStorage: tokenStorage)),
        Provider(create: (_) => AppointmentRepository(apiService: apiService)),
        Provider(create: (_) => UserRepository(apiService: apiService)),
        Provider(create: (_) => ServiceTypeRepository(apiService: apiService)),
        Provider(create: (_) => ProfessionalRepository(apiService: apiService)),
        Provider(create: (_) => RatingRepository(apiService: apiService)),
        ChangeNotifierProvider(
          create: (context) => AuthViewModel(
            repository: context.read<AuthRepository>(),
            userRepository: context.read<UserRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => HomeViewModel(
            repository: context.read<AppointmentRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => HistoryViewModel(
            repository: context.read<AppointmentRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ProfileViewModel(
            repository: context.read<UserRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => AppointmentsViewModel(
            repository: context.read<AppointmentRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => RatingViewModel(
            repository: context.read<RatingRepository>(),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Agendo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorScheme: ColorApp.lightScheme),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: ColorApp.darkScheme),
      themeMode: ThemeMode.dark,
      home: const _SplashGate(),
    );
  }
}

/// Checks for a saved session and routes to home or login.
class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSession());
  }

  Future<void> _checkSession() async {
    final auth = context.read<AuthViewModel>();
    final restored = await auth.tryAutoLogin();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => restored ? const BottomNavigationBarPage() : const LoginView(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      body: Center(
        child: CircularProgressIndicator(color: colors.primary),
      ),
    );
  }
}
