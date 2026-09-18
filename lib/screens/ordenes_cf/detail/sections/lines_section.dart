import 'package:flutter/material.dart';

import '../../../../core/cobalt_theme.dart';
import '../../../../core/colors.dart';
import '../../widgets/status_badge.dart';
import '../order_detail_controller.dart';

const double _skuW = 120;
const double _descFixedW = 180;
const double _qtyW = 60;
const double _costeW = 80;
const double _pvdW = 80;
const double _margenW = 70;
const double _rowPadH = 8;
const double _borderW = 3;

class LinesSection extends StatelessWidget {
  final OrderDetailController controller;

  const LinesSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    final rawLines = controller.detail?.sourceOrder?['lines'] as List?;

    if (rawLines == null || rawLines.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: ct.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ct.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Text(
          'Sin líneas de origen disponibles',
          style: TextStyle(color: ct.textHint, fontSize: 12),
        ),
      );
    }

    final lines = rawLines.cast<Map<String, dynamic>>();
    final showFinancials = controller.canViewFinancials;

    Widget table = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TableHeader(ct: ct, showFinancials: showFinancials),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: lines.length,
          itemBuilder: (context, index) => _LineRow(
            ct: ct,
            data: lines[index],
            isEven: index.isEven,
            showFinancials: showFinancials,
          ),
        ),
      ],
    );

    if (showFinancials) {
      table = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: table,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(ct: ct, count: lines.length),
        const SizedBox(height: 8),
        table,
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final CobaltPalette ct;
  final int count;

  const _SectionTitle({required this.ct, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'LÍNEAS',
          style: TextStyle(
            color: ct.textHint,
            fontSize: 9.5,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: CobaltColors.cobalt.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: CobaltColors.cobaltLight,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  final CobaltPalette ct;
  final bool showFinancials;

  const _TableHeader({required this.ct, required this.showFinancials});

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      color: ct.textHint,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );

    Widget descCell = showFinancials
        ? SizedBox(
            width: _descFixedW,
            child: Text('DESCRIPCIÓN', style: labelStyle),
          )
        : Expanded(child: Text('DESCRIPCIÓN', style: labelStyle));

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: _rowPadH),
      decoration: BoxDecoration(
        color: ct.surface,
        border: Border(bottom: BorderSide(color: ct.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _skuW,
            child: Text('SKU', style: labelStyle),
          ),
          descCell,
          SizedBox(
            width: _qtyW,
            child: Text('QTY', style: labelStyle, textAlign: TextAlign.right),
          ),
          if (showFinancials) ...[
            SizedBox(
              width: _costeW,
              child: Text('COSTE', style: labelStyle, textAlign: TextAlign.right),
            ),
            SizedBox(
              width: _pvdW,
              child: Text('PVD', style: labelStyle, textAlign: TextAlign.right),
            ),
            SizedBox(
              width: _margenW,
              child: Text('MARGEN %', style: labelStyle, textAlign: TextAlign.right),
            ),
          ],
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  final CobaltPalette ct;
  final Map<String, dynamic> data;
  final bool isEven;
  final bool showFinancials;

  const _LineRow({
    required this.ct,
    required this.data,
    required this.isEven,
    required this.showFinancials,
  });

  double _num(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;

  Color _priceColor(double coste, double pvd) {
    if (pvd <= 0 || coste <= 0) return StatusBadge.colorFor('2');
    if (pvd < coste) return StatusBadge.colorFor('4');
    return StatusBadge.colorFor('5');
  }

  @override
  Widget build(BuildContext context) {
    final sku = data['sku']?.toString() ?? '-';
    final desc = (data['description'] ?? data['desc'])?.toString() ?? '';
    final rawQty = data['qty'] ?? data['quantity'];
    final qty = rawQty is num
        ? (rawQty % 1 == 0
            ? rawQty.toInt().toString()
            : rawQty.toStringAsFixed(2))
        : rawQty?.toString() ?? '0';
    final coste = _num(data['coste'] ?? data['cost']);
    final pvd = _num(data['pvd']);
    final margen = _num(data['margen']);

    final borderColor = _priceColor(coste, pvd);
    final bg = isEven ? Colors.transparent : ct.surface.withValues(alpha: 0.35);

    final descStyle = TextStyle(color: ct.textPrimary, fontSize: 12);
    final monoStyle = TextStyle(color: ct.textSecondary, fontSize: 11);

    Widget descCell = showFinancials
        ? SizedBox(
            width: _descFixedW,
            child: Text(desc, style: descStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
          )
        : Expanded(
            child: Text(desc, style: descStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
          );

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: _rowPadH),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          left: BorderSide(width: _borderW, color: borderColor),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _skuW,
            child: Text(
              sku,
              style: TextStyle(
                color: CobaltColors.cobaltLight,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          descCell,
          SizedBox(
            width: _qtyW,
            child: Text(
              qty,
              style: TextStyle(color: ct.textSecondary, fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
          if (showFinancials) ...[
            SizedBox(
              width: _costeW,
              child: Text(
                coste > 0 ? coste.toStringAsFixed(2) : '-',
                style: monoStyle,
                textAlign: TextAlign.right,
              ),
            ),
            SizedBox(
              width: _pvdW,
              child: Text(
                pvd > 0 ? pvd.toStringAsFixed(2) : '-',
                style: monoStyle,
                textAlign: TextAlign.right,
              ),
            ),
            SizedBox(
              width: _margenW,
              child: Text(
                margen != 0 ? '${margen.toStringAsFixed(1)}%' : '-',
                style: monoStyle,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
