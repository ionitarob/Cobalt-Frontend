import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/cobalt_theme.dart';
import '../../../../core/colors.dart';
import '../../../../models/orderops/agent_order.dart';
import '../../../../services/orderops/orders_service.dart';
import '../../widgets/status_badge.dart';
import '../order_detail_controller.dart';

class HeaderSection extends StatefulWidget {
  const HeaderSection({super.key, required this.controller});
  final OrderDetailController controller;

  @override
  State<HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends State<HeaderSection> {
  bool _pressedRecepcionar = false;
  bool _pressedComenzar = false;
  bool _pressedParar = false;
  bool _pressedFinalizar = false;
  bool _pressedReanudar = false;

  OrderDetailController get _ctrl => widget.controller;

  @override
  Widget build(BuildContext context) {
    if (_ctrl.detail == null) return const SizedBox.shrink();
    final ct = context.ct;
    final order = _ctrl.detail!.agentOrder;
    final statusColor = StatusBadge.colorFor(order.estado);
    final fmt = DateFormat('dd/MM/yy HH:mm');
    String fmtDt(DateTime? dt) => dt != null ? fmt.format(dt) : '—';

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Identity row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                order.customer,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: ct.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              order.orderNbr,
              style: const TextStyle(
                fontSize: 13,
                color: CobaltColors.cobaltLight,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Status, priority, family, assignee, project
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            StatusBadge(estado: order.estado),
            PrioridadBadge(prioridad: order.prioridad),
            _familiaChip(ct, order),
            _assignadoChip(ct, order),
            _proyectoChip(ct, order),
          ],
        ),

        const SizedBox(height: 12),
        Divider(height: 1, color: ct.border),
        const SizedBox(height: 10),

        // Timestamps + workflow actions
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _tsChip(ct, 'Recibida', fmtDt(order.orderDate)),
                _tsChip(ct, 'Completada', fmtDt(order.completedAt)),
                if (order.stopReason != null && order.stopReason!.isNotEmpty)
                  Tooltip(
                    message: order.stopReason!,
                    child: _tsChip(
                      ct,
                      'Motivo parada',
                      order.stopReason!.length > 25
                          ? '${order.stopReason!.substring(0, 25)}…'
                          : order.stopReason!,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ..._buildActions(ct, order),
                if (_ctrl.isPrivileged) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.edit_outlined, size: 16, color: ct.textHint),
                    tooltip: 'Cambiar estado (admin)',
                    onPressed: _showForceEstadoDialog,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );

    // Flutter requires uniform border colors when borderRadius is set.
    // Workaround: uniform outer border + inner Row with a colored left strip.
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ct.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ct.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: content,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Chips ─────────────────────────────────────────────────────────────────

  Widget _familiaChip(CobaltPalette ct, AgentOrder order) {
    final label = order.subfamilies.isNotEmpty
        ? order.subfamiliesDisplay
        : (order.family?.trim().isNotEmpty == true
            ? order.family!
            : 'Sin familia');
    return GestureDetector(
      onTap: _ctrl.isPrivileged ? _showFamilyDialog : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: ct.border,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _ctrl.isPrivileged
                ? CobaltColors.cobaltLight.withValues(alpha: 0.35)
                : ct.border,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            color: ct.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _assignadoChip(CobaltPalette ct, AgentOrder order) {
    final label = order.assignedToName ?? order.assignedTo ?? 'Sin asignar';
    return GestureDetector(
      onTap: _ctrl.isPrivileged ? _showAssigneeDialog : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: ct.border,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _ctrl.isPrivileged
                ? CobaltColors.cobaltLight.withValues(alpha: 0.35)
                : ct.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline_rounded, size: 12, color: ct.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: ct.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _proyectoChip(CobaltPalette ct, AgentOrder order) {
    final hasProyecto = order.proyecto != null;
    final label = hasProyecto ? 'Proy. ${order.proyecto}' : 'Sin proyecto';
    final chipColor = hasProyecto ? CobaltColors.cobaltLight : ct.textHint;
    return GestureDetector(
      onTap: _ctrl.isPrivileged ? _showProyectoDialog : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: ct.border,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasProyecto
                ? CobaltColors.cobaltLight.withValues(alpha: 0.5)
                : _ctrl.isPrivileged
                    ? CobaltColors.cobaltLight.withValues(alpha: 0.2)
                    : ct.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_outlined, size: 12, color: chipColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: chipColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tsChip(CobaltPalette ct, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 9.5, color: ct.textHint)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            color: ct.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ─── Workflow actions ───────────────────────────────────────────────────────

  List<Widget> _buildActions(CobaltPalette ct, AgentOrder order) {
    final estado = order.estado;
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final actions = <Widget>[];

    FilledButton filledBtn(String label, VoidCallback onTap, Color bg) =>
        FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: bg.withValues(alpha: 0.85),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(label),
        );

    Widget scaled({
      required Widget child,
      required bool pressed,
      required void Function(bool) setPressed,
    }) {
      final inner = disableAnimations
          ? child
          : AnimatedScale(
              scale: pressed ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 110),
              curve: Curves.easeOut,
              child: child,
            );
      return GestureDetector(
        onTapDown: (_) => setState(() => setPressed(true)),
        onTapUp: (_) => setState(() => setPressed(false)),
        onTapCancel: () => setState(() => setPressed(false)),
        child: inner,
      );
    }

    if (estado.contains('1')) {
      actions.add(scaled(
        pressed: _pressedRecepcionar,
        setPressed: (v) => _pressedRecepcionar = v,
        child: filledBtn('Recepcionar', () => _ctrl.updateEstado('2'),
            StatusBadge.colorFor('1')),
      ));
    }

    if (estado.contains('2')) {
      actions.add(scaled(
        pressed: _pressedComenzar,
        setPressed: (v) => _pressedComenzar = v,
        child: filledBtn('Comenzar', () => _ctrl.updateEstado('3'),
            StatusBadge.colorFor('2')),
      ));
    }

    if (estado.contains('3')) {
      actions.addAll([
        scaled(
          pressed: _pressedParar,
          setPressed: (v) => _pressedParar = v,
          child: OutlinedButton(
            onPressed: _showStopDialog,
            style: OutlinedButton.styleFrom(
              foregroundColor: StatusBadge.colorFor('4'),
              side: BorderSide(
                color: StatusBadge.colorFor('4').withValues(alpha: 0.7),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Parar'),
          ),
        ),
        const SizedBox(width: 8),
        scaled(
          pressed: _pressedFinalizar,
          setPressed: (v) => _pressedFinalizar = v,
          child: filledBtn('Finalizar', _handleFinalizar,
              StatusBadge.colorFor('5')),
        ),
      ]);
    }

    if (estado.contains('4')) {
      actions.add(scaled(
        pressed: _pressedReanudar,
        setPressed: (v) => _pressedReanudar = v,
        child: filledBtn('Reanudar', () => _ctrl.updateEstado('3'),
            StatusBadge.colorFor('3')),
      ));
    }

    if (estado.contains('5') || estado.contains('6')) {
      actions.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded,
              size: 15, color: StatusBadge.colorFor('5')),
          const SizedBox(width: 5),
          Text(
            'Completada',
            style: TextStyle(
              fontSize: 12,
              color: ct.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ));
    }

    return actions;
  }

  // ─── Dialogs ───────────────────────────────────────────────────────────────

  Future<void> _showFamilyDialog() async {
    List<String> families;
    try {
      families = await OrdersService.instance.getCatalogFamilies();
    } catch (_) {
      families = [];
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seleccionar familia'),
        content: SizedBox(
          width: 300,
          child: families.isEmpty
              ? const Text('No se encontraron familias')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: families.length,
                  itemBuilder: (_, i) => ListTile(
                    title: Text(families[i]),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _ctrl.updateFamily([families[i]]);
                    },
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAssigneeDialog() async {
    final searchCtrl = TextEditingController();
    List<Map<String, dynamic>> employees;
    try {
      employees = await OrdersService.instance.getEmployees(limit: 50);
    } catch (_) {
      employees = [];
    }
    if (!mounted) {
      searchCtrl.dispose();
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        var filtered = List<Map<String, dynamic>>.from(employees);
        return StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            title: const Text('Asignar responsable'),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Buscar por nombre…',
                      prefixIcon: Icon(Icons.search_rounded, size: 18),
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                    ),
                    onChanged: (q) => setS(() {
                      filtered = employees
                          .where((e) =>
                              (e['name'] as String? ?? '')
                                  .toLowerCase()
                                  .contains(q.toLowerCase()) ||
                              (e['username'] as String? ?? '')
                                  .toLowerCase()
                                  .contains(q.toLowerCase()))
                          .toList();
                    }),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length + 1,
                      itemBuilder: (_, i) {
                        if (i == 0) {
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.person_off_outlined, size: 18),
                            title: const Text('Sin asignar'),
                            onTap: () {
                              Navigator.of(ctx).pop();
                              _ctrl.updateAssignee();
                            },
                          );
                        }
                        final emp = filtered[i - 1];
                        final name = emp['name'] as String? ??
                            emp['username'] as String? ??
                            '—';
                        final username = emp['username'] as String? ?? '';
                        return ListTile(
                          dense: true,
                          title: Text(name),
                          subtitle: username.isNotEmpty
                              ? Text(username, style: const TextStyle(fontSize: 11))
                              : null,
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _ctrl.updateAssignee(
                              userId: username.isNotEmpty ? username : null,
                              name: name,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        );
      },
    );
    searchCtrl.dispose();
  }

  Future<void> _showProyectoDialog() async {
    final ctrl = TextEditingController(
      text: _ctrl.detail!.agentOrder.proyecto?.toString() ?? '',
    );
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vincular proyecto'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'ID del proyecto (vacío para desvincular)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(''),
            child: const Text('Desvincular'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result == null) return;
    final id = result.isEmpty ? null : int.tryParse(result);
    if (result.isNotEmpty && id == null) return;
    await _ctrl.linkProject(id);
  }

  Future<void> _showStopDialog() async {
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Motivo de parada'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Describe el motivo de la parada…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Parar orden'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (reason == null) return;
    await _ctrl.updateEstado(
      '4',
      stopReason: reason.isNotEmpty ? reason : null,
    );
  }

  Future<void> _handleFinalizar() async {
    final hasQuality = _ctrl.detail!.photos.any(
      (p) => p.scope.contains('quality'),
    );
    if (!hasQuality) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Fotos de calidad requeridas'),
          content: const Text(
            'Se requieren fotos de calidad para finalizar la orden.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }
    await _ctrl.updateEstado('5');
  }

  Future<void> _showForceEstadoDialog() async {
    String? selected;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Cambiar estado (admin)'),
          content: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Nuevo estado',
              border: OutlineInputBorder(),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selected,
                isDense: true,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: '1', child: Text('1 — Validada')),
                  DropdownMenuItem(value: '2', child: Text('2 — Pendiente')),
                  DropdownMenuItem(value: '3', child: Text('3 — En Ejecución')),
                  DropdownMenuItem(value: '4', child: Text('4 — Parada')),
                  DropdownMenuItem(value: '5', child: Text('5 — Finalizada')),
                  DropdownMenuItem(value: '6', child: Text('6 — Facturada')),
                ],
                onChanged: (v) => setS(() => selected = v),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed:
                  selected == null ? null : () => Navigator.of(ctx).pop(true),
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && selected != null) {
      await _ctrl.updateEstado(selected!, force: true);
    }
  }
}
