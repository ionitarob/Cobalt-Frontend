import 'package:flutter/material.dart';

import '../../../../core/cobalt_theme.dart';
import '../../../../core/colors.dart';
import '../../../../services/server_registro_service.dart';
import '../order_detail_controller.dart';

class ServidorPanel extends StatefulWidget {
  final OrderDetailController controller;

  const ServidorPanel({super.key, required this.controller});

  @override
  State<ServidorPanel> createState() => _ServidorPanelState();
}

class _ServidorPanelState extends State<ServidorPanel>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _hostnameCtrl = TextEditingController();
  final _ipCtrl = TextEditingController();
  final _macCtrl = TextEditingController();
  final _ramCtrl = TextEditingController();
  final _cpuCtrl = TextEditingController();
  final _hddCtrl = TextEditingController();

  final _hostnameFocus = FocusNode();
  final _ipFocus = FocusNode();
  final _macFocus = FocusNode();
  final _ramFocus = FocusNode();
  final _cpuFocus = FocusNode();
  final _hddFocus = FocusNode();

  List<Map<String, dynamic>> _servidores = [];
  bool _loadingList = false;
  bool _saving = false;
  String? _loadError;
  bool _formVisible = false;

  late final AnimationController _entranceCtrl;
  late final Animation<double> _entranceOpacity;
  late final Animation<double> _entranceScale;

  int? get _orderId =>
      widget.controller.detail?.agentOrder.idnbr;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _entranceOpacity = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOut,
    );
    _entranceScale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut),
    );
    _loadServidores();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _hostnameCtrl.dispose();
    _ipCtrl.dispose();
    _macCtrl.dispose();
    _ramCtrl.dispose();
    _cpuCtrl.dispose();
    _hddCtrl.dispose();
    _hostnameFocus.dispose();
    _ipFocus.dispose();
    _macFocus.dispose();
    _ramFocus.dispose();
    _cpuFocus.dispose();
    _hddFocus.dispose();
    super.dispose();
  }

  Future<void> _loadServidores() async {
    final id = _orderId;
    if (id == null) return;
    setState(() {
      _loadingList = true;
      _loadError = null;
    });
    try {
      final list =
          await ServerRegistroService.instance.getServidoresByOrder(id);
      if (!mounted) return;
      setState(() => _servidores = list);
      _entranceCtrl.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingList = false);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final id = _orderId;
    if (id == null) return;

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await ServerRegistroService.instance.registerServidor({
        'idnbr': id,
        'hostname': _hostnameCtrl.text.trim(),
        'ip': _ipCtrl.text.trim(),
        'mac': _macCtrl.text.trim(),
        'ram': _ramCtrl.text.trim(),
        'cpu': _cpuCtrl.text.trim(),
        'hdd': _hddCtrl.text.trim(),
      });
      if (!mounted) return;
      _clearForm();
      setState(() => _formVisible = false);
      await _loadServidores();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar servidor: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final ct = ctx.ct;
        return AlertDialog(
          backgroundColor: ct.surfaceElevated,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Eliminar servidor',
              style: TextStyle(color: ct.textPrimary)),
          content: Text(
            'Esta accion no se puede deshacer.',
            style: TextStyle(color: ct.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancelar',
                  style: TextStyle(color: ct.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Eliminar',
                  style: TextStyle(color: Color(0xFFFF5252))),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    try {
      await ServerRegistroService.instance.deleteServidor(id);
      await _loadServidores();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e')),
      );
    }
  }

  void _clearForm() {
    _hostnameCtrl.clear();
    _ipCtrl.clear();
    _macCtrl.clear();
    _ramCtrl.clear();
    _cpuCtrl.clear();
    _hddCtrl.clear();
    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    final disableAnimations =
        MediaQuery.of(context).disableAnimations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PanelHeader(
          ct: ct,
          count: _servidores.length,
          formVisible: _formVisible,
          onToggleForm: () => setState(() {
            _formVisible = !_formVisible;
            if (!_formVisible) _clearForm();
          }),
        ),
        if (_formVisible) ...[
          const SizedBox(height: 12),
          _RegistroForm(
            formKey: _formKey,
            hostnameCtrl: _hostnameCtrl,
            ipCtrl: _ipCtrl,
            macCtrl: _macCtrl,
            ramCtrl: _ramCtrl,
            cpuCtrl: _cpuCtrl,
            hddCtrl: _hddCtrl,
            hostnameFocus: _hostnameFocus,
            ipFocus: _ipFocus,
            macFocus: _macFocus,
            ramFocus: _ramFocus,
            cpuFocus: _cpuFocus,
            hddFocus: _hddFocus,
            saving: _saving,
            ct: ct,
            onSubmit: _submit,
            onCancel: () => setState(() {
              _formVisible = false;
              _clearForm();
            }),
          ),
        ],
        const SizedBox(height: 16),
        if (_loadingList)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(
                color: CobaltColors.cobaltLight,
                strokeWidth: 2,
              ),
            ),
          )
        else if (_loadError != null)
          _ErrorRow(error: _loadError!, ct: ct, onRetry: _loadServidores)
        else if (_servidores.isEmpty)
          _EmptyState(ct: ct)
        else
          disableAnimations
              ? _ServidorTable(
                  servidores: _servidores,
                  isPrivileged: widget.controller.isPrivileged,
                  ct: ct,
                  onDelete: _delete,
                )
              : FadeTransition(
                  opacity: _entranceOpacity,
                  child: ScaleTransition(
                    scale: _entranceScale,
                    child: _ServidorTable(
                      servidores: _servidores,
                      isPrivileged: widget.controller.isPrivileged,
                      ct: ct,
                      onDelete: _delete,
                    ),
                  ),
                ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _PanelHeader extends StatelessWidget {
  final CobaltPalette ct;
  final int count;
  final bool formVisible;
  final VoidCallback onToggleForm;

  const _PanelHeader({
    required this.ct,
    required this.count,
    required this.formVisible,
    required this.onToggleForm,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [CobaltColors.cobalt, CobaltColors.cobaltLight],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Servidores',
          style: TextStyle(
            color: ct.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: CobaltColors.cobalt.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: CobaltColors.cobalt.withValues(alpha: 0.35), width: 1),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: CobaltColors.cobaltLight,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const Spacer(),
        _AddButton(formVisible: formVisible, onTap: onToggleForm),
      ],
    );
  }
}

