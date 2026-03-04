import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/home_view_model.dart';
import 'components/appointment_card.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final String clientName = "João Vitor";
  final double titlefontsize = 28;

  @override
  void initState() {
    super.initState();
    // Inicia a busca de dados assim que a tela carrega
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().loadAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final colors = Theme.of(context).colorScheme;
    final viewModel = context.watch<HomeViewModel>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight * 0.10),
            
            Text.rich(
              TextSpan(
                text: "Olá, ",
                style: TextStyle(fontSize: titlefontsize, color: colors.onSurface, fontWeight: FontWeight.w300),
                children: [
                  TextSpan(
                    text: clientName,
                    style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            Text(
              "Meus Agendamentos:",
              style: TextStyle(color: colors.onSurface.withOpacity(0.6)),
            ),

            Expanded(
              child: viewModel.isLoading 
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 16),
                    itemCount: viewModel.appointments.length,
                    itemBuilder: (context, index) {
                      return AppointmentCard(appointment: viewModel.appointments[index]);
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}