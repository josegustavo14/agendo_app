import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/appointment_model.dart';
import '../view_models/appointments_view_model.dart';
import 'components/appointment_card.dart';
import 'components/appointment_status_badge.dart';
import 'payment_view.dart';
import 'ratings_view.dart';

class AppointmentsView extends StatefulWidget {
  final String role; // 'professional' or 'client'

  const AppointmentsView({super.key, required this.role});

  @override
  State<AppointmentsView> createState() => _AppointmentsViewState();
}

class _AppointmentsViewState extends State<AppointmentsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentsViewModel>().loadAppointments(widget.role);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final vm = context.watch<AppointmentsViewModel>();

    if (vm.isLoading) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }

    if (widget.role == 'professional') {
      return _buildProfessionalView(context, colors, vm);
    } else {
      return _buildClientView(context, colors, vm);
    }
  }

  Widget _buildProfessionalView(
      BuildContext context, ColorScheme colors, AppointmentsViewModel vm) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Row(
            children: [
              Text(
                'Agendamentos',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (vm.pending.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${vm.pending.length}',
                    style: TextStyle(
                      color: colors.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          labelColor: colors.primary,
          unselectedLabelColor: colors.onSurface.withValues(alpha: 0.5),
          indicatorColor: colors.primary,
          tabs: [
            Tab(text: 'Pendentes (${vm.pending.length})'),
            Tab(text: 'Histórico (${vm.history.length})'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildList(
                colors,
                vm.pending,
                emptyText: 'Nenhum agendamento pendente',
                showClient: true,
                onTap: (a) => _showProfessionalActions(context, a, vm),
              ),
              _buildList(
                colors,
                vm.history,
                emptyText: 'Nenhum agendamento no histórico',
                showClient: true,
                onTap: (a) => _showProfessionalActions(context, a, vm),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClientView(
      BuildContext context, ColorScheme colors, AppointmentsViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Text(
            'Meus Agendamentos',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: _buildList(
            colors,
            vm.appointments,
            emptyText: 'Nenhum agendamento encontrado',
            showClient: false,
            onTap: (a) => _showClientActions(context, a, vm),
          ),
        ),
      ],
    );
  }

  Widget _buildList(
    ColorScheme colors,
    List<AppointmentModel> list, {
    required String emptyText,
    required bool showClient,
    required void Function(AppointmentModel) onTap,
  }) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: TextStyle(color: colors.onSurface.withValues(alpha: 0.4)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: list.length,
      itemBuilder: (ctx, i) => AppointmentCard(
        appointment: list[i],
        showClient: showClient,
        onTap: () => onTap(list[i]),
      ),
    );
  }

  void _showProfessionalActions(
      BuildContext context, AppointmentModel a, AppointmentsViewModel vm) {
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              a.clientName,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              a.services.join(', '),
              style: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.6), fontSize: 13),
            ),
            const SizedBox(height: 4),
            AppointmentStatusBadge(status: a.status),
            const SizedBox(height: 20),
            if (a.isPending) ...[
              _actionButton(
                context,
                label: 'Aprovar',
                icon: Icons.check_circle_outline,
                color: const Color(0xFF10B981),
                onTap: () async {
                  Navigator.pop(context);
                  final ok = await vm.approve(a.id);
                  if (!context.mounted) return;
                  _feedback(context, ok, 'Agendamento aprovado!');
                },
              ),
              const SizedBox(height: 10),
              _actionButton(
                context,
                label: 'Rejeitar',
                icon: Icons.cancel_outlined,
                color: const Color(0xFFEF4444),
                onTap: () async {
                  Navigator.pop(context);
                  final ok = await vm.reject(a.id);
                  if (!context.mounted) return;
                  _feedback(context, ok, 'Agendamento rejeitado');
                },
              ),
            ],
            if (a.isApproved) ...[
              _actionButton(
                context,
                label: 'Concluir atendimento',
                icon: Icons.done_all,
                color: const Color(0xFF3B82F6),
                onTap: () async {
                  Navigator.pop(context);
                  final ok = await vm.complete(a.id);
                  if (!context.mounted) return;
                  _feedback(context, ok, 'Atendimento concluído!');
                },
              ),
              const SizedBox(height: 10),
              _actionButton(
                context,
                label: 'Cancelar agendamento',
                icon: Icons.close,
                color: const Color(0xFF6B7280),
                onTap: () async {
                  Navigator.pop(context);
                  final ok = await vm.cancel(a.id);
                  if (!context.mounted) return;
                  _feedback(context, ok, 'Agendamento cancelado');
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showClientActions(
      BuildContext context, AppointmentModel a, AppointmentsViewModel vm) {
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
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
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              a.services.join(', '),
              style: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.6), fontSize: 13),
            ),
            const SizedBox(height: 4),
            AppointmentStatusBadge(status: a.status),
            const SizedBox(height: 20),
            if (a.isApproved) ...[
              _actionButton(
                context,
                label: 'Pagar agora',
                icon: Icons.pix,
                color: const Color(0xFF10B981),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentView(appointment: a),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _actionButton(
                context,
                label: 'Cancelar agendamento',
                icon: Icons.close,
                color: const Color(0xFFEF4444),
                onTap: () async {
                  Navigator.pop(context);
                  final ok = await vm.cancel(a.id);
                  if (!context.mounted) return;
                  _feedback(context, ok, 'Agendamento cancelado');
                },
              ),
            ],
            if (a.isCompleted)
              _actionButton(
                context,
                label: 'Avaliar profissional',
                icon: Icons.star_outline,
                color: Colors.amber,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RatingsView(
                        professionalId: a.professionalId,
                        professionalName: a.professionalName,
                        canSubmit: true,
                      ),
                    ),
                  );
                },
              ),
            if (!a.isApproved && !a.isCompleted)
              Center(
                child: Text(
                  'Nenhuma ação disponível',
                  style: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.4)),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color),
        label: Text(label, style: TextStyle(color: color)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _feedback(BuildContext context, bool ok, String successMsg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? successMsg : 'Erro ao executar ação'),
        backgroundColor: ok ? Colors.green : Theme.of(context).colorScheme.error,
      ),
    );
  }
}
