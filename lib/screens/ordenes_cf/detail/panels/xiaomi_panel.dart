import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/cobalt_theme.dart';
import '../../../../core/colors.dart';
import '../../../../services/xiaomi_service.dart';
import '../order_detail_controller.dart';

class XiaomiPanel extends StatefulWidget {
  const XiaomiPanel({super.key, required this.controller});

  final OrderDetailController controller;

  @override
  State<XiaomiPanel> createState() => _XiaomiPanelState();
}

class _XiaomiPanelState extends State<XiaomiPanel>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _cesbCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _partCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();
  final _cartonesCtrl = TextEditingController();

  final _cesbFocus = FocusNode();
  final _skuFocus = FocusNode();
  final _partFocus = FocusNode();
  final _cantidadFocus = FocusNode();
  final _cartonesFocus = FocusNode();

  late final AnimationController _entranceCtrl;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  List<XiaomiRegistro> _registros = [];
  XiaomiCesbStatus? _cesbStatus;
  bool _checkingCesb = false;
  bool _submitting = false;
  bool _loadingHistory = false;
  String? _loadError;
  bool _formVisible = true;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    final curve = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _scale = Tween<double>(begin: 0.95, end: 1.0).animate(curve);

    _entranceCtrl.forward();
    _loadHistory();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _cesbCtrl.dispose();
    _skuCtrl.dispose();
    _partCtrl.dispose();
    _cantidadCtrl.dispose();
    _cartonesCtrl.dispose();
    _cesbFocus.dispose();
    _skuFocus.dispose();
    _partFocus.dispose();
    _cantidadFocus.dispose();
    _cartonesFocus.dispose();
    super.dispose();
  }

  int? get _idnbr => widget.controller.detail?.agentOrder.idnbr;
  String get _orderNbr =>
      widget.controller.detail?.agentOrder.orderNbr ?? '—';

  Future<void> _loadHistory() async {
    final id = _idnbr;
    if (id == null) return;
    setState(() {
      _loadingHistory = true;
      _loadError = null;
    });
    try {
      final list = await XiaomiService.instance.getXiaomiRegistros(id);
      if (mounted) setState(() => _registros = list);
    } catch (e) {
      if (mounted) setState(() => _loadError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _checkCesb(String cesb) async {
    if (cesb.isEmpty) {
      setState(() => _cesbStatus = null);
      return;
    }
    setState(() => _checkingCesb = true);
    try {
      final status = await XiaomiService.instance.getXiaomiCesbStatus(cesb);
      if (mounted) setState(() => _cesbStatus = status);
    } catch (_) {
      if (mounted) setState(() => _cesbStatus = null);
    } finally {
      if (mounted) setState(() => _checkingCesb = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final cesb = _cesbCtrl.text.trim();
    final sku = _skuCtrl.text.trim();

    final warnings = <String>[];
    if (!cesb.toUpperCase().startsWith('CESB')) {
      warnings.add('El CESB no comienza con "CESB".');
    }
    if (!RegExp(r'^\d{5}$').hasMatch(sku)) {
      warnings.add('El SKU no parece tener 5 dígitos.');
    }

    if (warnings.isNotEmpty) {
      final proceed = await _showWarningDialog(warnings);
      if (proceed != true) return;
    }

    setState(() => _submitting = true);
    try {
      final now = DateTime.now();
      final payload = {
        'idnbr': _idnbr,
        'cesb': cesb,
        'sku': sku,
        'partn': _partCtrl.text.trim(),
        'qty': int.tryParse(_cantidadCtrl.text.trim()) ?? 0,
        'cartons': int.tryParse(_cartonesCtrl.text.trim()),
        'fecha_hora_registro': now.toIso8601String(),
      };

      final reg = await XiaomiService.instance.registerXiaomiUnit(payload);
      if (!mounted) return;

      setState(() {
        _registros.insert(0, reg);
        _cesbCtrl.clear();
        _skuCtrl.clear();
        _partCtrl.clear();
        _cantidadCtrl.clear();
        _cartonesCtrl.clear();
        _cesbStatus = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unidad registrada correctamente'),
          backgroundColor: const Color(0xFF1DE9B6),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _cesbFocus.requestFocus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar: $e'),
          backgroundColor: const Color(0xFFFF5252),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<bool?> _showWarningDialog(List<String> warnings) {
    final ct = context.ct;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ct.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Advertencia de formato',
          style: TextStyle(color: ct.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Se detectaron inconsistencias:',
              style: TextStyle(color: ct.textSecondary),
            ),
            const SizedBox(height: 8),
            ...warnings.map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '· $w',
                  style: const TextStyle(color: Color(0xFFFFB020)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '¿Continuar de todos modos?',
              style: TextStyle(color: ct.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Corregir', style: TextStyle(color: ct.textHint)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: CobaltColors.cobaltLight,
            ),
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final formWidget = _buildForm(ct);
    final historyWidget = _buildHistory(ct);

    Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(ct),
        const SizedBox(height: 16),
        _buildToggleRow(ct),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) {
            if (reduceMotion) return FadeTransition(opacity: anim, child: child);
            return FadeTransition(
              opacity: anim,
              child: ScaleTransition(scale: Tween(begin: 0.97, end: 1.0).animate(anim), child: child),
            );
          },
          child: _formVisible
              ? KeyedSubtree(key: const ValueKey('form'), child: formWidget)
              : KeyedSubtree(key: const ValueKey('hist'), child: historyWidget),
        ),
      ],
    );

    if (reduceMotion) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: body,
      );
    }

    return AnimatedBuilder(
      animation: _entranceCtrl,
      builder: (_, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.scale(scale: _scale.value, child: child),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: body,
      ),
    );
  }

  Widget _buildHeader(CobaltPalette ct) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: CobaltColors.cobalt.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CobaltColors.cobalt.withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.devices_rounded, color: CobaltColors.cobaltLight, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registro Xiaomi',
              style: TextStyle(
                color: ct.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Orden $_orderNbr',
              style: TextStyle(color: ct.textHint, fontSize: 12),
            ),
          ],
        ),
        const Spacer(),
        _PressableIcon(
          icon: Icons.refresh_rounded,
          color: ct.textHint,
          tooltip: 'Actualizar historial',
          onTap: _loadHistory,
        ),
      ],
    );
  }

  Widget _buildToggleRow(CobaltPalette ct) {
    return Container(
      decoration: BoxDecoration(
        color: ct.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ct.border),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _SegmentButton(
            label: 'Nueva entrada',
            selected: _formVisible,
            ct: ct,
            onTap: () => setState(() => _formVisible = true),
          ),
          _SegmentButton(
            label: 'Historial (${_registros.length})',
            selected: !_formVisible,
            ct: ct,
            onTap: () => setState(() => _formVisible = false),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(CobaltPalette ct) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ct.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ct.border),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCesbField(ct),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildField(
                    ct: ct,
                    controller: _skuCtrl,
                    label: 'SKU',
                    icon: Icons.tag_rounded,
                    focus: _skuFocus,
                    nextFocus: _partFocus,
                    keyboard: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => (v?.isEmpty ?? true) ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: _buildField(
                    ct: ct,
                    controller: _partCtrl,
                    label: 'Part Number',
                    icon: Icons.memory_rounded,
                    focus: _partFocus,
                    nextFocus: _cantidadFocus,
                    validator: (v) => (v?.isEmpty ?? true) ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    ct: ct,
                    controller: _cantidadCtrl,
                    label: 'Cantidad',
                    icon: Icons.numbers_rounded,
                    focus: _cantidadFocus,
                    nextFocus: _cartonesFocus,
                    keyboard: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => (v?.isEmpty ?? true) ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    ct: ct,
                    controller: _cartonesCtrl,
                    label: 'Cartones',
                    icon: Icons.inventory_2_rounded,
                    focus: _cartonesFocus,
                    keyboard: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    isLast: true,
                    onSubmit: _submit,
                    validator: (v) => (v?.isEmpty ?? true) ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSubmitButton(ct),
          ],
        ),
      ),
    );
  }

  Widget _buildCesbField(CobaltPalette ct) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _cesbCtrl,
          focusNode: _cesbFocus,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.characters,
          onFieldSubmitted: (_) => _skuFocus.requestFocus(),
          onChanged: (v) {
            if (v.length >= 4) {
              _checkCesb(v.trim());
            } else {
              setState(() => _cesbStatus = null);
            }
          },
          validator: (v) => (v?.isEmpty ?? true) ? 'Requerido' : null,
          style: TextStyle(color: ct.textPrimary),
          decoration: _inputDecoration(
            ct: ct,
            label: 'CESB',
            icon: Icons.qr_code_rounded,
            suffix: _checkingCesb
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : _cesbStatus != null
                    ? Icon(
                        _cesbStatus!.valid
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        size: 18,
                        color: _cesbStatus!.valid
                            ? const Color(0xFF1DE9B6)
                            : const Color(0xFFFF5252),
                      )
                    : null,
          ),
        ),
        if (_cesbStatus != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              _cesbStatus!.valid
                  ? 'CESB verificado'
                  : _cesbStatus!.statusLabel ?? 'CESB no válido',
              style: TextStyle(
                fontSize: 11,
                color: _cesbStatus!.valid
                    ? const Color(0xFF1DE9B6)
                    : const Color(0xFFFF5252),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildField({
    required CobaltPalette ct,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required FocusNode focus,
    FocusNode? nextFocus,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool isLast = false,
    VoidCallback? onSubmit,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focus,
      keyboardType: keyboard,
      inputFormatters: inputFormatters,
      textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: (_) {
        if (nextFocus != null) {
          nextFocus.requestFocus();
        } else if (isLast && onSubmit != null) {
          onSubmit();
        }
      },
      validator: validator,
      style: TextStyle(color: ct.textPrimary),
      decoration: _inputDecoration(ct: ct, label: label, icon: icon),
    );
  }

  InputDecoration _inputDecoration({
    required CobaltPalette ct,
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: ct.textHint, fontSize: 13),
      prefixIcon: Icon(icon, size: 18, color: ct.textHint),
      suffixIcon: suffix != null ? Padding(padding: const EdgeInsets.only(right: 12), child: suffix) : null,
      suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      filled: true,
      fillColor: ct.surfaceElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ct.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CobaltColors.cobaltLight, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF5252)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF5252), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildSubmitButton(CobaltPalette ct) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: _submitting
          ? Container(
              decoration: BoxDecoration(
                color: CobaltColors.cobalt.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          : _PressableButton(
              onTap: _submit,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [CobaltColors.cobalt, CobaltColors.cobaltLight],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: CobaltColors.cobalt.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Registrar unidad',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHistory(CobaltPalette ct) {
    if (_loadingHistory) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: CircularProgressIndicator(
            color: CobaltColors.cobaltLight,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_loadError != null) {
      return _ErrorState(
        ct: ct,
        message: _loadError!,
        onRetry: _loadHistory,
      );
    }

    if (_registros.isEmpty) {
      return _EmptyState(ct: ct);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHistoryTable(ct),
      ],
    );
  }

  Widget _buildHistoryTable(CobaltPalette ct) {
    return Container(
      decoration: BoxDecoration(
        color: ct.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ct.border),
      ),
      child: Column(
        children: [
          _buildTableHeader(ct),
          const Divider(height: 1, thickness: 1),
          ..._registros.asMap().entries.map(
            (e) => _buildTableRow(ct, e.value, e.key.isOdd),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(CobaltPalette ct) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 3, child: _headerCell(ct, 'CESB')),
          Expanded(flex: 2, child: _headerCell(ct, 'SKU')),
          Expanded(flex: 2, child: _headerCell(ct, 'P/N')),
          SizedBox(width: 50, child: _headerCell(ct, 'Qty', align: TextAlign.center)),
          SizedBox(width: 52, child: _headerCell(ct, 'Box', align: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _headerCell(CobaltPalette ct, String label, {TextAlign align = TextAlign.left}) {
    return Text(
      label,
      textAlign: align,
      style: TextStyle(
        color: ct.textHint,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTableRow(CobaltPalette ct, XiaomiRegistro reg, bool shaded) {
    return Container(
      color: shaded ? ct.surfaceElevated.withValues(alpha: 0.5) : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              reg.cesb,
              style: TextStyle(
                color: ct.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              reg.sku,
              style: TextStyle(color: ct.textSecondary, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              reg.partNumber ?? '—',
              style: TextStyle(color: ct.textHint, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 50,
            child: _CountPill(value: reg.quantity, ct: ct),
          ),
          SizedBox(
            width: 52,
            child: Text(
              reg.cartons?.toString() ?? '—',
              textAlign: TextAlign.center,
              style: TextStyle(color: ct.textHint, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.ct,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final CobaltPalette ct;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? CobaltColors.cobalt : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : ct.textHint,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _PressableButton extends StatefulWidget {
  const _PressableButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _PressableIcon extends StatefulWidget {
  const _PressableIcon({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_PressableIcon> createState() => _PressableIconState();
}

class _PressableIconState extends State<_PressableIcon> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: Tooltip(
        message: widget.tooltip,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: Icon(widget.icon, size: 20, color: widget.color),
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.value, required this.ct});

  final int value;
  final CobaltPalette ct;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: CobaltColors.cobalt.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CobaltColors.cobalt.withValues(alpha: 0.3)),
        ),
        child: Text(
          '$value',
          style: const TextStyle(
            color: CobaltColors.cobaltLight,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.ct});

  final CobaltPalette ct;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.devices_rounded, size: 40, color: ct.textHint),
          const SizedBox(height: 12),
          Text(
            'Sin registros Xiaomi',
            style: TextStyle(color: ct.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Añade la primera unidad desde la pestaña Nueva entrada',
            textAlign: TextAlign.center,
            style: TextStyle(color: ct.textHint, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.ct, required this.message, required this.onRetry});

  final CobaltPalette ct;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 36, color: Color(0xFFFF5252)),
          const SizedBox(height: 10),
          Text(
            'Error al cargar historial',
            style: TextStyle(color: ct.textSecondary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: ct.textHint, fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Reintentar'),
            style: TextButton.styleFrom(
              foregroundColor: CobaltColors.cobaltLight,
            ),
          ),
        ],
      ),
    );
  }
}
