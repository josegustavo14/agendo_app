import 'package:agendo/view/components/color_app.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'view/home_view.dart';
import 'repositories/appointment_repository.dart';
import 'view_models/home_view_model.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => AppointmentRepository()),
        ChangeNotifierProvider(
          create: (context) => HomeViewModel(
            repository: context.read<AppointmentRepository>(),
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
      home: const HomeView(),
    );
  }
}