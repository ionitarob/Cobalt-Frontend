import 'package:flutter/material.dart';
import '../../../../core/cobalt_theme.dart';
import '../../../../core/colors.dart';
import '../serial_change_controller.dart';
import '../serial_change_models.dart';
import '../serial_change_service.dart';

/// Shown after a box is complete. Shows stats, print, next box.
class SummaryStep extends StatefulWidget {
  final SerialChangeController ctrl;
  const SummaryStep({super.key, required this.ctrl});
  @override
  State<SummaryStep> createState() => _SummaryStepState();
}

class _SummaryStepState extends State<SummaryStep> {
  bool _printing = false;
  String? _printResult;
  SerialChangeController get c => widget.ctrl;

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    final last = c.completedBoxes.isNotEmpty ? c.completedBoxes.last : null;
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
        _stat(ct, 'Total escaneado', '${c.totalScanned}/${c.totalUnits}'),
        _stat(ct, 'Cajas completadas', '${c.completedBoxes.length}'),
        _stat(ct, 'Pendientes', '${c.pendingLabels.length}'),
        const SizedBox(height: 24),
        SizedBox(height: 44, child: OutlinedButton.icon(
          onPressed: _printing || last == null ? null : _printLastBox,
          icon: _printing
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.print_rounded, size: 18),
          label: Text('Imprimir caja ${last?.boxNumber ?? ''}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(side: BorderSide(color: ct.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        )),
        if (_printResult != null) ...[
          const SizedBox(height: 6),
          Text(_printResult!, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: _printResult!.contains('Error') ? Colors.redAccent : const Color(0xFF2ECC71))),
        ],
        const SizedBox(height: 20),
        SizedBox(height: 48, child: FilledButton(
          onPressed: c.nextBox,
          style: FilledButton.styleFrom(backgroundColor: CobaltColors.cobalt,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Siguiente caja', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        )),
      ]),
    );
  }

  Future<void> _printLastBox() async {
    final last = c.completedBoxes.isNotEmpty ? c.completedBoxes.last : null;
    if (last == null) return;
    final ip = await _pickPrinterIp();
    if (ip == null || ip.isEmpty) return;
    setState(() { _printing = true; _printResult = null; });
    try {
      final r = await c.printBox(last, printerIp: ip);
      final ok = (r['printed'] as int?) ?? 0;
      if (mounted) setState(() { _printing = false; _printResult = ok > 0 ? 'Impreso ✓' : 'Error imprimiendo'; });
    } catch (e) {
      if (mounted) setState(() { _printing = false; _printResult = 'Error: $e'; });
    }
  }

  Future<String?> _pickPrinterIp() async {
    List<SCPrinter> printers = [];
    try { printers = await SerialChangeService.instance.getPrinters(); } catch (_) {}
    if (!mounted) return null;
    final ct = context.ct;
    final ipCtrl = TextEditingController();
    SCPrinter? selected = c.cachedPrinter;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        backgroundColor: ct.surface,
        title: Text('Impresora', style: TextStyle(color: ct.textPrimary)),
        content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
          ...printers.map((p) => RadioListTile<SCPrinter>(value: p, groupValue: selected, dense: true,
            title: Text(p.name, style: TextStyle(color: ct.textPrimary, fontSize: 13)),
            subtitle: Text(p.ip, style: TextStyle(color: ct.textHint, fontSize: 11)),
            onChanged: (v) => setD(() => selected = v))),
          const SizedBox(height: 8),
          TextField(controller: ipCtrl, style: TextStyle(color: ct.textPrimary, fontSize: 13),
            decoration: InputDecoration(hintText: 'IP manual (sobreescribe)', hintStyle: TextStyle(color: ct.textHint),
              filled: true, fillColor: ct.surfaceElevated, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Imprimir')),
        ])));
    if (ok != true) { ipCtrl.dispose(); return null; }
    final manual = ipCtrl.text.trim(); ipCtrl.dispose();
    if (manual.isNotEmpty) { c.cachedPrinter = SCPrinter(id: 0, name: 'Manual', ip: manual); return manual; }
    if (selected != null) { c.cachedPrinter = selected; return selected!.ip; }
    return null;
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
