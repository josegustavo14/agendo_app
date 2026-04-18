import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/history_view_model.dart';
import '../view_models/auth_view_model.dart';
import 'components/appointment_card.dart';
import 'ratings_view.dart';

class AppointmentHistoryView extends StatefulWidget {
  const AppointmentHistoryView({super.key});

  @override
  State<AppointmentHistoryView> createState() => _AppointmentHistoryViewState();
}

class _AppointmentHistoryViewState extends State<AppointmentHistoryView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryViewModel>().loadArchive();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final vm = context.watch<HistoryViewModel>();
    final isProfessional =
        context.read<AuthViewModel>().user?.professionalProfile != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Text(
            'Histórico',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: vm.isLoading
              ? Center(child: CircularProgressIndicator(color: colors.primary))
              : vm.archive.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhum agendamento no histórico',
                        style: TextStyle(
                            color: colors.onSurface.withValues(alpha: 0.4)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      itemCount: vm.archive.length,
                      itemBuilder: (_, i) {
                        final a = vm.archive[i];
                        return AppointmentCard(
                          appointment: a,
                          showClient: isProfessional,
                          onRate: a.isCompleted && !isProfessional
                              ? () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RatingsView(
                                        professionalId: a.professionalId,
                                        professionalName: a.professionalName,
                                        canSubmit: true,
                                      ),
                                    ),
                                  )
                              : null,
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
