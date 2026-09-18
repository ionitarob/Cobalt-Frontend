// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/cobalt_theme.dart';
import '../../../../core/colors.dart';
import '../../../../services/orderops/orders_service.dart';
import '../order_detail_controller.dart';

class SerialChangePanel extends StatefulWidget {
  final OrderDetailController controller;
  const SerialChangePanel({super.key, required this.controller});

  @override
  State<SerialChangePanel> createState() => _SerialChangePanelState();
}

class _SerialMappingEntry {
  final String oldSerial;
  final String newSerial;
  final String operatorName;
  final DateTime date;

  const _SerialMappingEntry({
    required this.oldSerial,
    required this.newSerial,
    required this.operatorName,
    required this.date,
  });
}

class _SerialChangePanelState extends State<SerialChangePanel> {
  static const List<String> _kLabelTypes = [
    'Estándar',
    'Vodafone',
    'Relabeling S/N',
    'Caja Master',
  ];

  final _boxCtrl = TextEditingController();
  final _oldSnCtrl = TextEditingController();
  final _newSnCtrl = TextEditingController();
  final _oldSnFocus = FocusNode();
  final _newSnFocus = FocusNode();

  List<Map<String, dynamic>> _operators = const [];
  Map<String, dynamic>? _selectedOperator;
  String _selectedLabelType = _kLabelTypes.first;

  bool _loadingOperators = false;
  bool _boxActive = false;
  DateTime? _boxStart;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  final List<_SerialMappingEntry> _mappings = [];
  String _orderNbr = '';

