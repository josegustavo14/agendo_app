import 'package:flutter/material.dart';
import '../../models/appointment_model.dart';
import 'appointment_status_badge.dart';

class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback? onTap;
  final bool showClient;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onTap,
    this.showClient = false,
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
        ? "Amanhã às ${appointment.scheduleDate.hour}:${appointment.scheduleDate.minute.toString().padLeft(2, '0')}"
        : "${appointment.scheduleDate.day}/${appointment.scheduleDate.month} às ${appointment.scheduleDate.hour}:${appointment.scheduleDate.minute.toString().padLeft(2, '0')}";

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.services.join(', ').toUpperCase(),
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          showClient
                              ? appointment.clientName
                              : appointment.professionalName,
                          style: TextStyle(
                            color: colors.surface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppointmentStatusBadge(status: appointment.status),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 14, color: colors.surface.withValues(alpha: 0.6)),
                  const SizedBox(width: 4),
                  Text(
                    dateText,
                    style: TextStyle(
                        color: colors.surface.withValues(alpha: 0.7),
                        fontSize: 13),
                  ),
                  const Spacer(),
                  Text(
                    appointment.formattedValue,
                    style: TextStyle(
                      color: colors.surface,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              if (onTap != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.chevron_right,
                    color: colors.surface.withValues(alpha: 0.3),
                    size: 18,
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
