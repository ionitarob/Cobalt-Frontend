import 'package:flutter/material.dart';

import '../../../../core/cobalt_theme.dart';
import '../../../../core/colors.dart';
import '../../../../models/orderops/order_detail.dart';
import '../order_detail_controller.dart';

class ObservationsSection extends StatefulWidget {
  const ObservationsSection({super.key, required this.controller});
  final OrderDetailController controller;

  @override
  State<ObservationsSection> createState() => _ObservationsSectionState();
}

class _ObservationsSectionState extends State<ObservationsSection> {
  late final TextEditingController _inputCtrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _inputCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await widget.controller.addObservation(text);
      _inputCtrl.clear();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  static String _fmtDate(DateTime dt) {
    final d = dt.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}'
        ' ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  static String _initials(String author) {
    final parts = author.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      final w = parts.first;
      return (w.length > 1 ? '${w[0]}${w[w.length - 1]}' : w[0]).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    final sorted =
        (widget.controller.detail?.observations ?? <AgentOrderObservation>[])
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Inline add — always visible at top
        Container(
          decoration: BoxDecoration(
            color: ct.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  maxLines: 3,
                  minLines: 1,
                  style: TextStyle(color: ct.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Añadir observación...',
                    hintStyle: TextStyle(color: ct.textHint),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send),
                      color: CobaltColors.cobaltLight,
                      onPressed: _submit,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Section title
        Text(
          'OBSERVACIONES ${sorted.length}',
          style: TextStyle(
            color: ct.textHint,
            fontSize: 9.5,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),

        // List or empty state
        if (sorted.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Sin observaciones registradas',
              style: TextStyle(color: ct.textHint),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: sorted.length,
              itemBuilder: (context, index) => _ObsTile(
                obs: sorted[index],
                controller: widget.controller,
                fmtDate: _fmtDate,
                initials: _initials,
              ),
            ),
          ),
      ],
    );
  }
}

// Single observation tile — owns hover state for privileged action buttons.
class _ObsTile extends StatefulWidget {
  const _ObsTile({
    required this.obs,
    required this.controller,
    required this.fmtDate,
    required this.initials,
  });

  final AgentOrderObservation obs;
  final OrderDetailController controller;
  final String Function(DateTime) fmtDate;
  final String Function(String) initials;

  @override
  State<_ObsTile> createState() => _ObsTileState();
}

class _ObsTileState extends State<_ObsTile> {
  bool _hovering = false;

  Future<void> _showEditDialog() async {
    final editCtrl = TextEditingController(text: widget.obs.body);
    final newBody = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar observación'),
        content: TextField(
          controller: editCtrl,
          maxLines: null,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(editCtrl.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    editCtrl.dispose();
    if (newBody == null || newBody.isEmpty) return;
    await widget.controller.editObservation(widget.obs.id, newBody);
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar observación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.controller.deleteObservation(widget.obs.id);
  }

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    final isPrivileged = widget.controller.isPrivileged;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author avatar
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CobaltColors.cobalt.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Text(
                widget.initials(widget.obs.author),
                style: const TextStyle(
                  color: CobaltColors.cobaltLight,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Body column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.obs.author,
                        style: TextStyle(
                          color: ct.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        widget.fmtDate(widget.obs.createdAt),
                        style: TextStyle(color: ct.textHint, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.obs.body,
                    style: TextStyle(color: ct.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),

            // Privileged hover actions
            if (isPrivileged && _hovering)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: ct.textHint, size: 16),
                    onPressed: _showEditDialog,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: ct.textHint, size: 16),
                    onPressed: _confirmDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
