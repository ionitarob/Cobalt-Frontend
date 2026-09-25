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
  String _filter = 'serial'; // serial | nr_orden | nr_box
  List<Map<String, dynamic>> _rows = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final q = _searchCtrl.text.trim();
      if (q.isEmpty) {
        _rows = await _svc.list(limit: 200);
      } else {
        _rows = await _svc.search(
          serial: _filter == 'serial' ? q : null,
          nrOrden: _filter == 'nr_orden' ? q : null,
          nrBox: _filter == 'nr_box' ? q : null,
          q: q,
        );
      }
    } catch (e) { _error = e.toString(); }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return Scaffold(
      backgroundColor: ct.background,
      body: SafeArea(child: Column(children: [
        _topBar(ct),
        Divider(height: 1, color: ct.border),
        _searchBar(ct),
        Divider(height: 1, color: ct.border),
        Expanded(child: _body(ct)),
      ])),
    );
  }


  Widget _topBar(CobaltPalette ct) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), color: ct.surface,
    child: Row(children: [
      IconButton(icon: Icon(Icons.arrow_back_rounded, color: ct.textPrimary, size: 20), onPressed: () => context.pop()),
      const SizedBox(width: 4), Icon(Icons.history_rounded, size: 18, color: CobaltColors.cobaltLight), const SizedBox(width: 8),
      Text('Historial Serials', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ct.textPrimary)),
      const Spacer(),
      if (_rows.isNotEmpty) Text('${_rows.length} registros', style: TextStyle(fontSize: 11, color: ct.textHint)),
    ]));

  Widget _searchBar(CobaltPalette ct) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), color: ct.surface,
    child: Row(children: [
      ...['serial', 'nr_orden', 'nr_box'].map((f) => Padding(padding: const EdgeInsets.only(right: 6),
        child: ChoiceChip(label: Text(f == 'serial' ? 'Serial' : f == 'nr_orden' ? 'Orden' : 'Caja', style: TextStyle(fontSize: 11, color: _filter == f ? Colors.white : ct.textSecondary)),
          selected: _filter == f, onSelected: (_) => setState(() { _filter = f; if (_searchCtrl.text.isNotEmpty) _load(); }),
          selectedColor: CobaltColors.cobalt, backgroundColor: ct.surfaceElevated, side: BorderSide(color: _filter == f ? CobaltColors.cobalt : ct.border),
          padding: const EdgeInsets.symmetric(horizontal: 4), visualDensity: VisualDensity.compact))),
      const SizedBox(width: 8),
      Expanded(child: SizedBox(height: 36, child: TextField(controller: _searchCtrl, style: TextStyle(color: ct.textPrimary, fontSize: 13),
        decoration: InputDecoration(hintText: 'Buscar...', hintStyle: TextStyle(color: ct.textHint, fontSize: 13),
          prefixIcon: Icon(Icons.search, size: 18, color: ct.textHint), filled: true, fillColor: ct.surfaceElevated,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10)), onSubmitted: (_) => _load()))),
    ]));

  Widget _body(CobaltPalette ct) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: CobaltColors.cobaltLight));
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)));
    if (_rows.isEmpty) return Center(child: Text('Sin resultados', style: TextStyle(color: ct.textHint)));
    return ListView.separated(padding: const EdgeInsets.all(12), itemCount: _rows.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: ct.border.withValues(alpha: 0.3)),
      itemBuilder: (_, i) => _row(ct, _rows[i]));
  }

  Widget _row(CobaltPalette ct, Map<String, dynamic> r) {
    final fmt = DateFormat('dd/MM/yy HH:mm');
    String fmtDt(dynamic v) { if (v == null) return '-'; try { return fmt.format(DateTime.parse(v.toString())); } catch (_) { return v.toString(); } }
    return InkWell(onLongPress: () => _actions(r), child: Padding(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(children: [
        Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r['serial_new']?.toString() ?? '-', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CobaltColors.cobaltLight, fontFeatures: const [FontFeature.tabularFigures()])),
          const SizedBox(height: 2),
          Row(children: [Icon(Icons.arrow_back, size: 10, color: ct.textHint), const SizedBox(width: 4),
            Text(r['serial_old']?.toString() ?? '-', style: TextStyle(fontSize: 12, color: ct.textSecondary, fontFeatures: const [FontFeature.tabularFigures()]))])])),
        Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r['nr_orden']?.toString() ?? '-', style: TextStyle(fontSize: 12, color: ct.textPrimary)),
          Text('Caja ${r['nr_box'] ?? '-'}', style: TextStyle(fontSize: 11, color: ct.textHint))])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(fmtDt(r['fecha_creacion']), style: TextStyle(fontSize: 11, color: ct.textHint)),
          Text(r['usuario']?.toString() ?? '', style: TextStyle(fontSize: 11, color: ct.textSecondary))]),
      ])));
  }

  void _actions(Map<String, dynamic> r) {
    final ct = context.ct;
    showModalBottomSheet(context: context, backgroundColor: ct.surface, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.delete_outline, color: Colors.redAccent), title: const Text('Eliminar'), onTap: () async {
        Navigator.pop(ctx);
        final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Eliminar registro'), content: const Text('No se puede deshacer.'),
          actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Eliminar'))]));
        if (ok == true) { await _svc.delete(r['id'] as int); _load(); }
      }),
      ListTile(leading: Icon(Icons.close, color: ct.textHint), title: const Text('Cancelar'), onTap: () => Navigator.pop(ctx)),
    ])));
  }
}
