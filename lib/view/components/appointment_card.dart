import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/appointment_model.dart';

class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback? onTap;
  final bool showClient;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onRate;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onTap,
    this.showClient = false,
    this.onApprove,
    this.onReject,
    this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final isTomorrow = appointment.scheduleDate.year == tomorrow.year &&
        appointment.scheduleDate.month == tomorrow.month &&
        appointment.scheduleDate.day == tomorrow.day;

    final dateText = isTomorrow
        ? 'Amanhã às ${appointment.scheduleDate.hour}:${appointment.scheduleDate.minute.toString().padLeft(2, '0')}'
        : '${appointment.scheduleDate.day}/${appointment.scheduleDate.month} às ${appointment.scheduleDate.hour}:${appointment.scheduleDate.minute.toString().padLeft(2, '0')}';

    final personName = showClient ? appointment.clientName : appointment.professionalName;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 0,
        color: colors.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.servicesLabel.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          personName,
                          style: TextStyle(
                            color: colors.surface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 16, color: colors.surface.withValues(alpha: 0.6)),
                            const SizedBox(width: 4),
                            Text(
                              dateText,
                              style: TextStyle(color: colors.surface.withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appointment.formattedValue,
                          style: TextStyle(
                            color: colors.surface,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: appointment.status, colors: colors),
                ],
              ),
              if (appointment.isPending && (onApprove != null || onReject != null)) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (onReject != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onReject,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Recusar'),
                        ),
                      ),
                    if (onReject != null && onApprove != null) const SizedBox(width: 8),
                    if (onApprove != null)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onApprove,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Aprovar'),
                        ),
                      ),
                  ],
                ),
              ],
              if (appointment.isApproved) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openGoogleCalendar(appointment),
                    icon: const Icon(Icons.calendar_month, size: 18),
                    label: const Text('Salvar no Google Agenda'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
              if (appointment.isCompleted && onRate != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onRate,
                    icon: const Icon(Icons.star_outline, size: 18),
                    label: const Text('Ver avaliações / Avaliar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _fmtCalDate(DateTime dt) =>
    '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}'
    'T${dt.hour.toString().padLeft(2, '0')}${dt.minute.toString().padLeft(2, '0')}00';

void _openGoogleCalendar(AppointmentModel appointment) {
  final start = appointment.scheduleDate;
  final end = start.add(const Duration(hours: 1));

  final url = Uri.parse(
    'https://www.google.com/calendar/render'
    '?action=TEMPLATE'
    '&text=${Uri.encodeComponent(appointment.servicesLabel)}'
    '&dates=${_fmtCalDate(start)}/${_fmtCalDate(end)}'
    '&details=${Uri.encodeComponent('Profissional: ${appointment.professionalName}\nCliente: ${appointment.clientName}')}',
  );

  launchUrl(url, mode: LaunchMode.externalApplication);
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final ColorScheme colors;

  const _StatusBadge({required this.status, required this.colors});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'PENDING'   => ('Pendente',  Colors.amber),
      'APPROVED'  => ('Aprovado',  Colors.green),
      'COMPLETED' => ('Concluído', Colors.blue),
      'CANCELLED' => ('Cancelado', Colors.grey),
      'REJECTED'  => ('Rejeitado', Colors.red),
      _           => (status,      Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
