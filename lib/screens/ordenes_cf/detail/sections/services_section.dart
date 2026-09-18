import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/cobalt_theme.dart';
import '../../../../core/colors.dart';
import '../../../../models/orderops/order_detail.dart';
import '../../../../services/orderops/order_detail_service.dart';
import '../order_detail_controller.dart';

class ServicesSection extends StatelessWidget {
  const ServicesSection({super.key, required this.controller});

  final OrderDetailController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final ct = context.ct;
        final services =
            controller.detail?.services ?? const <AgentOrderService>[];
        final alerts = controller.alerts;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TitleRow(
              controller: controller,
              count: services.length,
              ct: ct,
            ),
            const SizedBox(height: 8),
            if (services.isEmpty)
              _EmptyState(ct: ct)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: services.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  thickness: 1,
                  color: ct.border.withValues(alpha: 0.35),
                ),
                itemBuilder: (context, i) {
                  final svc = services[i];
                  final alert = svc.skuConfig != null
                      ? alerts
                          .where((a) => a.sku == svc.skuConfig)
                          .firstOrNull
                      : null;
                  return _ServiceRowEntrance(
                    index: i,
                    child: _ServiceRow(
                      service: svc,
                      alert: alert,
                      controller: controller,
                      ct: ct,
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------

class _TitleRow extends StatelessWidget {
  const _TitleRow({
    required this.controller,
    required this.count,
    required this.ct,
  });

  final OrderDetailController controller;
  final int count;
  final CobaltPalette ct;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'SERVICIOS',
          style: TextStyle(
            color: ct.textHint,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: ct.border.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: ct.textHint,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        if (controller.isPrivileged)
          _AddServiceButton(controller: controller, ct: ct),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _AddServiceButton extends StatefulWidget {
  const _AddServiceButton({required this.controller, required this.ct});

  final OrderDetailController controller;
  final CobaltPalette ct;

  @override
  State<_AddServiceButton> createState() => _AddServiceButtonState();
}

class _AddServiceButtonState extends State<_AddServiceButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.of(context).disableAnimations;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _showCatalogDialog(context);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: (!reducedMotion && _pressed) ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: CobaltColors.cobalt.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: CobaltColors.cobaltLight.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 12, color: CobaltColors.cobaltLight),
              const SizedBox(width: 3),
              Text(
                'Agregar',
                style: TextStyle(
                  color: CobaltColors.cobaltLight,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCatalogDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => _CatalogSearchDialog(
        controller: widget.controller,
        ct: widget.ct,
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _CatalogSearchDialog extends StatefulWidget {
  const _CatalogSearchDialog({
    required this.controller,
    required this.ct,
  });

  final OrderDetailController controller;
  final CobaltPalette ct;

  @override
  State<_CatalogSearchDialog> createState() =>
      _CatalogSearchDialogState();
}

class _CatalogSearchDialogState extends State<_CatalogSearchDialog> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 320), () async {
      if (!mounted) return;
      setState(() => _loading = true);
      try {
        final res = await OrderDetailService.instance
            .searchCatalogServices(q.trim());
        if (mounted) setState(() => _results = res);
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ct = widget.ct;
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: ct.border),
    );

    return Dialog(
      backgroundColor: ct.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: 420, maxHeight: 520),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Text(
                'Buscar servicio',
                style: TextStyle(
                  color: ct.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: _onQueryChanged,
                style: TextStyle(color: ct.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'SKU o descripción…',
                  hintStyle:
                      TextStyle(color: ct.textHint, fontSize: 13),
                  prefixIcon: Icon(Icons.search,
                      color: ct.textHint, size: 18),
                  filled: true,
                  fillColor: ct.surfaceElevated,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 12),
                  border: inputBorder,
                  enabledBorder: inputBorder,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: CobaltColors.cobaltLight, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : _results.isEmpty
                      ? Center(
                          child: Text(
                            _searchCtrl.text.isEmpty
                                ? 'Escriba para buscar'
                                : 'Sin resultados',
                            style: TextStyle(
                                color: ct.textHint, fontSize: 13),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          itemCount: _results.length,
                          itemBuilder: (context, i) {
                            final item = _results[i];
                            return InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () async {
                                Navigator.of(context).pop();
                                await widget.controller
                                    .addManualService(item);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 8),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['sku_config']?.toString() ??
                                          '',
                                      style: TextStyle(
                                        color: CobaltColors.cobaltLight,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures()
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item['description']?.toString() ??
                                          '',
                                      style: TextStyle(
                                          color: ct.textSecondary,
                                          fontSize: 12),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancelar',
                      style: TextStyle(color: ct.textSecondary)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ServiceRowEntrance extends StatelessWidget {
  const _ServiceRowEntrance({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 160 + index * 30),
      curve: Curves.easeOut,
      builder: (context, t, c) => Opacity(
        opacity: t,
        child: Transform.scale(
          scale: 0.95 + 0.05 * t,
          alignment: Alignment.centerLeft,
          child: c,
        ),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------

/// Returns the price-state colour for a service that has catalog data.
/// Mirrors Granite's _getPriceColor logic exactly.
/// Returns null when theoreticalPvd == 0 (no catalog match → no colour).
Color? _priceStateColor(AgentOrderService svc) {
  if (svc.theoreticalPvd <= 0) return null;
  if (svc.orderUnitPrice < svc.coste - 0.05) return const Color(0xFFFF5252); // red
  if ((svc.orderUnitPrice - svc.theoreticalPvd).abs() <= 0.05) return const Color(0xFF69F0AE); // green
  return const Color(0xFFFFB020); // yellow
}

// ---------------------------------------------------------------------------

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.service,
    required this.alert,
    required this.controller,
    required this.ct,
  });

  final AgentOrderService service;
  final AgentServiceAlert? alert;
  final OrderDetailController controller;
  final CobaltPalette ct;

  @override
  Widget build(BuildContext context) {
    final hasRightCol = controller.canViewFinancials ||
        (service.isManual && controller.isPrivileged);

    // Colour indicator: alert status overrides price-state colour.
    Color? stateColor = _priceStateColor(service);
    if (alert != null) {
      if (alert!.status == 'validated') {
        stateColor = const Color(0xFF69F0AE);
      } else if (alert!.status == 'reported') {
        stateColor = const Color(0xFF448AFF);
      } else if (alert!.colorState != 'green') {
        stateColor = _alertColor(alert!.colorState);
      }
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left colour bar — only visible when this line has catalog data.
          Container(
            width: 3,
            decoration: BoxDecoration(
              color: stateColor ?? Colors.transparent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2),
                bottomLeft: Radius.circular(2),
              ),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SKU
                  SizedBox(
                    width: 130,
                    child: Text(
                      service.skuConfig ?? '—',
                      style: TextStyle(
                        color: stateColor ?? CobaltColors.cobaltLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        height: 1.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Description + inline badges
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.description,
                          style: TextStyle(
                              color: ct.textPrimary,
                              fontSize: 12,
                              height: 1.35),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (service.isManual || alert != null) ...[
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              if (service.isManual) _ManualBadge(ct: ct),
                              if (service.isManual && alert != null)
                                const SizedBox(width: 4),
                              if (alert != null)
                                _AlertBadge(
                                  alert: alert!,
                                  controller: controller,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Right column: financials + delete
                  if (hasRightCol) ...[
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (controller.canViewFinancials)
                          _FinancialInfo(service: service, ct: ct),
                        if (service.isManual && controller.isPrivileged) ...[
                          if (controller.canViewFinancials)
                            const SizedBox(height: 2),
                          _DeleteButton(
                            ct: ct,
                            onConfirm: () => controller
                                .removeManualService(service.manualId!),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ManualBadge extends StatelessWidget {
  const _ManualBadge({required this.ct});

  final CobaltPalette ct;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: ct.border,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        'MANUAL',
        style: TextStyle(
          color: ct.textHint,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

Color _alertColor(String colorState) {
  switch (colorState) {
    case 'red':
      return const Color(0xFFFF5252);
    case 'yellow':
      return const Color(0xFFFFB020);
    case 'green':
      return const Color(0xFF69F0AE);
    default:
      return const Color(0xFF8B93A0);
  }
}

String _alertLabel(String colorState) {
  switch (colorState) {
    case 'red':
      return 'ALERTA';
    case 'yellow':
      return 'AVISO';
    case 'green':
      return 'OK';
    default:
      return colorState.toUpperCase();
  }
}

class _AlertBadge extends StatefulWidget {
  const _AlertBadge({required this.alert, required this.controller});

  final AgentServiceAlert alert;
  final OrderDetailController controller;

  @override
  State<_AlertBadge> createState() => _AlertBadgeState();
}

class _AlertBadgeState extends State<_AlertBadge> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = _alertColor(widget.alert.colorState);
    final label = _alertLabel(widget.alert.colorState);
    final reducedMotion = MediaQuery.of(context).disableAnimations;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _showAlertSheet(context);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: (!reducedMotion && _pressed) ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAlertSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AlertEditSheet(
        alert: widget.alert,
        controller: widget.controller,
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _AlertEditSheet extends StatefulWidget {
  const _AlertEditSheet({
    required this.alert,
    required this.controller,
  });

  final AgentServiceAlert alert;
  final OrderDetailController controller;

  @override
  State<_AlertEditSheet> createState() => _AlertEditSheetState();
}

class _AlertEditSheetState extends State<_AlertEditSheet> {
  static const _statusOptions = ['pending', 'validated', 'reported'];

  late String _status;
  late final TextEditingController _notesCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _status = _statusOptions.contains(widget.alert.status)
        ? widget.alert.status
        : 'pending';
    _notesCtrl = TextEditingController(text: widget.alert.notes ?? '');
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  static String _statusLabel(String s) {
    switch (s) {
      case 'pending':
        return 'Pendiente';
      case 'validated':
        return 'Validado';
      case 'reported':
        return 'Reportado';
      default:
        return s;
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.controller.updateServiceAlert(
        widget.alert.sku,
        _status,
        _notesCtrl.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: ct.border),
    );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          decoration: BoxDecoration(
            color: ct.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ct.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alerta de servicio',
                style: TextStyle(
                  color: ct.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.alert.sku,
                style: TextStyle(
                  color: CobaltColors.cobaltLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 16),
              _SheetLabel(label: 'Estado', ct: ct),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _status,
                dropdownColor: ct.surfaceElevated,
                style: TextStyle(color: ct.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: ct.surfaceElevated,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  border: inputBorder,
                  enabledBorder: inputBorder,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: CobaltColors.cobaltLight, width: 1.5),
                  ),
                ),
                items: _statusOptions
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(_statusLabel(s)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _status = v);
                },
              ),
              const SizedBox(height: 14),
              _SheetLabel(label: 'Notas', ct: ct),
              const SizedBox(height: 6),
              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                style: TextStyle(color: ct.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Observaciones adicionales…',
                  hintStyle:
                      TextStyle(color: ct.textHint, fontSize: 12),
                  filled: true,
                  fillColor: ct.surfaceElevated,
                  contentPadding: const EdgeInsets.all(12),
                  border: inputBorder,
                  enabledBorder: inputBorder,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: CobaltColors.cobaltLight, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(color: ct.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CobaltColors.cobalt,
                      foregroundColor: ct.textPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Guardar',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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

class _SheetLabel extends StatelessWidget {
  const _SheetLabel({required this.label, required this.ct});

  final String label;
  final CobaltPalette ct;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: ct.textHint,
        fontSize: 9.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ---------------------------------------------------------------------------

String _fmtCurrency(double v) => '${v.toStringAsFixed(2)} €';

class _FinancialInfo extends StatelessWidget {
  const _FinancialInfo({required this.service, required this.ct});

  final AgentOrderService service;
  final CobaltPalette ct;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _FinLine(label: 'Coste', value: _fmtCurrency(service.coste), ct: ct),
        _FinLine(
            label: 'PVD Teórico',
            value: _fmtCurrency(service.theoreticalPvd),
            ct: ct),
        _FinLine(
            label: 'PVU',
            value: _fmtCurrency(service.orderUnitPrice),
            ct: ct),
      ],
    );
  }
}

class _FinLine extends StatelessWidget {
  const _FinLine({
    required this.label,
    required this.value,
    required this.ct,
  });

  final String label;
  final String value;
  final CobaltPalette ct;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: TextStyle(color: ct.textHint, fontSize: 9),
        ),
        Text(
          value,
          style: TextStyle(
            color: ct.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.ct, required this.onConfirm});

  final CobaltPalette ct;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _confirm(context),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(Icons.close, size: 14, color: ct.textHint),
      ),
    );
  }

  Future<void> _confirm(BuildContext context) {
    final ct = context.ct;
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ct.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Eliminar servicio',
          style: TextStyle(
              color: ct.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600),
        ),
        content: Text(
          '¿Confirmar la eliminación de este servicio manual?',
          style: TextStyle(color: ct.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancelar',
                style: TextStyle(color: ct.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Color(0xFFFF5252)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.ct});

  final CobaltPalette ct;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: ct.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ct.border.withValues(alpha: 0.4)),
      ),
      child: Text(
        'Sin servicios registrados',
        textAlign: TextAlign.center,
        style: TextStyle(color: ct.textHint, fontSize: 12),
      ),
    );
  }
}
