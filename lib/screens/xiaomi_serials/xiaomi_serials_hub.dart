import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/cobalt_theme.dart';
import '../../core/colors.dart';

/// Hub screen for the "Xiaomi y Serials" nav section.
/// Lists all available sub-screens as tappable cards.
class XiaomiSerialsHub extends StatelessWidget {
  const XiaomiSerialsHub({super.key});

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return Scaffold(
      backgroundColor: ct.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xiaomi y Serials',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: ct.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Herramientas de gestión de seriales',
                style: TextStyle(fontSize: 13, color: ct.textSecondary),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _HubCard(
                    icon: Icons.swap_horiz_rounded,
                    title: 'Cambio de Serials',
                    subtitle: 'RMA — cambio de serial antiguo por nuevo',
                    onTap: () => context.push('/home/xiaomi/cambio-serials'),
                  ),
                  _HubCard(
                    icon: Icons.history_rounded,
                    title: 'Historial Serials',
                    subtitle: 'Buscar y consultar registros de cambio',
                    onTap: () => context.push('/home/xiaomi/historial-serials'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HubCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_HubCard> createState() => _HubCardState();
}

class _HubCardState extends State<_HubCard> {
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
          duration: const Duration(milliseconds: 150),
          width: 260,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _hovered ? ct.surfaceElevated : ct.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered ? CobaltColors.cobaltLight.withValues(alpha: 0.4) : ct.border,
            ),
            boxShadow: _hovered
                ? [BoxShadow(color: CobaltColors.cobalt.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4))]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: CobaltColors.cobalt.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, size: 20, color: CobaltColors.cobaltLight),
              ),
              const SizedBox(height: 14),
              Text(
                widget.title,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ct.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: TextStyle(fontSize: 12, color: ct.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
