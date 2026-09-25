import 'package:flutter/material.dart';

import '../../../../core/cobalt_theme.dart';
import '../../../../core/colors.dart';
import '../order_detail_controller.dart';

/// Contextual workflow buttons based on current order estado.
class WorkflowActionBar extends StatefulWidget {
  const WorkflowActionBar({super.key, required this.controller});
  final OrderDetailController controller;

  @override
  State<WorkflowActionBar> createState() => _WorkflowActionBarState();
}

class _WorkflowActionBarState extends State<WorkflowActionBar> {
  bool _busy = false;
  OrderDetailController get _ctrl => widget.controller;

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    final detail = _ctrl.detail;
    if (detail == null) return const SizedBox.shrink();
    final actions = _actionsForEstado(detail.agentOrder.estado);
    if (actions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ct.surface,
        border: Border(top: BorderSide(color: ct.border, width: 0.5)),
      ),
      child: Row(children: [
        for (int i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          actions[i].primary ? Expanded(child: _primary(ct, actions[i])) : _secondary(ct, actions[i]),
        ],
        if (_ctrl.isPrivileged) ...[const SizedBox(width: 8), _adminBtn(ct)],
      ]),
    );
  }

  Widget _primary(CobaltPalette ct, _Act a) => SizedBox(
    height: 36,
    child: FilledButton(
      onPressed: _busy ? null : () => _run(a.fn),
      style: FilledButton.styleFrom(
        backgroundColor: a.color ?? CobaltColors.cobalt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: _busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(a.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    ),
  );

  Widget _secondary(CobaltPalette ct, _Act a) => SizedBox(
    height: 36,
    child: OutlinedButton(
      onPressed: _busy ? null : () => _run(a.fn),
      style: OutlinedButton.styleFrom(side: BorderSide(color: ct.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), foregroundColor: ct.textSecondary),
      child: Text(a.label, style: const TextStyle(fontSize: 13)),
    ),
  );

  Widget _adminBtn(CobaltPalette ct) => SizedBox(
    height: 36, width: 36,
    child: IconButton(
      icon: Icon(Icons.edit_outlined, size: 16, color: ct.textHint),
      onPressed: _showForceDialog,
      tooltip: 'Cambiar estado',
      style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: ct.border))),
    ),
  );

  Future<void> _run(Future<void> Function() fn) async {
    setState(() => _busy = true);
    try { await fn(); } finally { if (mounted) setState(() => _busy = false); }
  }

  List<_Act> _actionsForEstado(String e) {
    if (e == '1') return [_Act('Recepcionar', primary: true, fn: () => _ctrl.updateEstado('2'))];
    if (e == '2') return [_Act('Comenzar', primary: true, color: const Color(0xFF2ECC71), fn: () => _ctrl.updateEstado('3'))];
    if (e == '3') return [_Act('Finalizar', primary: true, fn: _handleFinalizar), _Act('Parar', fn: _handleParar)];
    if (e == '4') return [_Act('Reanudar', primary: true, color: const Color(0xFF2ECC71), fn: () => _ctrl.updateEstado('3'))];
    return [];
  }

  Future<void> _handleParar() async {
    final c = TextEditingController();
    final r = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Motivo de parada'),
      content: TextField(controller: c, autofocus: true, maxLines: 3,
        decoration: const InputDecoration(hintText: 'Describe el motivo…', border: OutlineInputBorder())),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.of(ctx).pop(c.text.trim()), child: const Text('Parar')),
      ],
    ));
    c.dispose();
    if (r == null) return;
    await _ctrl.updateEstado('4', stopReason: r.isNotEmpty ? r : null);
  }

  Future<void> _handleFinalizar() async {
    if (!_ctrl.detail!.photos.any((p) => p.scope.contains('quality'))) {
      if (!mounted) return;
      await showDialog<void>(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Fotos de calidad requeridas'),
        content: const Text('Sube al menos una foto de calidad antes de finalizar.'),
        actions: [FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Entendido'))],
      ));
      return;
    }
    await _ctrl.updateEstado('5');
  }

  Future<void> _showForceDialog() async {
    String? sel;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: const Text('Cambiar estado (admin)'),
        content: DropdownButtonFormField<String>(
          value: sel,
          decoration: const InputDecoration(labelText: 'Nuevo estado', border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: '1', child: Text('1 — Validada')),
            DropdownMenuItem(value: '2', child: Text('2 — Pendiente')),
            DropdownMenuItem(value: '3', child: Text('3 — En Ejecución')),
            DropdownMenuItem(value: '4', child: Text('4 — Parada')),
            DropdownMenuItem(value: '5', child: Text('5 — Finalizada')),
            DropdownMenuItem(value: '6', child: Text('6 — Facturada')),
          ],
          onChanged: (v) => setS(() => sel = v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: sel == null ? null : () => Navigator.of(ctx).pop(true), child: const Text('Aplicar')),
        ],
      ),
    ));
    if (ok == true && sel != null) await _ctrl.updateEstado(sel!, force: true);
  }
}

class _Act {
  final String label;
  final bool primary;
  final Color? color;
  final Future<void> Function() fn;
  _Act(this.label, {this.primary = false, this.color, required this.fn});
}
