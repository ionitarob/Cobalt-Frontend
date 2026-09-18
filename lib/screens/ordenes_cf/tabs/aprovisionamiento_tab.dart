import 'package:flutter/material.dart';

import '../../../core/cobalt_theme.dart';
import '../../../core/colors.dart';
import '../../../models/orderops/aprovisionamiento.dart';
import '../../../services/orderops/aprovisionamiento_service.dart';
import '../sheets/aprov_panel.dart';

class AprovisionamientoTab extends StatefulWidget {
  const AprovisionamientoTab({super.key});

  @override
  State<AprovisionamientoTab> createState() => _AprovisionamientoTabState();
}

class _AprovisionamientoTabState extends State<AprovisionamientoTab> {
  List<AprovisionamientoRecord> _records = [];
  bool _loading = true;
  String? _error;
  AprovisionamientoRecord? _panelRecord;
  bool _panelOpen = false;
  final Set<int> _expanded = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await AprovisionamientoService.instance.getAll();
      if (mounted) setState(() { _records = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  void _openCreate() => setState(() { _panelRecord = null; _panelOpen = true; });
  void _openEdit(AprovisionamientoRecord r) =>
      setState(() { _panelRecord = r; _panelOpen = true; });
  void _closePanel() => setState(() => _panelOpen = false);

  void _onPanelSaved() {
    _closePanel();
    _load();
  }

  Future<void> _delete(AprovisionamientoRecord r) async {
    try {
      await AprovisionamientoService.instance.delete(r.id);
      _load();
    } catch (_) {}
  }

  Future<void> _toggleTask(AprovisionamientoRecord r, AprovisionamientoTask task) async {
    try {
      await AprovisionamientoService.instance.toggleTask(
          r.id, task.id, !task.done);
      await _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _toolbar(ct),
            if (_loading)
              const Expanded(
                  child: Center(
                      child: CircularProgressIndicator(color: CobaltColors.cobaltLight)))
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFFF5252), size: 40),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: TextStyle(
                              color: ct.textHint, fontSize: 13)),
                      const SizedBox(height: 12),
                      TextButton(onPressed: _load, child: const Text('Reintentar')),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: _records.isEmpty
                    ? _emptyState(ct)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _records.length,
                        itemBuilder: (_, i) => _RecordCard(
                          record: _records[i],
                          expanded: _expanded.contains(_records[i].id),
                          onToggleExpand: () => setState(() {
                            if (_expanded.contains(_records[i].id)) {
                              _expanded.remove(_records[i].id);
                            } else {
                              _expanded.add(_records[i].id);
                            }
                          }),
                          onEdit: () => _openEdit(_records[i]),
                          onDelete: () => _delete(_records[i]),
                          onToggleTask: (task) => _toggleTask(_records[i], task),
                        ),
                      ),
              ),
          ],
        ),
        // Slide-in panel
        AnimatedPositioned(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          right: _panelOpen ? 0 : -420,
          top: 0,
          bottom: 0,
          child: _panelOpen
              ? AprovPanel(
                  existing: _panelRecord,
                  onSaved: _onPanelSaved,
                )
              : const SizedBox(width: 0),
        ),
      ],
    );
  }

  Widget _toolbar(CobaltPalette ct) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        children: [
          Text('${_records.length} registros',
              style: TextStyle(
                  color: ct.textHint, fontSize: 12)),
          const Spacer(),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _openCreate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [CobaltColors.cobalt, CobaltColors.cobaltLight]),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text('Nuevo',
                        style: TextStyle(color: Colors.white,
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _IconBtn(icon: Icons.refresh_rounded, onTap: _load),
        ],
      ),
    );
  }

  Widget _emptyState(CobaltPalette ct) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded, size: 48, color: ct.textHint),
          const SizedBox(height: 12),
          Text('Sin registros de aprovisionamiento.',
              style: TextStyle(color: ct.textHint, fontSize: 14)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _openCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Crear primero'),
          ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final AprovisionamientoRecord record;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(AprovisionamientoTask) onToggleTask;

  const _RecordCard({
    required this.record,
    required this.expanded,
    required this.onToggleExpand,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleTask,
  });

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    final doneCount = record.tasks.where((t) => t.done).length;
    final totalCount = record.tasks.length;
    final progress = totalCount > 0 ? doneCount / totalCount : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: ct.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: record.isLinked
                ? CobaltColors.cobaltLight.withValues(alpha: 0.35)
                : ct.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cardHeader(ct, progress, doneCount, totalCount),
          if (expanded) _cardBody(ct),
        ],
      ),
    );
  }

  Widget _cardHeader(CobaltPalette ct, double progress, int done, int total) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onToggleExpand,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(record.customer,
                                style: TextStyle(
                                    color: ct.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            if (record.isLinked) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: CobaltColors.cobalt.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: CobaltColors.cobaltLight.withValues(alpha: 0.4)),
                                ),
                                child: Text(record.orderNbr ?? '',
                                    style: const TextStyle(
                                        color: CobaltColors.cobaltLight,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ],
                        ),
                        if (record.family != null)
                          Text(record.family!,
                              style: TextStyle(
                                  color: ct.textHint, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text('$done/$total tareas',
                      style: TextStyle(
                          color: ct.textHint, fontSize: 11)),
                  const SizedBox(width: 10),
                  _iconAction(Icons.edit_outlined, onEdit),
                  const SizedBox(width: 4),
                  _iconAction(Icons.delete_outline_rounded, onDelete),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        size: 18, color: ct.textHint),
                  ),
                ],
              ),
              if (total > 0) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: ct.border,
                    color: progress >= 1.0
                        ? const Color(0xFF2EC672)
                        : CobaltColors.cobaltLight,
                    minHeight: 3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardBody(CobaltPalette ct) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: ct.border)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (record.notas != null && record.notas!.isNotEmpty) ...[
            Text(record.notas!,
                style: TextStyle(
                    color: ct.textSecondary, fontSize: 12)),
            const SizedBox(height: 10),
          ],
          ...record.tasks.map((task) => _taskRow(ct, task)),
        ],
      ),
    );
  }

  Widget _taskRow(CobaltPalette ct, AprovisionamientoTask task) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onToggleTask(task),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: task.done
                      ? const Color(0xFF2EC672)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: task.done
                          ? const Color(0xFF2EC672)
                          : ct.border,
                      width: 1.5),
                ),
                child: task.done
                    ? const Icon(Icons.check_rounded,
                        size: 11, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(task.titulo,
                    style: TextStyle(
                        color: task.done
                            ? ct.textHint
                            : ct.textPrimary,
                        fontSize: 12,
                        decoration: task.done
                            ? TextDecoration.lineThrough
                            : TextDecoration.none)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconAction(IconData icon, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Builder(
            builder: (context) => Icon(icon, size: 14, color: context.ct.textHint),
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: _hovered
                ? CobaltColors.cobalt.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(widget.icon, size: 16,
              color: _hovered
                  ? CobaltColors.cobaltLight
                  : ct.textSecondary),
        ),
      ),
    );
  }
}
