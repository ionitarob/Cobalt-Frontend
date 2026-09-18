import 'package:flutter/material.dart';

import '../../../core/cobalt_theme.dart';
import '../../../core/colors.dart';
import '../../../models/orderops/agent_order.dart';
import 'month_header.dart';
import 'order_row.dart';

class OrderTable extends StatelessWidget {
  final Map<String, List<AgentOrder>> grouped;
  final Set<int> selectedIds;
  final bool selectionMode;
  final bool allSelected;
  final void Function(AgentOrder) onOrderTap;
  final void Function(AgentOrder) onOrderLongPress;
  final void Function(AgentOrder) onFamilyPick;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;

  const OrderTable({
    super.key,
    required this.grouped,
    required this.selectedIds,
    required this.selectionMode,
    required this.allSelected,
    required this.onOrderTap,
    required this.onOrderLongPress,
    required this.onFamilyPick,
    required this.onSelectAll,
    required this.onDeselectAll,
  });

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    // Flatten into [String(month), AgentOrder, ...] list
    final items = <dynamic>[];
    grouped.forEach((month, orders) {
      items.add(month);
      items.addAll(orders);
    });

    return Column(
      children: [
        // Header row
        _TableHeader(
          selectionMode: selectionMode,
          allSelected: allSelected,
          anySelected: selectedIds.isNotEmpty,
          onToggleAll: allSelected ? onDeselectAll : onSelectAll,
        ),
        // Data rows
        Expanded(
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (context, i) {
              if (items[i] is String ||
                  (i + 1 < items.length && items[i + 1] is String)) {
                return const SizedBox.shrink();
              }
              return Container(
                  height: 1, color: ct.border.withValues(alpha: 0.4));
            },
            itemBuilder: (context, i) {
              final item = items[i];
              if (item is String) {
                return MonthHeader(month: item);
              }
              final order = item as AgentOrder;
              return OrderTableRow(
                order: order,
                selected: selectedIds.contains(order.idnbr),
                selectionMode: selectionMode,
                onTap: () => onOrderTap(order),
                onLongPress: () => onOrderLongPress(order),
                onFamilyPick: () => onFamilyPick(order),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  final bool selectionMode;
  final bool allSelected;
  final bool anySelected;
  final VoidCallback onToggleAll;

  const _TableHeader({
    required this.selectionMode,
    required this.allSelected,
    required this.anySelected,
    required this.onToggleAll,
  });

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: ct.surface,
        border: Border(bottom: BorderSide(color: ct.border, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (selectionMode)
            SizedBox(
              width: 44,
              child: Checkbox(
                value: allSelected ? true : (anySelected ? null : false),
                tristate: true,
                onChanged: (_) => onToggleAll(),
                side: BorderSide(color: ct.border, width: 1.5),
                activeColor: CobaltColors.cobaltLight,
              ),
            ),
          _HeaderCell('Nº Pedido', 3),
          _HeaderCell('Fecha', 2),
          _HeaderCell('Cliente', 4),
          _HeaderCell('Descripción', 5),
          _HeaderCell('Familia', 3),
          _HeaderCell('Prioridad', 3),
          _HeaderCell('Asignado', 3),
          _HeaderCell('Estado', 4),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final int flex;
  const _HeaderCell(this.label, this.flex);

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: ct.textHint,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
