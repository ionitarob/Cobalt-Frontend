import 'package:flutter/material.dart';

import '../../../core/cobalt_theme.dart';
import '../../../core/colors.dart';
import '../../../models/orderops/aprovisionamiento.dart';
import '../../../services/orderops/aprovisionamiento_service.dart';
import '../../../services/orderops/orders_service.dart';

class AprovPanel extends StatefulWidget {
  final AprovisionamientoRecord? existing;
  final VoidCallback onSaved;

  const AprovPanel({super.key, this.existing, required this.onSaved});

  @override
  State<AprovPanel> createState() => _AprovPanelState();
}

class _AprovPanelState extends State<AprovPanel> {
  final _customerCtrl = TextEditingController();
  final _orderNbrCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();

  List<String> _families = [];
  String? _selectedFamily;
  String? _selectedPrio;
  Map<String, dynamic>? _selectedEmployee;
  bool _autoApply = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _customerCtrl.text = e.customer;
      _orderNbrCtrl.text = e.orderNbr ?? '';
      _notasCtrl.text = e.notas ?? '';
      _selectedFamily = e.family;
      _selectedPrio = e.prioridad;
      _autoApply = e.autoApply;
      if (e.assignedTo != null) {
        _selectedEmployee = {
          'id': e.assignedTo,
          'display_name': e.assignedToName ?? e.assignedTo,
        };
      }
    }
    _loadFamilies();
  }

  Future<void> _loadFamilies() async {
    try {
      final list = await OrdersService.instance.getCatalogFamilies();
      if (mounted) setState(() => _families = {...list}.toList()..sort());
    } catch (_) {}
  }

  @override
  void dispose() {
    _customerCtrl.dispose();
    _orderNbrCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final customer = _customerCtrl.text.trim();
    if (customer.isEmpty) return;

    setState(() => _saving = true);
    try {
      final e = widget.existing;
      if (e == null) {
        await AprovisionamientoService.instance.create(
          customer: customer,
          orderNbr: _orderNbrCtrl.text.trim().isEmpty ? null : _orderNbrCtrl.text.trim(),
          notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
          family: _selectedFamily,
          prioridad: _selectedPrio,
          assignedTo: _selectedEmployee?['id']?.toString(),
          assignedToName: _selectedEmployee?['display_name']?.toString(),
          autoApply: _autoApply,
        );
      } else {
        await AprovisionamientoService.instance.update(
          e.id,
          customer: customer,
          orderNbr: _orderNbrCtrl.text.trim(),
          notas: _notasCtrl.text.trim(),
          family: _selectedFamily ?? '',
          prioridad: _selectedPrio ?? '',
          assignedTo: _selectedEmployee?['id']?.toString() ?? '',
          assignedToName: _selectedEmployee?['display_name']?.toString() ?? '',
          autoApply: _autoApply,
        );
      }
      widget.onSaved();
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    final isEdit = widget.existing != null;

    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: ct.surface,
        border: Border(left: BorderSide(color: ct.border)),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(-4, 0))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: ct.border)),
            ),
            child: Row(
              children: [
                Text(isEdit ? 'Editar aprovisionamiento' : 'Nuevo aprovisionamiento',
                    style: TextStyle(
                        color: ct.textPrimary,
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const Spacer(),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: widget.onSaved,
                    child: Icon(Icons.close_rounded,
                        size: 16, color: ct.textHint),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _field(ct, 'Cliente *', _customerCtrl, Icons.business_outlined),
                const SizedBox(height: 14),
                _field(ct, 'Nº Orden esperado', _orderNbrCtrl, Icons.receipt_long_outlined,
                    hint: 'SE-12345-01'),
                const SizedBox(height: 14),
                _familySection(ct),
                const SizedBox(height: 14),
                _prioSection(ct),
                const SizedBox(height: 14),
                _employeeSection(ct),
                const SizedBox(height: 14),
                _notasField(ct),
                const SizedBox(height: 14),
                _autoApplyToggle(ct),
                const SizedBox(height: 24),
                _saveButton(isEdit),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(CobaltPalette ct, String label, TextEditingController ctrl, IconData icon, {String? hint}) {
    return TextField(
      controller: ctrl,
      style: TextStyle(color: ct.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: ct.textHint, fontSize: 12),
        hintText: hint,
        hintStyle: TextStyle(color: ct.textHint, fontSize: 12),
        prefixIcon: Icon(icon, size: 16, color: ct.textHint),
        filled: true,
        fillColor: ct.background,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: ct.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: ct.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: CobaltColors.cobaltLight, width: 1.5)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _notasField(CobaltPalette ct) {
    return TextField(
      controller: _notasCtrl,
      maxLines: 3,
      style: TextStyle(color: ct.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        labelText: 'Notas',
        labelStyle: TextStyle(color: ct.textHint, fontSize: 12),
        filled: true,
        fillColor: ct.background,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: ct.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: ct.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: CobaltColors.cobaltLight, width: 1.5)),
        isDense: true,
        contentPadding: const EdgeInsets.all(12),
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _familySection(CobaltPalette ct) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Familia',
            style: TextStyle(color: ct.textHint, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (_families.isEmpty)
          Text('Cargando…',
              style: TextStyle(color: ct.textHint, fontSize: 12))
        else
          Wrap(
            spacing: 6, runSpacing: 6,
            children: _families.map((f) {
              final sel = _selectedFamily == f;
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedFamily = sel ? null : f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: sel
                          ? CobaltColors.cobalt.withValues(alpha: 0.20)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: sel ? CobaltColors.cobaltLight : ct.border),
                    ),
                    child: Text(f,
                        style: TextStyle(
                            fontSize: 11.5,
                            color: sel ? CobaltColors.cobaltLight : ct.textSecondary,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _prioSection(CobaltPalette ct) {
    final prios = [('1', 'Alta'), ('2', 'Media'), ('3', 'Baja')];
    final colors = [const Color(0xFFFF5252), const Color(0xFFFFAA00), const Color(0xFF2EC672)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Prioridad',
            style: TextStyle(color: ct.textHint, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(prios.length, (i) {
            final (code, label) = prios[i];
            final sel = _selectedPrio == code;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPrio = sel ? null : code),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: sel ? colors[i].withValues(alpha: 0.16) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: sel ? colors[i] : ct.border),
                    ),
                    child: Text(label,
                        style: TextStyle(
                            fontSize: 12,
                            color: sel ? colors[i] : ct.textSecondary,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _employeeSection(CobaltPalette ct) {
    return Autocomplete<Map<String, dynamic>>(
      initialValue: _selectedEmployee != null
          ? TextEditingValue(text: _selectedEmployee!['display_name']?.toString() ?? '')
          : TextEditingValue.empty,
      displayStringForOption: (e) => e['display_name']?.toString() ?? '',
      optionsBuilder: (v) async {
        if (v.text.length < 2) return [];
        try {
          return await OrdersService.instance.getEmployees(q: v.text, limit: 20);
        } catch (_) {
          return [];
        }
      },
      onSelected: (emp) => setState(() => _selectedEmployee = emp),
      fieldViewBuilder: (ctx, fCtrl, fNode, onSub) => TextField(
        controller: fCtrl,
        focusNode: fNode,
        onEditingComplete: onSub,
        style: TextStyle(color: ct.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          labelText: 'Asignar a',
          labelStyle: TextStyle(color: ct.textHint, fontSize: 12),
          hintText: 'Buscar técnico…',
          prefixIcon: Icon(Icons.person_outline, size: 16, color: ct.textHint),
          suffixIcon: _selectedEmployee != null
              ? const Icon(Icons.check_circle, size: 14, color: Color(0xFF2EC672))
              : null,
          filled: true,
          fillColor: ct.background,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: ct.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: ct.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: CobaltColors.cobaltLight, width: 1.5)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      optionsViewBuilder: (ctx, onSel, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          color: ct.surface,
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200, maxWidth: 360),
            child: ListView.builder(
              padding: EdgeInsets.zero, shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (_, i) {
                final emp = options.elementAt(i);
                return ListTile(
                  dense: true,
                  leading: Icon(Icons.person_outline, size: 16, color: ct.textHint),
                  title: Text(emp['display_name']?.toString() ?? '',
                      style: TextStyle(color: ct.textPrimary, fontSize: 13)),
                  subtitle: emp['empresa_nombre'] != null
                      ? Text(emp['empresa_nombre'].toString(),
                          style: TextStyle(color: ct.textHint, fontSize: 11))
                      : null,
                  onTap: () => onSel(emp),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _autoApplyToggle(CobaltPalette ct) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CobaltColors.cobalt.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CobaltColors.cobalt.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_outlined, size: 16, color: CobaltColors.cobaltLight),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Aplicar al enlazar',
                  style: TextStyle(color: ct.textPrimary, fontSize: 12,
                      fontWeight: FontWeight.w600)),
              Text('Aplica familia, prioridad y asignación automáticamente.',
                  style: TextStyle(color: ct.textHint, fontSize: 11)),
            ]),
          ),
          Switch(
            value: _autoApply,
            onChanged: (v) => setState(() => _autoApply = v),
            activeThumbColor: CobaltColors.cobaltLight,
          ),
        ],
      ),
    );
  }

  Widget _saveButton(bool isEdit) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _saving ? null : _save,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [CobaltColors.cobalt, CobaltColors.cobaltLight],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: _saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(isEdit ? 'Guardar' : 'Crear',
                    style: const TextStyle(color: Colors.white, fontSize: 13,
                        fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}
