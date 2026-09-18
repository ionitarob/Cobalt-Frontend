import 'package:flutter/material.dart';

import '../../../core/cobalt_theme.dart';
import '../../../core/colors.dart';

class ToolbarRow extends StatelessWidget {
  final bool canSync;
  final bool syncing;
  final bool exporting;
  final bool selectionMode;
  final int selectedCount;
  final VoidCallback onSync;
  final VoidCallback onExport;
  final VoidCallback onImport;
  final VoidCallback onToggleSelection;
  final VoidCallback onRefresh;

  const ToolbarRow({
    super.key,
    required this.canSync,
    required this.syncing,
    required this.exporting,
    required this.selectionMode,
    required this.selectedCount,
    required this.onSync,
    required this.onExport,
    required this.onImport,
    required this.onToggleSelection,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (syncing)
          SizedBox(
            width: 120,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  color: CobaltColors.cobaltLight,
                  backgroundColor: ct.border,
                ),
                const SizedBox(height: 2),
                Text('Sincronizando…',
                    style: TextStyle(
                        color: ct.textHint,
                        fontSize: 10)),
              ],
            ),
          )
        else if (canSync)
          _IconBtn(
            icon: Icons.sync_alt_rounded,
            tooltip: 'Sincronizar',
            onTap: onSync,
          ),
        if (canSync) ...[
          const SizedBox(width: 2),
          _IconBtn(
            icon: Icons.cloud_upload_rounded,
            tooltip: 'Importar CSV',
            color: const Color(0xFFFFAA00),
            onTap: onImport,
          ),
        ],
        const SizedBox(width: 2),
        exporting
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: CobaltColors.cobaltLight),
              )
            : _IconBtn(
                icon: Icons.download_rounded,
                tooltip: 'Exportar Excel',
                color: const Color(0xFF2EC672),
                onTap: onExport,
              ),
        const SizedBox(width: 2),
        _IconBtn(
          icon: selectionMode ? Icons.close : Icons.checklist_rounded,
          tooltip: selectionMode
              ? 'Cancelar selección ($selectedCount)'
              : 'Modo selección',
          color: selectionMode ? const Color(0xFFFFAA00) : null,
          onTap: onToggleSelection,
        ),
        const SizedBox(width: 2),
        _IconBtn(icon: Icons.refresh_rounded, tooltip: 'Actualizar', onTap: onRefresh),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _IconBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color? color;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.tooltip,
    this.color,
    required this.onTap,
  });

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _hovered
                  ? CobaltColors.cobalt.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: widget.color ??
                  (_hovered
                      ? CobaltColors.cobaltLight
                      : ct.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
