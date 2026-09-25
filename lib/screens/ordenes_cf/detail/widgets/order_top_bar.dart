import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/cobalt_theme.dart';
import '../../../../core/colors.dart';
import '../../widgets/status_badge.dart';
import '../order_detail_controller.dart';

/// Compact top bar: ← Customer Name                   order#
///                  ● Status  ● Priority  Family
class OrderTopBar extends StatelessWidget {
  const OrderTopBar({super.key, required this.controller});
  final OrderDetailController controller;

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    final detail = controller.detail;
    if (detail == null) return const SizedBox(height: 56);

    final order = detail.agentOrder;
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      color: ct.surface,
      padding: EdgeInsets.only(top: topPad + 8, left: 4, right: 16, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: back + customer + order number
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: ct.textPrimary, size: 20),
                onPressed: () => context.pop(),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  order.customer,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ct.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _formatOrderNbr(order.orderNbr),
                style: TextStyle(
                  fontSize: 12,
                  color: CobaltColors.cobaltLight,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),

          // Row 2: badges
          Padding(
            padding: const EdgeInsets.only(left: 44, top: 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                StatusBadge(estado: order.estado),
                PrioridadBadge(prioridad: order.prioridad),
                if (order.family != null && order.family!.isNotEmpty)
                  _FamilyTag(label: order.family!),
                if (order.assignedToName != null && order.assignedToName!.isNotEmpty)
                  _AssigneeTag(label: order.assignedToName!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatOrderNbr(String nbr) {
    final clean = nbr.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 9) {
      return '${clean.substring(0, 2)}-${clean.substring(2, 7)}-${clean.substring(7)}';
    }
    return nbr;
  }
}

// ── Tiny helper chips ────────────────────────────────────────────────────────

class _FamilyTag extends StatelessWidget {
  const _FamilyTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: ct.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ct.textSecondary),
      ),
    );
  }
}

class _AssigneeTag extends StatelessWidget {
  const _AssigneeTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.person_outline, size: 12, color: ct.textHint),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: ct.textHint),
        ),
      ],
    );
  }
}
