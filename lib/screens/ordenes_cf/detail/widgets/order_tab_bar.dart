import 'package:flutter/material.dart';

import '../../../../core/cobalt_theme.dart';
import '../../../../core/colors.dart';

/// Slim tab bar for order detail sections.
class OrderTabBar extends StatelessWidget {
  const OrderTabBar({super.key, required this.controller});
  final TabController controller;

  static const tabs = ['Servicios', 'Tareas', 'Archivos', 'Historial'];

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return Container(
      decoration: BoxDecoration(
        color: ct.surface,
        border: Border(bottom: BorderSide(color: ct.border, width: 0.5)),
      ),
      child: TabBar(
        controller: controller,
        labelColor: CobaltColors.cobaltLight,
        unselectedLabelColor: ct.textHint,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        indicatorColor: CobaltColors.cobaltLight,
        indicatorWeight: 2,
        dividerHeight: 0,
        tabs: [for (final t in tabs) Tab(height: 38, text: t)],
      ),
    );
  }
}
