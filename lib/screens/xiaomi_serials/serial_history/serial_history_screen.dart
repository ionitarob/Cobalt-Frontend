import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/cobalt_theme.dart';
import '../../../core/colors.dart';
import 'serial_history_service.dart';

class SerialHistoryScreen extends StatefulWidget {
  const SerialHistoryScreen({super.key});
  @override
  State<SerialHistoryScreen> createState() => _SerialHistoryScreenState();
}

class _SerialHistoryScreenState extends State<SerialHistoryScreen> {
  final _searchCtrl = TextEditingController();
  final _svc = SerialHistoryService.instance;
  String _filter = 'serial';
  List<Map<String, dynamic>> _rows = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final q = _searchCtrl.text.trim();
      if (q.isEmpty) {
        _rows = await _svc.list(limit: 2000);
      } else {
        _rows = await _svc.search(
          serial: _filter == 'serial' ? q : null,
          nrOrden: _filter == 'nr_orden' ? q : null,
          nrBox: _filter == 'nr_box' ? q : null, q: q,
        );
      }
    } catch (e) { _error = e.toString(); }
    if (mounted) setState(() => _loading = false);
  }

  Map<String, Map<String, List<Map<String, dynamic>>>> _grouped() {
    final out = <String, Map<String, List<Map<String, dynamic>>>>{};
    for (final r in _rows) {
      final ord = (r['nr_orden'] ?? '').toString();
      final box = (r['nr_box'] ?? '').toString();
      out.putIfAbsent(ord, () => {});
      out[ord]!.putIfAbsent(box, () => []);
      out[ord]![box]!.add(r);
    }
    return out;
  }

  static final _dtFmt = DateFormat('dd/MM/yy HH:mm');
  String _fmtDt(dynamic v) {
    if (v == null) return '-';
    try { return _dtFmt.format(DateTime.parse(v.toString())); }
    catch (_) { return v.toString(); }
  }

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return Scaffold(
      backgroundColor: ct.background,
      body: SafeArea(child: Column(children: [
        _topBar(ct), Divider(height: 1, color: ct.border),
        _searchBar(ct), Divider(height: 1, color: ct.border),
        Expanded(child: _body(ct)),
      ])),
    );
  }

  Widget _topBar(CobaltPalette ct) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), color: ct.surface,
    child: Row(children: [
      IconButton(icon: Icon(Icons.arrow_back_rounded, color: ct.textPrimary, size: 20), onPressed: () => context.pop()),
      const SizedBox(width: 4),
      Icon(Icons.history_rounded, size: 18, color: CobaltColors.cobaltLight),
      const SizedBox(width: 8),
      Text('Historial Serials', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ct.textPrimary)),
      const Spacer(),
      if (_rows.isNotEmpty) Text('${_rows.length} registros', style: TextStyle(fontSize: 11, color: ct.textHint)),
      const SizedBox(width: 4),
      IconButton(
        icon: _loading
            ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: CobaltColors.cobaltLight))
            : Icon(Icons.refresh_rounded, size: 20, color: CobaltColors.cobaltLight),
        tooltip: 'Refrescar', onPressed: _loading ? null : _load,
      ),
    ]));

  Widget _searchBar(CobaltPalette ct) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), color: ct.surface,
    child: Row(children: [
      ...['serial', 'nr_orden', 'nr_box'].map((f) => Padding(padding: const EdgeInsets.only(right: 6),
        child: ChoiceChip(
          label: Text(f == 'serial' ? 'Serial' : f == 'nr_orden' ? 'Orden' : 'Caja',
            style: TextStyle(fontSize: 11, color: _filter == f ? Colors.white : ct.textSecondary)),
          selected: _filter == f,
          onSelected: (_) => setState(() { _filter = f; if (_searchCtrl.text.isNotEmpty) _load(); }),
          selectedColor: CobaltColors.cobalt, backgroundColor: ct.surfaceElevated,
          side: BorderSide(color: _filter == f ? CobaltColors.cobalt : ct.border),
          padding: const EdgeInsets.symmetric(horizontal: 4), visualDensity: VisualDensity.compact))),
      const SizedBox(width: 8),
      Expanded(child: SizedBox(height: 36, child: TextField(controller: _searchCtrl,
        style: TextStyle(color: ct.textPrimary, fontSize: 13),
        decoration: InputDecoration(hintText: 'Buscar...', hintStyle: TextStyle(color: ct.textHint, fontSize: 13),
          prefixIcon: Icon(Icons.search, size: 18, color: ct.textHint), filled: true, fillColor: ct.surfaceElevated,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10)), onSubmitted: (_) => _load()))),
    ]));

  Widget _body(CobaltPalette ct) {
    if (_loading && _rows.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: CobaltColors.cobaltLight));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)));
    }
    if (_rows.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.history_toggle_off_rounded, size: 48, color: ct.textHint.withValues(alpha: 0.4)),
        const SizedBox(height: 12),
        Text('Sin registros encontrados', style: TextStyle(color: ct.textHint)),
      ]));
    }
    return _groupedList(ct);
  }

  Widget _groupedList(CobaltPalette ct) {
    final grouped = _grouped();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: grouped.length,
      itemBuilder: (_, i) {
        final ordKey = grouped.keys.elementAt(i);
        final boxes = grouped[ordKey]!;
        final totalRegs = boxes.values.fold<int>(0, (s, l) => s + l.length);
        final displayOrd = ordKey.isEmpty ? 'Sin Orden' : ordKey;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: ct.surface, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ct.border.withValues(alpha: 0.5))),
          clipBehavior: Clip.antiAlias,
          child: Theme(data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(key: PageStorageKey('order-$ordKey'),
              collapsedBackgroundColor: Colors.transparent,
              backgroundColor: ct.surfaceElevated.withValues(alpha: 0.3),
              iconColor: CobaltColors.cobaltLight, collapsedIconColor: ct.textHint, shape: const Border(),
              title: Row(children: [
                Container(padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: CobaltColors.cobalt.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.inventory_2_outlined, size: 18, color: CobaltColors.cobaltLight)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(displayOrd, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: ct.textPrimary)),
                  const SizedBox(height: 2),
                  Text('$totalRegs registros en ${boxes.length} ${boxes.length == 1 ? "caja" : "cajas"}',
                    style: TextStyle(fontSize: 11, color: ct.textHint)),
                ])),
              ]),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                _iconBtn(Icons.download_rounded, 'Exportar Excel',
                  () => _exportOrder(ordKey), color: CobaltColors.cobaltLight),
                const SizedBox(width: 4),
                _iconBtn(Icons.delete_forever_rounded, 'Borrar orden',
                  () => _deleteOrder(ordKey, boxes), color: Colors.redAccent.withValues(alpha: 0.7)),
              ]),
              children: boxes.entries.map((e) => _buildBoxTile(ct, ordKey, e.key, e.value)).toList(),
            )),
        );
      },
    );
  }

  Widget _buildBoxTile(CobaltPalette ct, String ordKey, String boxNum, List<Map<String, dynamic>> regs) {
    final displayBox = boxNum.isEmpty ? 'N/A' : boxNum;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: ct.background.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: CobaltColors.cobaltLight, width: 3))),
      child: Theme(data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(key: PageStorageKey('order-$ordKey-box-$boxNum'),
          shape: const Border(), iconColor: ct.textSecondary, collapsedIconColor: ct.textHint,
          title: Row(children: [
            Icon(Icons.inbox_rounded, size: 15, color: ct.textHint), const SizedBox(width: 8),
            Text('Caja $displayBox', style: TextStyle(fontSize: 13, color: ct.textPrimary)),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: CobaltColors.cobalt.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
              child: Text('${regs.length}', style: TextStyle(fontSize: 10, color: CobaltColors.cobaltLight, fontWeight: FontWeight.w600))),
          ]),
          trailing: _iconBtn(Icons.delete_outline_rounded, 'Borrar caja',
            () => _deleteBox(boxNum, regs), color: Colors.redAccent.withValues(alpha: 0.6), size: 18),
          children: regs.map((r) => _buildSerialRow(ct, r)).toList(),
        )),
    );
  }

  Widget _buildSerialRow(CobaltPalette ct, Map<String, dynamic> r) {
    final oldS = r['serial_old']?.toString() ?? '-';
    final newS = r['serial_new']?.toString() ?? '-';
    final changed = oldS != newS;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(children: [
        Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r['nr_sku']?.toString() ?? '-',
            style: TextStyle(color: ct.textPrimary, fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 2),
          Text(_fmtDt(r['fecha_creacion']), style: TextStyle(color: ct.textHint, fontSize: 10)),
        ])),
        Expanded(flex: 4, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(oldS, style: TextStyle(color: ct.textHint, fontSize: 11, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.arrow_forward, size: 10, color: ct.textHint)),
            Expanded(child: Text(newS,
              style: TextStyle(color: changed ? const Color(0xFF4ADE80) : ct.textPrimary, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis)),
          ]),
          if (r['usuario'] != null)
            Padding(padding: const EdgeInsets.only(top: 2),
              child: Text('User: ${r["usuario"]}', style: TextStyle(color: ct.textHint, fontSize: 10))),
        ])),
        Row(mainAxisSize: MainAxisSize.min, children: [
          _tinyAction(Icons.edit, ct.textHint, () => _editRow(r)),
          const SizedBox(width: 6),
          _tinyAction(Icons.close, Colors.redAccent.withValues(alpha: 0.6), () => _deleteRow(r)),
        ]),
      ]),
    );
  }

  Widget _iconBtn(IconData icon, String tooltip, VoidCallback onTap, {Color? color, double size = 20}) =>
    IconButton(icon: Icon(icon, size: size), color: color ?? CobaltColors.cobaltLight,
      tooltip: tooltip, onPressed: onTap, visualDensity: VisualDensity.compact, splashRadius: 20);

  Widget _tinyAction(IconData icon, Color color, VoidCallback onTap) =>
    InkWell(onTap: onTap, borderRadius: BorderRadius.circular(4),
      child: Padding(padding: const EdgeInsets.all(4), child: Icon(icon, size: 16, color: color)));

  int? _rowId(Map<String, dynamic> r) => (r['id'] ?? r['ID']) as int?;

  Future<void> _exportOrder(String ordKey) async {
    try {
      final bytes = await _svc.exportOrder(ordKey);
      if (!mounted) return;
      if (bytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay datos para exportar')));
        return;
      }
      // On mobile/desktop: save to temp and show path
      final dir = Directory.systemTemp;
      final file = File('${dir.path}/$ordKey.xlsx');
      await file.writeAsBytes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exportado: ${file.path}')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error exportando: $e')));
    }
  }

  Future<void> _deleteRow(Map<String, dynamic> r) async {
    final ct = context.ct;
    final id = _rowId(r);
    if (id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error: Registro sin ID — necesita redeploy del backend'),
          backgroundColor: Colors.redAccent,
        ));
      }
      return;
    }
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      backgroundColor: ct.surface,
      title: Text('Eliminar registro', style: TextStyle(color: ct.textPrimary)),
      content: Text('No se puede deshacer.', style: TextStyle(color: ct.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(c, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text('Eliminar')),
      ]));
    if (ok == true) {
      try {
        final n = await _svc.delete(id);
        if (n == 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Registro no fue eliminado (deleted: 0) — redeploy backend'),
            backgroundColor: Colors.orange,
          ));
        }
        _load();
      } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    }
  }

  Future<void> _deleteBox(String boxNum, List<Map<String, dynamic>> regs) async {
    final ct = context.ct;
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      backgroundColor: ct.surface,
      title: Text('Eliminar caja $boxNum', style: TextStyle(color: ct.textPrimary)),
      content: Text('Se borrarán ${regs.length} registros. No se puede deshacer.', style: TextStyle(color: ct.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(c, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text('Eliminar')),
      ]));
    if (ok == true) {
      try {
        int skipped = 0;
        for (final r in regs) {
          final id = _rowId(r);
          if (id == null) { skipped++; continue; }
          await _svc.delete(id);
        }
        if (skipped > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$skipped registros sin ID — no eliminados (redeploy backend)'),
            backgroundColor: Colors.orange,
          ));
        }
        _load();
      } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    }
  }

  Future<void> _deleteOrder(String ordKey, Map<String, List<Map<String, dynamic>>> boxes) async {
    final ct = context.ct;
    final allRegs = boxes.values.expand((e) => e).toList();
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      backgroundColor: ct.surface,
      title: Text('Eliminar orden $ordKey', style: TextStyle(color: ct.textPrimary)),
      content: Text('Se borrarán ${allRegs.length} registros en ${boxes.length} cajas. No se puede deshacer.',
        style: TextStyle(color: ct.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(c, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text('Eliminar')),
      ]));
    if (ok == true) {
      try {
        int skipped = 0;
        for (final r in allRegs) {
          final id = _rowId(r);
          if (id == null) { skipped++; continue; }
          await _svc.delete(id);
        }
        if (skipped > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$skipped registros sin ID — no eliminados (redeploy backend)'),
            backgroundColor: Colors.orange,
          ));
        }
        _load();
      } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    }
  }

  Future<void> _editRow(Map<String, dynamic> row) async {
    final ct = context.ct;
    final fields = ['nr_orden','nr_sku','nr_unidades','tipo_etiqueta','fecha_creacion','usuario',
      'tipo_etiqueta_id','nr_box','nr_unidades_box','serial_old','serial_new','fecha_finalizacion'];
    final ctrls = Map.fromEntries(fields.map((k) => MapEntry(k, TextEditingController(text: row[k]?.toString() ?? ''))));
    final rowId = _rowId(row);
    final save = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      backgroundColor: ct.surface,
      title: Text('Editar registro #${rowId ?? ""}', style: TextStyle(color: ct.textPrimary)),
      content: SizedBox(width: 560, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
        children: ctrls.entries.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 5),
          child: TextField(controller: e.value, style: TextStyle(color: ct.textPrimary, fontSize: 13),
            decoration: InputDecoration(labelText: e.key, labelStyle: TextStyle(color: ct.textHint),
              filled: true, fillColor: ct.surfaceElevated,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10))))).toList()))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Guardar')),
      ]));
    if (save == true) {
      final payload = <String, dynamic>{};
      for (final e in ctrls.entries) { final v = e.value.text.trim(); if (v.isNotEmpty) payload[e.key] = v; }
      try {
        if (rowId == null) throw Exception('Row has no id');
        await _svc.update(rowId, payload); _load();
      } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    }
    for (final ctrl in ctrls.values) { ctrl.dispose(); }
  }
}
