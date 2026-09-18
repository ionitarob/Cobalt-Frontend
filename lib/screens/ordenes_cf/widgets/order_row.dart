import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/cobalt_theme.dart';
import '../../../core/colors.dart';
import '../../../models/orderops/agent_order.dart';
import 'status_badge.dart';

String formatDate(DateTime? dt) {
  if (dt == null) return '-';
  return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

String formatOrderNbr(String nbr) {
  final clean = nbr.replaceAll(RegExp(r'[^0-9]'), '');
  if (clean.length == 9) {
    return '${clean.substring(0, 2)}-${clean.substring(2, 7)}-${clean.substring(7, 9)}';
  }
  return nbr;
}

class OrderTableRow extends StatefulWidget {
  final AgentOrder order;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onFamilyPick;

  const OrderTableRow({
    super.key,
    required this.order,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
    this.onLongPress,
    this.onFamilyPick,
  });

  @override
  State<OrderTableRow> createState() => _OrderTableRowState();
}

class _OrderTableRowState extends State<OrderTableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    final o = widget.order;
    final accent = StatusBadge.colorFor(o.estado);
    final leftBorderWidth = widget.selected ? 3.0 : 2.0;
    final leftBorderColor = widget.selected ? CobaltColors.cobaltLight : accent.withValues(alpha: 0.6);

    Color bgColor;
    if (widget.selected) {
      bgColor = CobaltColors.cobalt.withValues(alpha: 0.08);
    } else if (_hovered) {
      bgColor = CobaltColors.cobalt.withValues(alpha: 0.04);
    } else {
      bgColor = Colors.transparent;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.selectionMode
            ? widget.onTap
            : () => context.push('/home/ordenes-cf/${widget.order.idnbr}'),
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 46,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              left: BorderSide(color: leftBorderColor, width: leftBorderWidth),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.selectionMode)
                SizedBox(
                  width: 44,
                  child: Checkbox(
                    value: widget.selected,
                    onChanged: (_) => widget.onTap(),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    side: BorderSide(color: ct.border, width: 1.5),
                    activeColor: CobaltColors.cobaltLight,
                  ),
                ),
              // Nº Orden — flex 3
              _Cell(flex: 3, child: Text(formatOrderNbr(o.orderNbr),
                  style: const TextStyle(color: CobaltColors.cobaltLight,
                      fontWeight: FontWeight.w700, fontSize: 13))),
              // Fecha — flex 2
              _Cell(flex: 2, child: Text(formatDate(o.orderDate),
                  style: TextStyle(color: ct.textSecondary, fontSize: 12))),
              // Cliente — flex 4
              _Cell(flex: 4, child: Text(o.customer,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: ct.textPrimary,
                      fontWeight: FontWeight.w600, fontSize: 13))),
              // Descripción — flex 5 (matches header)
              Expanded(flex: 5, child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Tooltip(
                  message: o.sourceCommentsExcerpt ?? '',
                  child: Text(o.sourcePrimaryDesc ?? 'Sin descripción',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: ct.textSecondary, fontSize: 12)),
                ),
              )),
              // Familia — flex 3
              _Cell(flex: 3, child: Tooltip(
                message: o.subfamiliesDisplay,
                child: Text(
                    o.subfamiliesDisplay.isNotEmpty
                        ? o.subfamiliesDisplay
                        : (o.family ?? '-'),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: CobaltColors.cobaltLight,
                        fontWeight: FontWeight.w600, fontSize: 12)),
              )),
              // Prioridad — flex 3
              _Cell(flex: 3, child: PrioridadBadge(prioridad: o.prioridad)),
              // Asignado — flex 3
              _Cell(flex: 3, child: Text(o.assignedToName ?? o.assignedTo ?? '-',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: ct.textPrimary, fontSize: 12))),
              // Estado + family picker — flex 4
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      if ((o.family == null || o.family!.isEmpty) && widget.onFamilyPick != null) ...[
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: widget.onFamilyPick,
                            child: const Tooltip(
                              message: 'Asignar familia',
                              child: Icon(Icons.assignment_add,
                                  size: 16, color: Color(0xFFFFAA00)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(child: StatusBadge(estado: o.estado)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final int flex;
  final Widget child;
  const _Cell({required this.flex, required this.child});

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Align(alignment: Alignment.centerLeft, child: child),
        ),
      );
}
