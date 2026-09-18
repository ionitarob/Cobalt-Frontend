import 'package:flutter/material.dart';

import '../../../core/cobalt_theme.dart';
import '../../../core/colors.dart';
import '../../../models/orderops/my_task.dart';
import '../../../services/orderops/tasks_service.dart';

class MyTasksTab extends StatefulWidget {
  const MyTasksTab({super.key});

  @override
  State<MyTasksTab> createState() => _MyTasksTabState();
}

class _MyTasksTabState extends State<MyTasksTab> {
  List<MyTask> _tasks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final tasks = await TasksService.instance.getMyTasks();
      if (mounted) setState(() { _tasks = tasks; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _toggle(MyTask task) async {
    try {
      if (task.type == MyTaskType.order) {
        await TasksService.instance.toggleOrderTask(
            task.idnbr!, task.id, !task.done);
      } else {
        await TasksService.instance.toggleAprovTask(
            task.aprovisionamientoId!, task.id, !task.done);
      }
      setState(() {
        final idx = _tasks.indexWhere((t) => t.id == task.id && t.type == task.type);
        if (idx >= 0) _tasks[idx] = task.copyWith(done: !task.done);
      });
    } catch (_) {}
  }

  List<MyTask> get _orderTasks =>
      _tasks.where((t) => t.type == MyTaskType.order).toList();

  List<MyTask> get _aprovTasks =>
      _tasks.where((t) => t.type == MyTaskType.aprovisionamiento).toList();

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: CobaltColors.cobaltLight));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFFF5252), size: 40),
            const SizedBox(height: 12),
            Text(_error!,
                style: TextStyle(
                    color: ct.textHint, fontSize: 13)),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    if (_tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt_rounded,
                size: 48, color: ct.textHint),
            const SizedBox(height: 12),
            Text('Sin tareas pendientes.',
                style: TextStyle(
                    color: ct.textHint, fontSize: 14)),
          ],
        ),
      );
    }

    final pending = _tasks.where((t) => !t.done).length;
    final total = _tasks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: Row(
            children: [
              _ProgressPill(done: total - pending, total: total),
              const Spacer(),
              _RefreshBtn(onTap: _load),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (_orderTasks.isNotEmpty) ...[
                _sectionHeader(ct, 'Tareas de órdenes', _orderTasks.length),
                ..._orderTasks.map((t) => _TaskTile(
                    task: t, onToggle: () => _toggle(t))),
              ],
              if (_aprovTasks.isNotEmpty) ...[
                const SizedBox(height: 8),
                _sectionHeader(ct, 'Aprovisionamiento', _aprovTasks.length),
                ..._aprovTasks.map((t) => _TaskTile(
                    task: t, onToggle: () => _toggle(t))),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(CobaltPalette ct, String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          Text(title.toUpperCase(),
              style: TextStyle(
                  color: ct.textHint,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: CobaltColors.cobalt.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: const TextStyle(
                    color: CobaltColors.cobaltLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final MyTask task;
  final VoidCallback onToggle;

  const _TaskTile({required this.task, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onToggle,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: ct.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: task.done
                    ? ct.border.withValues(alpha: 0.5)
                    : ct.border),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: task.done
                      ? const Color(0xFF2EC672)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                      color: task.done
                          ? const Color(0xFF2EC672)
                          : ct.border,
                      width: 1.5),
                ),
                child: task.done
                    ? const Icon(Icons.check_rounded,
                        size: 12, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.titulo,
                        style: TextStyle(
                            color: task.done
                                ? ct.textHint
                                : ct.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            decoration: task.done
                                ? TextDecoration.lineThrough
                                : TextDecoration.none)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(task.orderNbr,
                            style: const TextStyle(
                                color: CobaltColors.cobaltLight,
                                fontSize: 10,
                                fontWeight: FontWeight.w500)),
                        Text(' · ',
                            style: TextStyle(
                                color: ct.textHint, fontSize: 10)),
                        Expanded(
                          child: Text(task.customer,
                              style: TextStyle(
                                  color: ct.textHint, fontSize: 10),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: task.type == MyTaskType.order
                      ? CobaltColors.cobalt.withValues(alpha: 0.10)
                      : const Color(0xFF00B8D4).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  task.type == MyTaskType.order ? 'Orden' : 'Aprov.',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: task.type == MyTaskType.order
                          ? CobaltColors.cobaltLight
                          : const Color(0xFF00B8D4)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressPill extends StatelessWidget {
  final int done;
  final int total;
  const _ProgressPill({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    final pct = total > 0 ? (done / total * 100).round() : 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 100,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? done / total : 0,
              minHeight: 4,
              backgroundColor: ct.border,
              color: done == total && total > 0
                  ? const Color(0xFF2EC672)
                  : CobaltColors.cobaltLight,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$done/$total ($pct%)',
            style: TextStyle(
                color: ct.textHint,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _RefreshBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _RefreshBtn({required this.onTap});

  @override
  State<_RefreshBtn> createState() => _RefreshBtnState();
}

class _RefreshBtnState extends State<_RefreshBtn> {
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
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: _hovered
                ? CobaltColors.cobalt.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(Icons.refresh_rounded, size: 16,
              color: _hovered
                  ? CobaltColors.cobaltLight
                  : ct.textSecondary),
        ),
      ),
    );
  }
}
