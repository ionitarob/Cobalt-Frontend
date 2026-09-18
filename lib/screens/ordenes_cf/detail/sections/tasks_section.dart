import 'package:flutter/material.dart';

import '../../../../core/cobalt_theme.dart';
import '../../../../core/colors.dart';
import '../../../../models/orderops/order_task.dart';
import '../../../../services/orderops/templates_service.dart';
import '../order_detail_controller.dart';

class TasksSection extends StatefulWidget {
  const TasksSection({super.key, required this.controller});

  final OrderDetailController controller;

  @override
  State<TasksSection> createState() => _TasksSectionState();
}

class _TasksSectionState extends State<TasksSection> {
  late final TextEditingController _newCtrl;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _newCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _newCtrl.dispose();
    super.dispose();
  }

  OrderDetailController get _c => widget.controller;

  Future<void> _addTask() async {
    final text = _newCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _adding = true);
    await _c.addTask(text);
    _newCtrl.clear();
    if (mounted) setState(() => _adding = false);
  }

  Future<void> _confirmDelete(BuildContext context, int taskId) async {
    final ct = context.ct;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ct.surface,
        title: Text('Eliminar tarea', style: TextStyle(color: ct.textPrimary, fontSize: 15)),
        content: Text('¿Eliminar esta tarea?', style: TextStyle(color: ct.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: ct.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) await _c.deleteTask(taskId);
  }

  void _showTemplateDialog(BuildContext context) {
    final ct = context.ct;
    final detail = _c.detail;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ct.surface,
        title: Text(
          'Aplicar plantilla',
          style: TextStyle(color: ct.textPrimary, fontSize: 15),
        ),
        content: SizedBox(
          width: 320,
          child: FutureBuilder<List<ChecklistTemplate>>(
            future: TemplatesService.instance.getTemplates(
              family: detail?.agentOrder.family,
            ),
            builder: (ctx2, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              final templates = snap.data ?? [];
              if (templates.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Sin plantillas disponibles',
                    style: TextStyle(color: ct.textHint, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                itemCount: templates.length,
                separatorBuilder: (context2, i2) => Divider(color: ct.border, height: 1),
                itemBuilder: (_, i) {
                  final t = templates[i];
                  return ListTile(
                    dense: true,
                    title: Text(t.name, style: TextStyle(color: ct.textPrimary, fontSize: 13)),
                    subtitle: t.description != null
                        ? Text(t.description!, style: TextStyle(color: ct.textHint, fontSize: 11))
                        : null,
                    trailing: Text(
                      '${t.items.length} tareas',
                      style: TextStyle(color: ct.textHint, fontSize: 11),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _c.applyTemplate(t.id);
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: ct.textSecondary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    final tasks = _c.tasks;
    final detail = _c.detail;
    final isPrivileged = _c.isPrivileged;
    final loading = _c.loading;

    final total = detail?.agentOrder.planTotal ?? tasks.length;
    final done = detail?.agentOrder.planDone ?? tasks.where((t) => t.done).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'TAREAS',
              style: TextStyle(
                color: ct.textHint,
                fontSize: 9.5,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$done/${tasks.length}',
              style: TextStyle(color: ct.textHint, fontSize: 11),
            ),
            const Spacer(),
            if (isPrivileged)
              TextButton(
                onPressed: () => _showTemplateDialog(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Plantilla',
                  style: TextStyle(color: CobaltColors.cobaltLight, fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: total > 0 ? done / total : 0,
          color: CobaltColors.cobaltLight,
          backgroundColor: ct.border,
          minHeight: 3,
          borderRadius: BorderRadius.circular(2),
        ),
        const SizedBox(height: 4),
        Text(
          '$done/$total completadas',
          style: TextStyle(color: ct.textHint, fontSize: 10),
        ),
        const SizedBox(height: 12),
        if (tasks.isEmpty && !loading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Sin tareas registradas',
              style: TextStyle(color: ct.textHint, fontSize: 13),
            ),
          ),
        ...tasks.map(
          (task) => _TaskRow(
            key: ValueKey(task.id),
            task: task,
            ct: ct,
            isPrivileged: isPrivileged,
            onToggle: (v) => _c.toggleTask(task.id, v),
            onDelete: () => _confirmDelete(context, task.id),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newCtrl,
                style: TextStyle(color: ct.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Nueva tarea...',
                  hintStyle: TextStyle(color: ct.textHint, fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                ),
                onSubmitted: (_) => _addTask(),
              ),
            ),
            if (_adding)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                icon: const Icon(Icons.add, color: CobaltColors.cobaltLight),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: _addTask,
              ),
          ],
        ),
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    super.key,
    required this.task,
    required this.ct,
    required this.isPrivileged,
    required this.onToggle,
    required this.onDelete,
  });

  final AgentOrderTask task;
  final CobaltPalette ct;
  final bool isPrivileged;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return SizedBox(
      height: 46,
      child: Row(
        children: [
          Checkbox(
            value: task.done,
            onChanged: (v) => onToggle(v!),
            checkColor: ct.background,
            fillColor: WidgetStateProperty.resolveWith(
              (_) => task.done ? CobaltColors.cobalt : ct.border,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: BorderSide(color: ct.border),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: disableAnimations
                ? Text(
                    task.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: task.done
                        ? TextStyle(
                            color: ct.textHint,
                            decoration: TextDecoration.lineThrough,
                            fontSize: 13,
                          )
                        : TextStyle(color: ct.textPrimary, fontSize: 13),
                  )
                : AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    style: task.done
                        ? TextStyle(
                            color: ct.textHint,
                            decoration: TextDecoration.lineThrough,
                            fontSize: 13,
                          )
                        : TextStyle(color: ct.textPrimary, fontSize: 13),
                    child: Text(
                      task.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          ),
          if (isPrivileged)
            IconButton(
              icon: Icon(Icons.close, size: 16, color: ct.textHint),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
