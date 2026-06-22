import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/appointments_view_model.dart';
import 'components/appointment_card.dart';
import 'appointments_view.dart';

class ProfessionalHomeView extends StatefulWidget {
  const ProfessionalHomeView({super.key});

  @override
  State<ProfessionalHomeView> createState() => _ProfessionalHomeViewState();
}

class _ProfessionalHomeViewState extends State<ProfessionalHomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentsViewModel>().loadAppointments('professional');
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final authVm = context.watch<AuthViewModel>();
    final vm = context.watch<AppointmentsViewModel>();
    final name = authVm.user?.name.split(' ').first ?? 'Profissional';

    final upcoming = vm.appointments
        .where((a) => a.isApproved && a.scheduleDate.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.scheduleDate.compareTo(b.scheduleDate));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.08),
          Text.rich(
            TextSpan(
              text: 'Olá, ',
              style: TextStyle(
                  fontSize: 28,
                  color: colors.onSurface,
                  fontWeight: FontWeight.w300),
              children: [
                TextSpan(
                  text: name,
                  style: TextStyle(
                      color: colors.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Cards de resumo
          Row(
            children: [
              _SummaryCard(
                colors: colors,
                label: 'Pendentes',
                value: '${vm.pending.length}',
                icon: Icons.pending_outlined,
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 12),
              _SummaryCard(
                colors: colors,
                label: 'Aprovados',
                value: '${vm.appointments.where((a) => a.isApproved).length}',
                icon: Icons.check_circle_outline,
                color: const Color(0xFF10B981),
              ),
              const SizedBox(width: 12),
              _SummaryCard(
                colors: colors,
                label: 'Concluídos',
                value: '${vm.appointments.where((a) => a.isCompleted).length}',
                icon: Icons.done_all,
                color: const Color(0xFF3B82F6),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Botão Google Calendar (futuro)
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Integração com Google Calendar em breve!')),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: colors.onSurface.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.calendar_month,
                        color: colors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Google Agenda',
                          style: TextStyle(
                            color: colors.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Sincronizar agendamentos (em breve)',
                          style: TextStyle(
                            color: colors.onSurface.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: colors.onSurface.withValues(alpha: 0.3)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Próximos agendamentos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Próximos agendamentos',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (vm.pending.isNotEmpty)
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        body: SafeArea(
                          child: AppointmentsView(role: 'professional'),
                        ),
                      ),
                    ),
                  ),
                  child: Text(
                    'Ver pendentes (${vm.pending.length})',
                    style: TextStyle(color: colors.primary, fontSize: 13),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (vm.isLoading)
            Center(
                child: CircularProgressIndicator(color: colors.primary))
          else if (upcoming.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Nenhum agendamento aprovado próximo',
                  style: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.4)),
                ),
              ),
            )
          else
            ...upcoming.take(5).map(
                  (a) => AppointmentCard(
                    appointment: a,
                    showClient: true,
                  ),
                ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final ColorScheme colors;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.colors,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: colors.onSurface.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
