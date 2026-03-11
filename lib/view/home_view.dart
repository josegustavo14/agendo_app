import 'package:agendo/view/components/appointment_card_skeleton.dart';
import 'package:agendo/view/select_professional_view.dart';
import 'package:agendo/view_models/auth_view_model.dart';
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
  final double titlefontsize = 28;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().loadAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final viewModel = context.watch<HomeViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final clientName = authVm.user?.name.split(' ').first ?? 'Usuário';

    return Scaffold(
      // Botão Fixo em baixo
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ElevatedButton(
          onPressed: () async {
            final created = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const SelectProfessionalView()),
            );
            if (created == true && mounted) {
              context.read<HomeViewModel>().loadAppointments();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            minimumSize: const Size(double.infinity, 56), // Altura fixa
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text(
            "Agendar Agora",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Se a tela for larga (ex: Web ou iPad), divide lateralmente
          if (constraints.maxWidth > 800) {
            return Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildHeader(context, colors, clientName, isLateral: true),
                ),
                Expanded(
                  flex: 3,
                  child: _buildScrollableContent(viewModel, colors),
                ),
              ],
            );
          }

          // Layout Mobile (Vertical)
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, colors, clientName),
                _buildScrollableContent(viewModel, colors),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget do Cabeçalho (Olá, João...)
  Widget _buildHeader(BuildContext context, ColorScheme colors, String clientName, {bool isLateral = false}) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.only(
        top: isLateral ? 60 : screenHeight * 0.10,
        left: isLateral ? 24 : 0,
        right: isLateral ? 24 : 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 12),
          Text(
            "Meus Agendamentos:",
            style: TextStyle(color: colors.onSurface.withOpacity(0.6)),
          ),
          if (isLateral) const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Widget da Lista de Cards
  Widget _buildScrollableContent(HomeViewModel viewModel, ColorScheme colors) {
  if (viewModel.isLoading) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        // Mostra 3 cards de esqueleto "piscando"
        children: const [
          AppointmentCardSkeleton(),
          AppointmentCardSkeleton(),
          AppointmentCardSkeleton(),
        ],
      ),
    );
  }

  return Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 24),
    child: Column(
      children: viewModel.appointments.map((appointment) {
        return AppointmentCard(appointment: appointment);
      }).toList(),
    ),
  );
}
}