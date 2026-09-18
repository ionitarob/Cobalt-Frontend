import 'package:flutter/material.dart';

import '../../../core/colors.dart';

class StatusBadge extends StatelessWidget {
  final String estado;
  const StatusBadge({super.key, required this.estado});

  static Color colorFor(String estado) {
    if (estado.contains('1')) return const Color(0xFF4D9EFF); // Validada — cornflower blue
    if (estado.contains('2')) return const Color(0xFFFFB020); // Pendiente — amber
    if (estado.contains('3')) return const Color(0xFF1DE9B6); // En Ejecución — teal mint
    if (estado.contains('4')) return const Color(0xFFFF5252); // Parada — red
    if (estado.contains('5')) return const Color(0xFF69F0AE); // Finalizada — green
    if (estado.contains('6')) return const Color(0xFFCE93D8); // Facturada — violet
    return CobaltColors.textHint;
  }

  static String labelFor(String estado) {
    if (estado.contains('1')) return 'Validada';
    if (estado.contains('2')) return 'Pendiente';
    if (estado.contains('3')) return 'En Ejecución';
    if (estado.contains('4')) return 'Parada';
    if (estado.contains('5')) return 'Finalizada';
    if (estado.contains('6')) return 'Facturada';
    return estado.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    if (estado.isEmpty) return const SizedBox.shrink();
    final color = colorFor(estado);
    final label = labelFor(estado).toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PrioridadBadge extends StatelessWidget {
  final String prioridad;
  const PrioridadBadge({super.key, required this.prioridad});

  @override
  Widget build(BuildContext context) {
    if (prioridad.isEmpty) return const SizedBox.shrink();

    String label;
    Color color;
    if (prioridad.contains('1') || prioridad.toLowerCase().contains('alta')) {
      label = 'Alta'; color = const Color(0xFFFF6B6B);
    } else if (prioridad.contains('2') || prioridad.toLowerCase().contains('media')) {
      label = 'Media'; color = const Color(0xFFFFD54F);
    } else if (prioridad.contains('3') || prioridad.toLowerCase().contains('baja')) {
      label = 'Baja'; color = const Color(0xFF90A4AE);
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 5, height: 5,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: 5),
          Text(label.toUpperCase(),
              style: TextStyle(fontSize: 9.5, color: color,
                  fontWeight: FontWeight.w900, letterSpacing: 0.7)),
        ],
      ),
    );
  }
}
