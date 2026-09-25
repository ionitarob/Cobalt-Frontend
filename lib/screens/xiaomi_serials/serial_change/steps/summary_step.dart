import 'package:flutter/material.dart';
import '../../../../core/cobalt_theme.dart';
import '../../../../core/colors.dart';
import '../serial_change_controller.dart';

/// Shown after a box is complete. Shows stats, offers to start next box.
class SummaryStep extends StatelessWidget {
  final SerialChangeController ctrl;
  const SummaryStep({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    final last = ctrl.completedBoxes.isNotEmpty ? ctrl.completedBoxes.last : null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Icon(Icons.check_circle_outline, size: 48, color: Color(0xFF2ECC71)),
        const SizedBox(height: 12),
        Text('Caja completada', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ct.textPrimary)),
        if (last != null) ...[
          const SizedBox(height: 8),
          Text('Caja ${last.boxNumber} — ${last.scannedCount} unidades',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: ct.textSecondary)),
        ],
        const SizedBox(height: 24),
        _stat(ct, 'Total escaneado', '${ctrl.totalScanned}/${ctrl.totalUnits}'),
        _stat(ct, 'Cajas completadas', '${ctrl.completedBoxes.length}'),
        _stat(ct, 'Pendientes', '${ctrl.pendingLabels.length}'),
        const SizedBox(height: 32),
        SizedBox(height: 48, child: FilledButton(
          onPressed: ctrl.nextBox,
          style: FilledButton.styleFrom(backgroundColor: CobaltColors.cobalt,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Siguiente caja', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        )),
      ]),
    );
  }

  Widget _stat(CobaltPalette ct, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Text(label, style: TextStyle(fontSize: 14, color: ct.textSecondary)),
      const Spacer(),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ct.textPrimary)),
    ]),
  );
}
