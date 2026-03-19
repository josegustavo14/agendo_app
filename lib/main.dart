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
import 'view_models/profile_view_model.dart';
import 'view_models/appointments_view_model.dart';
import 'view_models/rating_view_model.dart';

void main() {
  final apiService = ApiService();

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => apiService),
        Provider(create: (_) => AuthRepository(apiService: apiService)),
        Provider(create: (_) => AppointmentRepository(apiService: apiService)),
        Provider(create: (_) => UserRepository(apiService: apiService)),
        Provider(create: (_) => ServiceTypeRepository(apiService: apiService)),
        Provider(create: (_) => ProfessionalRepository(apiService: apiService)),
        Provider(create: (_) => RatingRepository(apiService: apiService)),
        ChangeNotifierProvider(
          create: (context) => AuthViewModel(
            repository: context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => HomeViewModel(
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
      title: 'Agendo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorScheme: ColorApp.lightScheme),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: ColorApp.darkScheme),
      themeMode: ThemeMode.dark,
      home: const LoginView(),
    );
  }
}
