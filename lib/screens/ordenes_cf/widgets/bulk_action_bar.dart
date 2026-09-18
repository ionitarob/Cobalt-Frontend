import 'package:flutter/material.dart';

import '../../../core/cobalt_theme.dart';
import '../../../core/colors.dart';

class BulkActionBar extends StatelessWidget {
  final int count;
  final bool visible;
  final VoidCallback onSetFamily;
  final VoidCallback onSetEstado;
  final VoidCallback onAddNote;
  final VoidCallback onAssign;
  final VoidCallback onCancel;

  const BulkActionBar({
    super.key,
    required this.count,
    required this.visible,
    required this.onSetFamily,
    required this.onSetEstado,
    required this.onAddNote,
    required this.onAssign,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 180),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: ct.surface,
            border: Border(
              top: BorderSide(
                  color: CobaltColors.cobalt.withValues(alpha: 0.35), width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: CobaltColors.cobalt.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: CobaltColors.cobalt.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: CobaltColors.cobalt.withValues(alpha: 0.30)),
                ),
                child: Text(
                  '$count seleccionada${count == 1 ? '' : 's'}',
                  style: const TextStyle(
                      color: CobaltColors.cobaltLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 16),
              _ActionBtn(label: 'Familia', icon: Icons.inventory_2_outlined, onTap: onSetFamily),
              const SizedBox(width: 8),
              _ActionBtn(label: 'Estado', icon: Icons.swap_horiz_rounded, onTap: onSetEstado),
              const SizedBox(width: 8),
              _ActionBtn(label: 'Nota', icon: Icons.note_add_outlined, onTap: onAddNote),
              const SizedBox(width: 8),
              _ActionBtn(label: 'Asignar', icon: Icons.person_add_outlined, onTap: onAssign),
              const Spacer(),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onCancel,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: ct.border),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Cancelar',
                        style: TextStyle(
                            color: ct.textSecondary, fontSize: 12)),
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

class _ActionBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.icon, required this.onTap});

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _hovered
                ? CobaltColors.cobalt.withValues(alpha: 0.20)
                : CobaltColors.cobalt.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color: CobaltColors.cobalt.withValues(alpha: 0.30)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 13, color: CobaltColors.cobaltLight),
              const SizedBox(width: 5),
              Text(widget.label,
                  style: const TextStyle(
                      color: CobaltColors.cobaltLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
