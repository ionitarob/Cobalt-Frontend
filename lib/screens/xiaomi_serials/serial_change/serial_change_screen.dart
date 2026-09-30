import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/cobalt_theme.dart';
import '../../../core/colors.dart';
import 'serial_change_controller.dart';
import 'serial_change_models.dart';
import 'serial_change_service.dart';
import 'steps/config_step.dart';
import 'steps/scan_step.dart';
import 'steps/summary_step.dart';
import 'steps/finish_step.dart';

class SerialChangeScreen extends StatefulWidget {
  const SerialChangeScreen({super.key});
  @override
  State<SerialChangeScreen> createState() => _SerialChangeScreenState();
}

class _SerialChangeScreenState extends State<SerialChangeScreen> {
  final _ctrl = SerialChangeController();

  @override
  void initState() {
    super.initState();
    _ctrl.loadOperators();
    _ctrl.addListener(_rebuild);
    _ctrl.onBoxCompleted = _autoPrintLastBox;
  }

  @override
  void dispose() { _ctrl.removeListener(_rebuild); _ctrl.dispose(); super.dispose(); }
  void _rebuild() => setState(() {});

  Future<void> _autoPrintLastBox() async {
    if (_ctrl.completedBoxes.isEmpty) return;
    final last = _ctrl.completedBoxes.last;

    // B1: First box → prompt for printer, cache it
    if (_ctrl.cachedPrinter == null) {
      final ip = await _pickPrinterIp();
      if (ip == null || ip.isEmpty) return; // user cancelled — skip print
    }

    try {
      await _ctrl.printBox(last, printerIp: _ctrl.cachedPrinter!.ip);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Caja ${last.boxNumber} impresa ✓'),
        backgroundColor: const Color(0xFF2ECC71), duration: const Duration(seconds: 2)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error imprimiendo: $e'), backgroundColor: Colors.redAccent));
    }
  }

  Future<String?> _pickPrinterIp() async {
    List<SCPrinter> printers = [];
    try { printers = await SerialChangeService.instance.getPrinters(); } catch (_) {}
    if (!mounted) return null;
    final ct = context.ct;
    final ipCtrl = TextEditingController();
    SCPrinter? selected = _ctrl.cachedPrinter;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        backgroundColor: ct.surface,
        title: Text('Seleccionar impresora', style: TextStyle(color: ct.textPrimary)),
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Omitir impresión')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Imprimir')),
        ])));
    if (ok != true) { ipCtrl.dispose(); return null; }
    final manual = ipCtrl.text.trim(); ipCtrl.dispose();
    if (manual.isNotEmpty) { _ctrl.cachedPrinter = SCPrinter(id: 0, name: 'Manual', ip: manual); return manual; }
    if (selected != null) { _ctrl.cachedPrinter = selected; return selected!.ip; }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return Scaffold(
      backgroundColor: ct.background,
      body: SafeArea(child: Column(children: [
        _topBar(ct), Divider(height: 1, color: ct.border),
        if (_ctrl.configLocked) _progressBar(ct),
        Expanded(child: _mainContent(ct)),
      ])),
    );
  }


  Widget _topBar(CobaltPalette ct) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), color: ct.surface,
    child: Row(children: [
      IconButton(icon: Icon(Icons.arrow_back_rounded, color: ct.textPrimary, size: 20), onPressed: () => context.pop()),
      const SizedBox(width: 4),
      Icon(Icons.swap_horiz_rounded, size: 18, color: CobaltColors.cobaltLight),
      const SizedBox(width: 8),
      Text('Cambio de Serials', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ct.textPrimary)),
      const Spacer(),
      if (_ctrl.configLocked) Text('${_ctrl.totalScanned}/${_ctrl.totalUnits}',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: CobaltColors.cobaltLight)),
      const SizedBox(width: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: CobaltColors.cobalt.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
        child: Text(_stepLabel(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CobaltColors.cobaltLight))),
    ]));

  String _stepLabel() => switch (_ctrl.step) {
    SCStep.config => 'Configuración',
    SCStep.scan => _ctrl.activeBox != null ? 'Caja ${_ctrl.activeBox!.boxNumber}' : 'Nueva caja',
    SCStep.summary => 'Caja completada',
    SCStep.finish => 'Finalizado',
  };

  Widget _progressBar(CobaltPalette ct) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: ClipRRect(borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(value: _ctrl.progressPct, minHeight: 5, backgroundColor: ct.border, color: CobaltColors.cobaltLight)));

  Widget _mainContent(CobaltPalette ct) {
    if (_ctrl.completedBoxes.isEmpty) return _stepWidget();
    return CustomScrollView(slivers: [
      SliverToBoxAdapter(child: _stepWidget()),
      SliverToBoxAdapter(child: Divider(height: 1, color: ct.border)),
      SliverToBoxAdapter(child: _historyHeader(ct)),
      SliverList(delegate: SliverChildBuilderDelegate(
        (_, i) => _historyBox(ct, _ctrl.completedBoxes[_ctrl.completedBoxes.length - 1 - i]),
        childCount: _ctrl.completedBoxes.length)),
    ]);
  }

  Widget _historyHeader(CobaltPalette ct) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Row(children: [
      Icon(Icons.history_rounded, size: 16, color: ct.textHint), const SizedBox(width: 6),
      Text('Cajas completadas (${_ctrl.completedBoxes.length})',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ct.textSecondary)),
    ]));

  Widget _historyBox(CobaltPalette ct, SCBoxSession box) => ExpansionTile(
    tilePadding: const EdgeInsets.symmetric(horizontal: 16),
    childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
    leading: Icon(Icons.inventory_2_outlined, size: 18, color: ct.textHint),
    title: Text('Caja ${box.boxNumber}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ct.textPrimary)),
    subtitle: Text('${box.scannedCount} unidades', style: TextStyle(fontSize: 11, color: ct.textHint)),
    children: box.mappings.map((m) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        const Icon(Icons.check_circle, size: 14, color: Color(0xFF2ECC71)), const SizedBox(width: 6),
        Text(m.oldSerial, style: TextStyle(fontSize: 12, color: ct.textSecondary, fontFeatures: const [FontFeature.tabularFigures()])),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.arrow_forward, size: 10, color: ct.textHint)),
        Text(m.newSerial, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF2ECC71), fontFeatures: const [FontFeature.tabularFigures()])),
      ]))).toList());

  Widget _stepWidget() => switch (_ctrl.step) {
    SCStep.config  => ConfigStep(ctrl: _ctrl),
    SCStep.scan    => ScanStep(ctrl: _ctrl),
    SCStep.summary => SummaryStep(ctrl: _ctrl),
    SCStep.finish  => FinishStep(ctrl: _ctrl),
  };
}

