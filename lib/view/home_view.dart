import 'package:agendo/view/components/appointment_card_skeleton.dart';
import 'package:agendo/view/select_profession_view.dart';
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
      final isProfessional = context.read<AuthViewModel>().user?.professionalProfile != null;
      context.read<HomeViewModel>().loadAppointments(isProfessional: isProfessional);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final viewModel = context.watch<HomeViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final clientName = authVm.user?.name.split(' ').first ?? 'Usuário';

    return Scaffold(
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ElevatedButton(
          onPressed: () async {
            final isProfessional = context.read<AuthViewModel>().user?.professionalProfile != null;
            final homeVm = context.read<HomeViewModel>();
            final created = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const SelectProfessionView()),
            );
            if (created == true && mounted) {
              homeVm.loadAppointments(isProfessional: isProfessional);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text(
            'Agendar Agora',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;

          if (isWide) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 300,
                      child: _buildHeader(context, colors, clientName, isLateral: true),
                    ),
                    Expanded(
                      child: _buildContent(viewModel, colors, context, isWide: true),
                    ),
                  ],
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, colors, clientName),
                Expanded(
                  child: _buildContent(viewModel, colors, context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colors, String clientName,
      {bool isLateral = false}) {
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
              text: 'Olá, ',
              style: TextStyle(
                  fontSize: titlefontsize,
                  color: colors.onSurface,
                  fontWeight: FontWeight.w300),
              children: [
                TextSpan(
                  text: clientName,
                  style: TextStyle(
                      color: colors.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Meus Agendamentos:',
            style: TextStyle(color: colors.onSurface.withValues(alpha: 0.6)),
          ),
          if (isLateral) const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildContent(HomeViewModel viewModel, ColorScheme colors,
      BuildContext context, {bool isWide = false}) {
    final edgePadding = EdgeInsets.only(
      top: isWide ? 32 : 16,
      right: isWide ? 32 : 0,
      bottom: 24,
    );

    if (viewModel.isLoading) {
      return SingleChildScrollView(
        padding: edgePadding,
        child: const Column(children: [
          AppointmentCardSkeleton(),
          AppointmentCardSkeleton(),
          AppointmentCardSkeleton(),
        ]),
      );
    }

    if (viewModel.appointments.isEmpty) {
      return Center(
        child: Text(
          'Nenhum agendamento ativo',
          style: TextStyle(color: colors.onSurface.withValues(alpha: 0.4)),
        ),
      );
    }

    return ListView.builder(
      padding: edgePadding,
      itemCount: viewModel.appointments.length,
      itemBuilder: (_, i) {
        final a = viewModel.appointments[i];
        return AppointmentCard(
          appointment: a,
          onTap: () => _showActions(context, a, viewModel),
        );
      },
    );
  }

  void _showActions(BuildContext context, dynamic a, HomeViewModel vm) {
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              a.professionalName,
              style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              (a.services as List).join(', '),
              style: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.6), fontSize: 13),
            ),
            const SizedBox(height: 20),
            if (a.isApproved)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(sheetCtx);
                    await vm.cancelAppointment(a.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Agendamento cancelado')),
                    );
                  },
                  icon: const Icon(Icons.close, color: Color(0xFFEF4444)),
                  label: const Text('Cancelar agendamento',
                      style: TextStyle(color: Color(0xFFEF4444))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              )
            else
              Center(
                child: Text(
                  'Nenhuma ação disponível',
                  style: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.4),
                      fontSize: 13),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
