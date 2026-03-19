import 'package:flutter/material.dart';

class AppointmentStatusBadge extends StatelessWidget {
  final String status;

  const AppointmentStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _config(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static (String, Color) _config(String status) {
    return switch (status) {
      'PENDING' => ('Pendente', const Color(0xFFF59E0B)),
      'APPROVED' => ('Aprovado', const Color(0xFF10B981)),
      'COMPLETED' => ('Concluído', const Color(0xFF3B82F6)),
      'CANCELLED' => ('Cancelado', const Color(0xFF6B7280)),
      'REJECTED' => ('Rejeitado', const Color(0xFFEF4444)),
      _ => (status, const Color(0xFF6B7280)),
    };
  }
}
