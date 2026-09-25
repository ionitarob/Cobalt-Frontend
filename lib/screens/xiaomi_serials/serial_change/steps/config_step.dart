import 'package:flutter/material.dart';
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
          _tf(ct, _orderCtrl, '29-19574-11', (v) => c.orderNbr = v),
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
  Widget _opDrop(CobaltPalette ct) => _drop<SCOperator>(ct, c.operators, c.selectedOperator, (o) => o.name, (o) { if (o != null) c.selectOperator(o); });
  Widget _typeDrop(CobaltPalette ct) => _drop<SCLabelType>(ct, c.labelTypes, c.selectedType, (t) => t.displayName, (t) { if (t != null) c.selectType(t); });
  Widget _drop<T>(CobaltPalette ct, List<T> items, T? sel, String Function(T) lbl, void Function(T?) oc) => Container(padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: ct.surface, border: Border.all(color: ct.border), borderRadius: BorderRadius.circular(8)), child: DropdownButton<T>(value: sel, isExpanded: true, underline: const SizedBox(), hint: Text('Seleccionar...', style: TextStyle(color: ct.textHint, fontSize: 14)), dropdownColor: ct.surfaceElevated, style: TextStyle(color: ct.textPrimary, fontSize: 14), items: items.map((e) => DropdownMenuItem(value: e, child: Text(lbl(e)))).toList(), onChanged: oc));
  Widget _datePick(CobaltPalette ct) => GestureDetector(onTap: () async { final d = await showDatePicker(context: context, initialDate: c.productionDate, firstDate: DateTime(2020), lastDate: DateTime(2030)); if (d != null) setState(() => c.productionDate = d); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: ct.surface, border: Border.all(color: ct.border), borderRadius: BorderRadius.circular(8)), child: Row(children: [Icon(Icons.calendar_today, size: 16, color: ct.textHint), const SizedBox(width: 10), Text(DateFormat('dd/MM/yyyy').format(c.productionDate), style: TextStyle(color: ct.textPrimary, fontSize: 14))])));
}
