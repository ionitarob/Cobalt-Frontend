import 'package:flutter/material.dart';
import '../../../../core/cobalt_theme.dart';
import '../../../../core/colors.dart';
import '../serial_change_controller.dart';

class ScanStep extends StatefulWidget {
  final SerialChangeController ctrl;
  const ScanStep({super.key, required this.ctrl});
  @override
  State<ScanStep> createState() => _ScanStepState();
}

class _ScanStepState extends State<ScanStep> {
  final _boxNumCtrl = TextEditingController();
  final _boxUnitsCtrl = TextEditingController();
  final _scanCtrl = TextEditingController();
  final _scanFocus = FocusNode();
  bool _busy = false;
  String? _err;
  SerialChangeController get c => widget.ctrl;

  @override
  void dispose() { _boxNumCtrl.dispose(); _boxUnitsCtrl.dispose(); _scanCtrl.dispose(); _scanFocus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return c.activeBox == null ? _boxSetup(ct) : _scanner(ct);
  }

  // --- Box setup ---
  Widget _boxSetup(CobaltPalette ct) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Nueva caja', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ct.textPrimary)),
      Text('${c.pendingLabels.length} etiquetas pendientes', style: TextStyle(fontSize: 13, color: ct.textSecondary)),
      const SizedBox(height: 24),
      _input(ct, _boxNumCtrl, 'Numero de caja', Icons.inventory_2_outlined),
      const SizedBox(height: 12),
      _input(ct, _boxUnitsCtrl, 'Unidades en caja', Icons.tag, kb: TextInputType.number),
      const SizedBox(height: 24),
      SizedBox(height: 48, child: FilledButton(onPressed: _startBox,
        style: FilledButton.styleFrom(backgroundColor: CobaltColors.cobalt, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        child: const Text('Comenzar caja', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)))),
    ]),
  );


  Widget _scanner(CobaltPalette ct) {
    final b = c.activeBox!;
    final pct = b.units > 0 ? b.scannedCount / b.units : 0.0;
    return Column(children: [
      Container(padding: const EdgeInsets.all(16), color: ct.surface, child: Column(children: [
        Row(children: [
          Text('Caja ${b.boxNumber}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ct.textPrimary)),
          const Spacer(),
          Text('${b.scannedCount}/${b.units}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: CobaltColors.cobaltLight)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct, minHeight: 6, backgroundColor: ct.border, color: CobaltColors.cobaltLight)),
        if (b.currentLabel != null) ...[const SizedBox(height: 12),
          Text('Nuevo serial:', style: TextStyle(fontSize: 11, color: ct.textHint)),
          Text(b.currentLabel!, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: CobaltColors.cobaltLight, fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ])),
      Padding(padding: const EdgeInsets.all(16), child: TextField(controller: _scanCtrl, focusNode: _scanFocus, autofocus: true, enabled: !_busy, style: TextStyle(color: ct.textPrimary, fontSize: 18),
        decoration: InputDecoration(hintText: 'Escanear serial antiguo...', hintStyle: TextStyle(color: ct.textHint), prefixIcon: Icon(Icons.qr_code_scanner, color: ct.textHint), filled: true, fillColor: ct.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ct.border, width: 2)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: CobaltColors.cobaltLight, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)), onSubmitted: _onScan)),
      if (_err != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(_err!, style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
      Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), reverse: true, itemCount: b.mappings.length, itemBuilder: (_, i) {
        final m = b.mappings[b.mappings.length - 1 - i];
        return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
          const Icon(Icons.check_circle, color: Color(0xFF2ECC71), size: 18), const SizedBox(width: 8),
          Text(m.newSerial, style: TextStyle(fontSize: 13, color: ct.textPrimary, fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()])),
          const SizedBox(width: 8), Icon(Icons.arrow_back, size: 12, color: ct.textHint), const SizedBox(width: 8),
          Expanded(child: Text(m.oldSerial, style: TextStyle(fontSize: 13, color: ct.textSecondary, fontFeatures: const [FontFeature.tabularFigures()]))),
        ]));
      })),
    ]);
  }
  void _startBox() { final e = c.startBox(_boxNumCtrl.text, int.tryParse(_boxUnitsCtrl.text) ?? 0); if (e != null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e))); return; } setState(() {}); _scanFocus.requestFocus(); }
  Future<void> _onScan(String v) async { if (v.trim().isEmpty) return; setState(() { _busy = true; _err = null; }); final e = await c.scanOldSerial(v); if (mounted) { setState(() { _busy = false; _err = e; }); _scanCtrl.clear(); _scanFocus.requestFocus(); } }
  Widget _input(CobaltPalette ct, TextEditingController tc, String h, IconData ic, {TextInputType? kb}) => TextField(controller: tc, keyboardType: kb, style: TextStyle(color: ct.textPrimary), decoration: InputDecoration(hintText: h, hintStyle: TextStyle(color: ct.textHint), prefixIcon: Icon(ic, color: ct.textHint), filled: true, fillColor: ct.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ct.border)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ct.border)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)));
}
