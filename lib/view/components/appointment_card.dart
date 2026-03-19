import 'package:flutter/material.dart';
import '../../models/appointment_model.dart';

class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;

  const AppointmentCard({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final isTomorrow = appointment.scheduleDate.year == tomorrow.year &&
        appointment.scheduleDate.month == tomorrow.month &&
        appointment.scheduleDate.day == tomorrow.day;

    String dateText = isTomorrow
        ? "Amanhã às ${appointment.scheduleDate.hour}:${appointment.scheduleDate.minute.toString().padLeft(2, '0')}"
        : "${appointment.scheduleDate.day}/${appointment.scheduleDate.month} às ${appointment.scheduleDate.hour}:${appointment.scheduleDate.minute.toString().padLeft(2, '0')}";

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: colors.onSurface, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0), 
        child: Row(
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
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appointment.professionalName,
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

            // LADO DIREITO: Foto
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                image: const DecorationImage(
                  image: NetworkImage("https://www.w3schools.com/howto/img_avatar.png"), // Foto padrão
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}