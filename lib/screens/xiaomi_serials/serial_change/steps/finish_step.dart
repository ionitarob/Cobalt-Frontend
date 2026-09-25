import 'package:flutter/material.dart';
import '../../../../core/cobalt_theme.dart';
import '../../../../core/colors.dart';
import '../serial_change_controller.dart';

/// Final screen when all units are scanned.
class FinishStep extends StatelessWidget {
  final SerialChangeController ctrl;
  const FinishStep({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 40),
        const Icon(Icons.celebration_outlined, size: 56, color: CobaltColors.cobaltLight),
        const SizedBox(height: 16),
        Text('Orden completada', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ct.textPrimary)),
        const SizedBox(height: 8),
        Text('${ctrl.totalScanned} seriales registrados en ${ctrl.completedBoxes.length} cajas',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: ct.textSecondary)),
        const SizedBox(height: 40),
        SizedBox(height: 48, child: FilledButton(
          onPressed: ctrl.reset,
          style: FilledButton.styleFrom(backgroundColor: CobaltColors.cobalt,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Nueva orden', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        )),
      ]),
    );
  }
}