  @override
  void initState() {
    super.initState();
    _orderNbr = widget.controller.detail?.agentOrder.orderNbr ?? '';
    widget.controller.addListener(_onControllerUpdate);
    _loadOperators();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    _boxCtrl.dispose();
    _oldSnCtrl.dispose();
    _newSnCtrl.dispose();
    _oldSnFocus.dispose();
    _newSnFocus.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _onControllerUpdate() {
    final nbr = widget.controller.detail?.agentOrder.orderNbr ?? '';
    if (nbr != _orderNbr && mounted) {
      setState(() => _orderNbr = nbr);
    }
  }

  Future<void> _loadOperators() async {
    if (!mounted) return;
    setState(() => _loadingOperators = true);
    try {
      final list = await OrdersService.instance.getEmployees(limit: 100);
      if (mounted) {
        setState(() {
          _operators = list;
          if (list.isNotEmpty) _selectedOperator ??= list.first;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingOperators = false);
    }
  }

  void _startBox() {
    final id = _boxCtrl.text.trim();
    if (id.isEmpty) {
      _snack('Introduce el identificador de caja.');
      return;
    }
    setState(() {
      _boxActive = true;
      _boxStart = DateTime.now();
      _elapsed = Duration.zero;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _boxStart != null) {
        setState(() => _elapsed = DateTime.now().difference(_boxStart!));
      }
    });
    FocusScope.of(context).requestFocus(_oldSnFocus);
  }

  void _stopBox() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _boxActive = false;
      _boxStart = null;
      _elapsed = Duration.zero;
    });
  }

  void _mapSerial() {
    final oldSn = _oldSnCtrl.text.trim();
    final newSn = _newSnCtrl.text.trim();
    if (oldSn.isEmpty || newSn.isEmpty) {
      _snack('Completa ambos campos S/N.');
      return;
    }
    final opName = _selectedOperator?['display_name']?.toString() ??
        _selectedOperator?['name']?.toString() ??
        '—';
    setState(() {
      _mappings.add(_SerialMappingEntry(
        oldSerial: oldSn,
        newSerial: newSn,
        operatorName: opName,
        date: DateTime.now(),
      ));
      _oldSnCtrl.clear();
      _newSnCtrl.clear();
    });
    FocusScope.of(context).requestFocus(_oldSnFocus);
  }

  void _exportPrint() {
    final msg = _mappings.isEmpty
        ? 'Sin mapeos registrados para exportar.'
        : 'Impresión no disponible en esta versión. ${_mappings.length} mapeo(s) registrado(s).';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  String _fmtElapsed(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final dateFmt = DateFormat('dd/MM/yy HH:mm');

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduceMotion ? 1.0 : 0.0, end: 1.0),
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.scale(
          scale: reduceMotion ? 1.0 : 0.95 + 0.05 * v,
          alignment: Alignment.topCenter,
          child: child,
        ),
      ),
      child: Container(
        color: ct.background,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Header(ct: ct, orderNbr: _orderNbr),
            const SizedBox(height: 16),
            _ConfigCard(
              ct: ct,
              loadingOperators: _loadingOperators,
              operators: _operators,
              selectedOperator: _selectedOperator,
              labelTypes: _kLabelTypes,
              selectedLabelType: _selectedLabelType,
              onOperatorChanged: (v) => setState(() => _selectedOperator = v),
              onLabelTypeChanged: (v) {
                if (v != null) setState(() => _selectedLabelType = v);
              },
            ),
            const SizedBox(height: 16),
            _BoxSessionCard(
              ct: ct,
              boxCtrl: _boxCtrl,
              boxActive: _boxActive,
              elapsed: _elapsed,
              onStart: _startBox,
              onStop: _stopBox,
              fmtElapsed: _fmtElapsed,
            ),
            if (_boxActive) ...[
              const SizedBox(height: 16),
              _SerialMapCard(
                ct: ct,
                oldCtrl: _oldSnCtrl,
                newCtrl: _newSnCtrl,
                oldFocus: _oldSnFocus,
                newFocus: _newSnFocus,
                onMap: _mapSerial,
                onNewSubmitted: () => _mapSerial(),
              ),
            ],
            if (_mappings.isNotEmpty) ...[
              const SizedBox(height: 16),
              _MappingsTable(
                ct: ct,
                mappings: _mappings,
                dateFmt: dateFmt,
              ),
            ],
            const SizedBox(height: 24),
            _ExportButton(ct: ct, onTap: _exportPrint),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final CobaltPalette ct;
  final String orderNbr;
  const _Header({required this.ct, required this.orderNbr});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.sync_alt_rounded, size: 18, color: CobaltColors.cobaltLight),
        const SizedBox(width: 8),
        Text(
          'Cambio de Seriales',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: ct.textPrimary,
          ),
        ),
        const Spacer(),
        if (orderNbr.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: CobaltColors.cobalt.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: CobaltColors.cobalt.withValues(alpha: 0.4)),
            ),
            child: Text(
              orderNbr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CobaltColors.cobaltLight,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _ConfigCard extends StatelessWidget {
  final CobaltPalette ct;
  final bool loadingOperators;
  final List<Map<String, dynamic>> operators;
  final Map<String, dynamic>? selectedOperator;
  final List<String> labelTypes;
  final String selectedLabelType;
  final ValueChanged<Map<String, dynamic>?> onOperatorChanged;
  final ValueChanged<String?> onLabelTypeChanged;

  const _ConfigCard({
    required this.ct,
    required this.loadingOperators,
    required this.operators,
    required this.selectedOperator,
    required this.labelTypes,
    required this.selectedLabelType,
    required this.onOperatorChanged,
    required this.onLabelTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      ct: ct,
      title: 'Configuración',
      child: Column(
        children: [
          if (loadingOperators)
            _LoadingRow(ct: ct, label: 'Cargando operadores...')
          else
            _FieldRow(
              ct: ct,
              icon: Icons.person_outline_rounded,
              label: 'Operador',
              child: operators.isEmpty
                  ? Text('Sin operadores',
                      style: TextStyle(color: ct.textHint, fontSize: 14))
                  : DropdownButton<Map<String, dynamic>>(
                      value: selectedOperator,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      dropdownColor: ct.surfaceElevated,
                      style:
                          TextStyle(color: ct.textPrimary, fontSize: 14),
                      onChanged: onOperatorChanged,
                      items: operators.map((op) {
                        final name =
                            op['display_name']?.toString() ??
                                op['name']?.toString() ??
                                '—';
                        return DropdownMenuItem(
                          value: op,
                          child: Text(name),
                        );
                      }).toList(),
                    ),
            ),
          const SizedBox(height: 8),
          _FieldRow(
            ct: ct,
            icon: Icons.label_outline_rounded,
            label: 'Tipo etiqueta',
            child: DropdownButton<String>(
              value: selectedLabelType,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              dropdownColor: ct.surfaceElevated,
              style: TextStyle(color: ct.textPrimary, fontSize: 14),
              onChanged: onLabelTypeChanged,
              items: labelTypes
                  .map((t) =>
                      DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _BoxSessionCard extends StatelessWidget {
  final CobaltPalette ct;
  final TextEditingController boxCtrl;
  final bool boxActive;
  final Duration elapsed;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final String Function(Duration) fmtElapsed;

  const _BoxSessionCard({
    required this.ct,
    required this.boxCtrl,
    required this.boxActive,
    required this.elapsed,
    required this.onStart,
    required this.onStop,
    required this.fmtElapsed,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      ct: ct,
      title: 'Sesión de Caja',
      borderAccent: boxActive,
      trailing: boxActive
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CobaltColors.cobaltLight,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  fmtElapsed(elapsed),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: CobaltColors.cobaltLight,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            )
          : null,
      child: Row(
        children: [
          Expanded(
            child: _CoTextField(
              ct: ct,
              controller: boxCtrl,
              hint: 'Identificador de caja (ej. C-001)',
              icon: Icons.inventory_2_outlined,
              enabled: !boxActive,
              onSubmitted: (_) {
                if (!boxActive) onStart();
              },
            ),
          ),
          const SizedBox(width: 10),
          _CoButton(
            ct: ct,
            label: boxActive ? 'Detener' : 'Iniciar',
            icon: boxActive
                ? Icons.stop_circle_outlined
                : Icons.play_circle_outline_rounded,
            variant: boxActive ? _BtnVariant.danger : _BtnVariant.subtle,
            onTap: boxActive ? onStop : onStart,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _SerialMapCard extends StatelessWidget {
  final CobaltPalette ct;
  final TextEditingController oldCtrl;
  final TextEditingController newCtrl;
  final FocusNode oldFocus;
  final FocusNode newFocus;
  final VoidCallback onMap;
  final VoidCallback onNewSubmitted;

  const _SerialMapCard({
    required this.ct,
    required this.oldCtrl,
    required this.newCtrl,
    required this.oldFocus,
    required this.newFocus,
    required this.onMap,
    required this.onNewSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      ct: ct,
      title: 'Mapeo de Serial',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _CoTextField(
              ct: ct,
              controller: oldCtrl,
              focusNode: oldFocus,
              hint: 'S/N original',
              icon: Icons.qr_code_scanner_rounded,
              onSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(newFocus),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward_rounded,
                size: 15, color: ct.textHint),
          ),
          Expanded(
            child: _CoTextField(
              ct: ct,
              controller: newCtrl,
              focusNode: newFocus,
              hint: 'S/N nuevo',
              icon: Icons.label_rounded,
              onSubmitted: (_) => onNewSubmitted(),
            ),
          ),
          const SizedBox(width: 10),
          _CoButton(
            ct: ct,
            label: 'Mapear',
            icon: Icons.link_rounded,
            variant: _BtnVariant.primary,
            onTap: onMap,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _MappingsTable extends StatelessWidget {
  final CobaltPalette ct;
  final List<_SerialMappingEntry> mappings;
  final DateFormat dateFmt;

  const _MappingsTable({
    required this.ct,
    required this.mappings,
    required this.dateFmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ct.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ct.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Text(
                  'Mapeos registrados',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ct.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: CobaltColors.cobalt.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${mappings.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: CobaltColors.cobaltLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: ct.border),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                _TH(ct: ct, label: 'S/N ORIGINAL', flex: 3),
                _TH(ct: ct, label: 'S/N NUEVO', flex: 3),
                _TH(ct: ct, label: 'OPERADOR', flex: 2),
                _TH(ct: ct, label: 'FECHA', flex: 2),
              ],
            ),
          ),
          Divider(height: 1, color: ct.border),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: mappings.length,
            separatorBuilder: (_, _) => Divider(height: 1, color: ct.border),
            itemBuilder: (context, i) {
              final m = mappings[mappings.length - 1 - i];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                child: Row(
                  children: [
                    _TD(
                        ct: ct,
                        value: m.oldSerial,
                        flex: 3,
                        mono: true),
                    _TD(
                        ct: ct,
                        value: m.newSerial,
                        flex: 3,
                        mono: true,
                        accent: true),
                    _TD(ct: ct, value: m.operatorName, flex: 2),
                    _TD(
                        ct: ct,
                        value: dateFmt.format(m.date),
                        flex: 2),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ExportButton extends StatelessWidget {
  final CobaltPalette ct;
  final VoidCallback onTap;
  const _ExportButton({required this.ct, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _CoButton(
      ct: ct,
      label: 'Exportar / Imprimir',
      icon: Icons.print_outlined,
      variant: _BtnVariant.subtle,
      fullWidth: true,
      onTap: onTap,
    );
  }
}

// ---------------------------------------------------------------------------
// Shared layout helpers

class _SectionCard extends StatelessWidget {
  final CobaltPalette ct;
  final String title;
  final Widget child;
  final Widget? trailing;
  final bool borderAccent;

  const _SectionCard({
    required this.ct,
    required this.title,
    required this.child,
    this.trailing,
    this.borderAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ct.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderAccent
              ? CobaltColors.cobaltLight.withValues(alpha: 0.5)
              : ct.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: ct.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LoadingRow extends StatelessWidget {
  final CobaltPalette ct;
  final String label;
  const _LoadingRow({required this.ct, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 13,
          height: 13,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: CobaltColors.cobaltLight,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 13, color: ct.textHint)),
      ],
    );
  }
}

class _FieldRow extends StatelessWidget {
  final CobaltPalette ct;
  final IconData icon;
  final String label;
  final Widget child;

  const _FieldRow({
    required this.ct,
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: ct.textSecondary),
        const SizedBox(width: 8),
        SizedBox(
          width: 96,
          child: Text(label,
              style: TextStyle(fontSize: 13, color: ct.textSecondary)),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _TH extends StatelessWidget {
  final CobaltPalette ct;
  final String label;
  final int flex;
  const _TH({required this.ct, required this.label, this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: ct.textHint,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _TD extends StatelessWidget {
  final CobaltPalette ct;
  final String value;
  final int flex;
  final bool mono;
  final bool accent;

  const _TD({
    required this.ct,
    required this.value,
    this.flex = 1,
    this.mono = false,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        value,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: mono ? FontWeight.w500 : FontWeight.w400,
          color: accent ? CobaltColors.cobaltLight : ct.textPrimary,
          fontFeatures: mono ? const [FontFeature.tabularFigures()] : null,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Input field

class _CoTextField extends StatelessWidget {
  final CobaltPalette ct;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final IconData icon;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;

  const _CoTextField({
    required this.ct,
    required this.controller,
    required this.hint,
    required this.icon,
    this.focusNode,
    this.enabled = true,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      textInputAction: TextInputAction.next,
      onSubmitted: onSubmitted,
      style: TextStyle(
        fontSize: 13,
        color: ct.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: ct.textHint, fontSize: 13),
        prefixIcon: Icon(icon, size: 16, color: ct.textSecondary),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: ct.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ct.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ct.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: CobaltColors.cobaltLight, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: ct.border.withValues(alpha: 0.4)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Button

enum _BtnVariant { primary, subtle, danger }

class _CoButton extends StatefulWidget {
  final CobaltPalette ct;
  final String label;
  final IconData icon;
  final _BtnVariant variant;
  final bool fullWidth;
  final VoidCallback onTap;

  const _CoButton({
    required this.ct,
    required this.label,
    required this.icon,
    required this.variant,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  State<_CoButton> createState() => _CoButtonState();
}

class _CoButtonState extends State<_CoButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final ct = widget.ct;

    final (bg, fg, border) = switch (widget.variant) {
      _BtnVariant.primary => (
          CobaltColors.cobalt,
          Colors.white,
          CobaltColors.cobalt,
        ),
      _BtnVariant.danger => (
          CobaltColors.cobalt.withValues(alpha: 0.12),
          CobaltColors.cobaltLight,
          CobaltColors.cobalt.withValues(alpha: 0.4),
        ),
      _BtnVariant.subtle => (
          ct.surfaceElevated,
          ct.textSecondary,
          ct.border,
        ),
    };

    Widget inner = Container(
      width: widget.fullWidth ? double.infinity : null,
      padding: EdgeInsets.symmetric(
        horizontal: widget.fullWidth ? 20 : 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize:
            widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, size: 15, color: fg),
          const SizedBox(width: 6),
          Text(
            widget.label,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );

    if (!reduceMotion) {
      inner = AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: inner,
      );
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: inner,
    );
  }
}
