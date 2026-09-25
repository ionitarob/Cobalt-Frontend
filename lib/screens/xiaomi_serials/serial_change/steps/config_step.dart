import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/cobalt_theme.dart';
import '../../../../core/colors.dart';
import '../serial_change_controller.dart';
import '../serial_change_models.dart';

class ConfigStep extends StatefulWidget {
  final SerialChangeController ctrl;
  const ConfigStep({super.key, required this.ctrl});
  @override
  State<ConfigStep> createState() => _ConfigStepState();
}

class _ConfigStepState extends State<ConfigStep> {
  final _orderCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _unitsCtrl = TextEditingController();

  @override
  void dispose() {
    _orderCtrl.dispose();
    _skuCtrl.dispose();
    _unitsCtrl.dispose();
    super.dispose();
  }

  SerialChangeController get c => widget.ctrl;

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Configuracion',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ct.textPrimary)),
          const SizedBox(height: 4),
          Text('Selecciona operador, tipo y datos de la orden',
              style: TextStyle(fontSize: 13, color: ct.textSecondary)),
          const SizedBox(height: 24),
          _lbl(ct, 'Operador'),
          const SizedBox(height: 6),
          _opDrop(ct),
          const SizedBox(height: 16),

          if (c.labelTypes.isNotEmpty) ...[
            _lbl(ct, 'Tipo de etiqueta'),
            const SizedBox(height: 6),
            _typeDrop(ct),
            const SizedBox(height: 16),
          ],
          _lbl(ct, 'No Orden'), const SizedBox(height: 6),
          _orderField(ct),
          const SizedBox(height: 16),
          _lbl(ct, 'SKU'), const SizedBox(height: 6),
          _tf(ct, _skuCtrl, '12ABCD', (v) => c.sku = v),
          const SizedBox(height: 16),
          _lbl(ct, 'Unidades totales'), const SizedBox(height: 6),
          _tf(ct, _unitsCtrl, '500', (v) => c.totalUnits = int.tryParse(v) ?? 0, kb: TextInputType.number),
          const SizedBox(height: 16),
          _lbl(ct, 'Fecha produccion'), const SizedBox(height: 6),
          _datePick(ct), const SizedBox(height: 32),
          SizedBox(height: 48, child: FilledButton(
            onPressed: c.selectedType == null ? null : _gen,
            style: FilledButton.styleFrom(backgroundColor: CobaltColors.cobalt, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Generar etiquetas', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          )),
        ]));
  }
  void _gen() { final e = c.generateLabels(); if (e != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e))); }
  Widget _lbl(CobaltPalette ct, String t) => Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ct.textSecondary));
  Widget _tf(CobaltPalette ct, TextEditingController tc, String h, void Function(String) oc, {TextInputType? kb}) => TextField(controller: tc, keyboardType: kb, style: TextStyle(color: ct.textPrimary, fontSize: 14), decoration: InputDecoration(hintText: h, hintStyle: TextStyle(color: ct.textHint), filled: true, fillColor: ct.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ct.border)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ct.border)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)), onChanged: oc);

  Widget _orderField(CobaltPalette ct) => TextField(
    controller: _orderCtrl,
    keyboardType: TextInputType.number,
    inputFormatters: [_OrderFormatter()],
    style: TextStyle(color: ct.textPrimary, fontSize: 14, fontFeatures: const [FontFeature.tabularFigures()], letterSpacing: 0.5),
    decoration: InputDecoration(
      hintText: 'XX-XXXXX-XX', hintStyle: TextStyle(color: ct.textHint),
      filled: true, fillColor: ct.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ct.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ct.border)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    onChanged: (v) => c.orderNbr = v,
  );
  Widget _opDrop(CobaltPalette ct) => _drop<SCOperator>(ct, c.operators, c.selectedOperator, (o) => o.name, (o) { if (o != null) c.selectOperator(o); });

  Widget _typeDrop(CobaltPalette ct) {
    return Autocomplete<SCLabelType>(
      displayStringForOption: (t) => t.displayName,
      optionsBuilder: (text) {
        if (text.text.isEmpty) return c.labelTypes;
        final q = text.text.toLowerCase();
        return c.labelTypes.where((t) =>
            t.displayName.toLowerCase().contains(q) ||
            (t.sapClient ?? '').toLowerCase().contains(q) ||
            (t.codeLetter ?? '').toLowerCase().contains(q));
      },
      onSelected: (t) => c.selectType(t),
      fieldViewBuilder: (ctx, tc, fn, onSubmit) => TextField(
        controller: tc,
        focusNode: fn,
        style: TextStyle(color: ct.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: c.selectedType?.displayName ?? 'Buscar tipo...',
          hintStyle: TextStyle(color: ct.textHint),
          prefixIcon: Icon(Icons.search, size: 18, color: ct.textHint),
          suffixIcon: c.selectedType != null
              ? IconButton(
                  icon: Icon(Icons.clear, size: 16, color: ct.textHint),
                  onPressed: () { tc.clear(); c.selectType(c.labelTypes.first); })
              : null,
          filled: true, fillColor: ct.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ct.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ct.border)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        onSubmitted: (_) => onSubmit(),
      ),
      optionsViewBuilder: (ctx, onSelect, opts) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            color: ct.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: 400),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: opts.length,
                itemBuilder: (_, i) {
                  final t = opts.elementAt(i);
                  return InkWell(
                    onTap: () => onSelect(t),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(children: [
                        Expanded(child: Text(t.displayName, style: TextStyle(color: ct.textPrimary, fontSize: 13))),
                        if (t.sapClient != null && t.sapClient!.isNotEmpty)
                          Text(t.sapClient!, style: TextStyle(color: ct.textHint, fontSize: 11)),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
  Widget _drop<T>(CobaltPalette ct, List<T> items, T? sel, String Function(T) lbl, void Function(T?) oc) => Container(padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: ct.surface, border: Border.all(color: ct.border), borderRadius: BorderRadius.circular(8)), child: DropdownButton<T>(value: sel, isExpanded: true, underline: const SizedBox(), hint: Text('Seleccionar...', style: TextStyle(color: ct.textHint, fontSize: 14)), dropdownColor: ct.surfaceElevated, style: TextStyle(color: ct.textPrimary, fontSize: 14), items: items.map((e) => DropdownMenuItem(value: e, child: Text(lbl(e)))).toList(), onChanged: oc));
  Widget _datePick(CobaltPalette ct) => GestureDetector(onTap: () async { final d = await showDatePicker(context: context, initialDate: c.productionDate, firstDate: DateTime(2020), lastDate: DateTime(2030)); if (d != null) setState(() => c.productionDate = d); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: ct.surface, border: Border.all(color: ct.border), borderRadius: BorderRadius.circular(8)), child: Row(children: [Icon(Icons.calendar_today, size: 16, color: ct.textHint), const SizedBox(width: 10), Text(DateFormat('dd/MM/yyyy').format(c.productionDate), style: TextStyle(color: ct.textPrimary, fontSize: 14))])));
}

/// Auto-formats order numbers: user types digits, sees XX-XXXXX-XX.
/// Strips non-digits, inserts dashes at positions 2 and 7, caps at 9 digits.
class _OrderFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue cur) {
    final digits = cur.text.replaceAll(RegExp(r'[^0-9]'), '');
    final capped = digits.length > 9 ? digits.substring(0, 9) : digits;
    final buf = StringBuffer();
    for (int i = 0; i < capped.length; i++) {
      if (i == 2 || i == 7) buf.write('-');
      buf.write(capped[i]);
    }
    final formatted = buf.toString();
    // Place cursor at end
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