class _AddButton extends StatefulWidget {
  final bool formVisible;
  final VoidCallback onTap;

  const _AddButton({required this.formVisible, required this.onTap});

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final label =
        widget.formVisible ? 'Cancelar' : 'Agregar servidor';
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            gradient: widget.formVisible
                ? null
                : const LinearGradient(
                    colors: [CobaltColors.cobalt, CobaltColors.cobaltLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: widget.formVisible
                ? context.ct.surfaceElevated
                : null,
            borderRadius: BorderRadius.circular(10),
            border: widget.formVisible
                ? Border.all(
                    color: context.ct.border, width: 1)
                : null,
            boxShadow: widget.formVisible
                ? null
                : [
                    BoxShadow(
                      color: CobaltColors.cobalt.withValues(alpha:0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.formVisible ? Icons.close : Icons.add,
                size: 16,
                color: widget.formVisible
                    ? context.ct.textSecondary
                    : Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: widget.formVisible
                      ? context.ct.textSecondary
                      : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _RegistroForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController hostnameCtrl;
  final TextEditingController ipCtrl;
  final TextEditingController macCtrl;
  final TextEditingController ramCtrl;
  final TextEditingController cpuCtrl;
  final TextEditingController hddCtrl;
  final FocusNode hostnameFocus;
  final FocusNode ipFocus;
  final FocusNode macFocus;
  final FocusNode ramFocus;
  final FocusNode cpuFocus;
  final FocusNode hddFocus;
  final bool saving;
  final CobaltPalette ct;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const _RegistroForm({
    required this.formKey,
    required this.hostnameCtrl,
    required this.ipCtrl,
    required this.macCtrl,
    required this.ramCtrl,
    required this.cpuCtrl,
    required this.hddCtrl,
    required this.hostnameFocus,
    required this.ipFocus,
    required this.macFocus,
    required this.ramFocus,
    required this.cpuFocus,
    required this.hddFocus,
    required this.saving,
    required this.ct,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ct.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ct.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: CobaltColors.cobalt.withValues(alpha:0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nuevo servidor',
              style: TextStyle(
                color: ct.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(builder: (context, box) {
              final wide = box.maxWidth > 560;
              final fields = [
                _FormField(
                  controller: hostnameCtrl,
                  focusNode: hostnameFocus,
                  nextFocus: ipFocus,
                  label: 'Hostname',
                  ct: ct,
                  validator: _requiredValidator,
                ),
                _FormField(
                  controller: ipCtrl,
                  focusNode: ipFocus,
                  nextFocus: macFocus,
                  label: 'Direccion IP',
                  ct: ct,
                  keyboardType: TextInputType.number,
                ),
                _FormField(
                  controller: macCtrl,
                  focusNode: macFocus,
                  nextFocus: ramFocus,
                  label: 'MAC',
                  ct: ct,
                ),
                _FormField(
                  controller: ramCtrl,
                  focusNode: ramFocus,
                  nextFocus: cpuFocus,
                  label: 'RAM',
                  hint: 'ej: 16 GB',
                  ct: ct,
                ),
                _FormField(
                  controller: cpuCtrl,
                  focusNode: cpuFocus,
                  nextFocus: hddFocus,
                  label: 'CPU',
                  hint: 'ej: Intel Xeon E5-2650',
                  ct: ct,
                ),
                _FormField(
                  controller: hddCtrl,
                  focusNode: hddFocus,
                  label: 'HDD',
                  hint: 'ej: 2 TB SATA',
                  ct: ct,
                  isLast: true,
                  onLast: onSubmit,
                ),
              ];
              if (wide) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: fields[0]),
                        const SizedBox(width: 12),
                        Expanded(child: fields[1]),
                        const SizedBox(width: 12),
                        Expanded(child: fields[2]),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: fields[3]),
                        const SizedBox(width: 12),
                        Expanded(child: fields[4]),
                        const SizedBox(width: 12),
                        Expanded(child: fields[5]),
                      ],
                    ),
                  ],
                );
              }
              return Column(
                children: fields
                    .expand((f) => [f, const SizedBox(height: 10)])
                    .toList()
                  ..removeLast(),
              );
            }),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: saving ? null : onCancel,
                  child: Text('Cancelar',
                      style: TextStyle(color: ct.textSecondary)),
                ),
                const SizedBox(width: 10),
                _SubmitButton(saving: saving, onSubmit: onSubmit),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _requiredValidator(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Requerido' : null;
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocus;
  final String label;
  final String? hint;
  final CobaltPalette ct;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool isLast;
  final VoidCallback? onLast;

  const _FormField({
    required this.controller,
    required this.focusNode,
    this.nextFocus,
    required this.label,
    this.hint,
    required this.ct,
    this.validator,
    this.keyboardType,
    this.isLast = false,
    this.onLast,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction:
          isLast ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: (_) {
        if (isLast) {
          onLast?.call();
        } else {
          nextFocus?.requestFocus();
        }
      },
      validator: validator,
      style: TextStyle(color: ct.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: ct.textSecondary, fontSize: 13),
        hintStyle: TextStyle(color: ct.textHint, fontSize: 13),
        filled: true,
        fillColor: ct.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: ct.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
              color: CobaltColors.cobaltLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFFFF5252), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFFFF5252), width: 1.5),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatefulWidget {
  final bool saving;
  final VoidCallback onSubmit;

  const _SubmitButton({required this.saving, required this.onSubmit});

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.saving) widget.onSubmit();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
          decoration: BoxDecoration(
            gradient: widget.saving
                ? null
                : const LinearGradient(
                    colors: [CobaltColors.cobalt, CobaltColors.cobaltLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: widget.saving ? context.ct.border : null,
            borderRadius: BorderRadius.circular(10),
            boxShadow: widget.saving
                ? null
                : [
                    BoxShadow(
                      color: CobaltColors.cobalt.withValues(alpha:0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: widget.saving
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
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ServidorTable extends StatelessWidget {
  final List<Map<String, dynamic>> servidores;
  final bool isPrivileged;
  final CobaltPalette ct;
  final void Function(int id) onDelete;

  const _ServidorTable({
    required this.servidores,
    required this.isPrivileged,
    required this.ct,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ct.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ct.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _TableHeader(ct: ct, isPrivileged: isPrivileged),
          const Divider(height: 1, thickness: 1),
          ...servidores.asMap().entries.map((entry) {
            final idx = entry.key;
            final srv = entry.value;
            return _ServidorRow(
              servidor: srv,
              isEven: idx.isEven,
              isPrivileged: isPrivileged,
              ct: ct,
              onDelete: onDelete,
            );
          }),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final CobaltPalette ct;
  final bool isPrivileged;

  const _TableHeader({required this.ct, required this.isPrivileged});

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      color: ct.textSecondary,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
    );
    return Container(
      color: ct.surfaceElevated,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('HOSTNAME', style: labelStyle)),
          Expanded(flex: 2, child: Text('IP', style: labelStyle)),
          Expanded(flex: 3, child: Text('MAC', style: labelStyle)),
          Expanded(flex: 2, child: Text('RAM', style: labelStyle)),
          Expanded(flex: 3, child: Text('CPU', style: labelStyle)),
          Expanded(flex: 2, child: Text('HDD', style: labelStyle)),
          if (isPrivileged) const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _ServidorRow extends StatelessWidget {
  final Map<String, dynamic> servidor;
  final bool isEven;
  final bool isPrivileged;
  final CobaltPalette ct;
  final void Function(int id) onDelete;

  const _ServidorRow({
    required this.servidor,
    required this.isEven,
    required this.isPrivileged,
    required this.ct,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final id = (servidor['id'] as num?)?.toInt() ?? 0;
    final cellStyle = TextStyle(color: ct.textPrimary, fontSize: 13);
    final mono = cellStyle.copyWith(
      fontFamily: 'monospace',
      color: ct.textSecondary,
      fontSize: 12,
    );
    return Container(
      color: isEven ? ct.surface : ct.surfaceElevated.withValues(alpha:0.5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(servidor['hostname']?.toString() ?? '-',
                  style: cellStyle,
                  overflow: TextOverflow.ellipsis)),
          Expanded(
              flex: 2,
              child: Text(servidor['ip']?.toString() ?? '-',
                  style: mono,
                  overflow: TextOverflow.ellipsis)),
          Expanded(
              flex: 3,
              child: Text(servidor['mac']?.toString() ?? '-',
                  style: mono,
                  overflow: TextOverflow.ellipsis)),
          Expanded(
              flex: 2,
              child: Text(servidor['ram']?.toString() ?? '-',
                  style: cellStyle,
                  overflow: TextOverflow.ellipsis)),
          Expanded(
              flex: 3,
              child: Text(servidor['cpu']?.toString() ?? '-',
                  style: cellStyle,
                  overflow: TextOverflow.ellipsis)),
          Expanded(
              flex: 2,
              child: Text(servidor['hdd']?.toString() ?? '-',
                  style: cellStyle,
                  overflow: TextOverflow.ellipsis)),
          if (isPrivileged)
            SizedBox(
              width: 40,
              child: _DeleteIconButton(
                ct: ct,
                onDelete: () => onDelete(id),
              ),
            ),
        ],
      ),
    );
  }
}

class _DeleteIconButton extends StatefulWidget {
  final CobaltPalette ct;
  final VoidCallback onDelete;

  const _DeleteIconButton({required this.ct, required this.onDelete});

  @override
  State<_DeleteIconButton> createState() => _DeleteIconButtonState();
}

class _DeleteIconButtonState extends State<_DeleteIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onDelete();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Icon(
          Icons.delete_outline,
          size: 18,
          color: _pressed
              ? const Color(0xFFFF5252)
              : widget.ct.textHint,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final CobaltPalette ct;

  const _EmptyState({required this.ct});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dns_outlined, size: 36, color: ct.textHint),
            const SizedBox(height: 10),
            Text(
              'Sin servidores registrados',
              style: TextStyle(
                color: ct.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final String error;
  final CobaltPalette ct;
  final VoidCallback onRetry;

  const _ErrorRow(
      {required this.error, required this.ct, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: Color(0xFFFF5252)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Error al cargar: $error',
              style: const TextStyle(color: Color(0xFFFF5252), fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text('Reintentar',
                style: TextStyle(color: ct.textSecondary, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
