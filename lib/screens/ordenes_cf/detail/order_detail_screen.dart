import 'package:flutter/material.dart';

import '../../../core/cobalt_theme.dart';
import '../../../core/colors.dart';
import 'order_detail_controller.dart';
import 'panels/masterizacion_panel.dart';
import 'panels/serial_change_panel.dart';
import 'panels/serial_link_panel.dart';
import 'panels/servidor_panel.dart';
import 'panels/serigrafia_panel.dart';
import 'panels/xiaomi_panel.dart';
import 'sections/files_section.dart';
import 'sections/header_section.dart';
import 'sections/lines_section.dart';
import 'sections/log_section.dart';
import 'sections/observations_section.dart';
import 'sections/quality_section.dart';
import 'sections/services_section.dart';
import 'sections/tasks_section.dart';

class OrderDetailScreen extends StatefulWidget {
  final int idnbr;
  const OrderDetailScreen({super.key, required this.idnbr});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late final OrderDetailController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = OrderDetailController(idnbr: widget.idnbr);
    _ctrl.load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return Scaffold(
      backgroundColor: ct.background,
      body: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          if (_ctrl.loading && _ctrl.detail == null) {
            return const Center(
              child: CircularProgressIndicator(
                color: CobaltColors.cobaltLight,
              ),
            );
          }
          if (_ctrl.error != null && _ctrl.detail == null) {
            return _buildErrorView(context, ct);
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 900) {
                return _buildSplitPane(context, ct);
              }
              return _buildSingleColumn(context, ct);
            },
          );
        },
      ),
    );
  }

  // ── Split pane (>=900px) ─────────────────────────────────────────────────

  Widget _buildSplitPane(BuildContext context, CobaltPalette ct) {
    final detail = _ctrl.detail!;
    final estado = detail.agentOrder.estado;
    final family = detail.agentOrder.family ?? '';
    final inExecution = estado.contains('3');
    final hasLines = (detail.sourceOrder?['lines'] as List?)?.isNotEmpty == true;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: 58,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HeaderSection(controller: _ctrl),
                if (hasLines) ...[
                  const SizedBox(height: 20),
                  _sectionLabel(ct, 'LÍNEAS DEL PEDIDO'),
                  LinesSection(controller: _ctrl),
                ],
                const SizedBox(height: 20),
                ServicesSection(controller: _ctrl),
                const SizedBox(height: 20),
                TasksSection(controller: _ctrl),
                const SizedBox(height: 20),
                ObservationsSection(controller: _ctrl),
              ],
            ),
          ),
        ),
        VerticalDivider(width: 1, thickness: 1, color: ct.border),
        Flexible(
          flex: 42,
          child: inExecution && family.isNotEmpty
              ? _buildFamilyPanel(context, ct, family)
              : _buildRightColumn(context, ct),
        ),
      ],
    );
  }

  // ── Single column (<900px) ───────────────────────────────────────────────

  Widget _buildSingleColumn(BuildContext context, CobaltPalette ct) {
    final detail = _ctrl.detail!;
    final estado = detail.agentOrder.estado;
    final family = detail.agentOrder.family ?? '';
    final inExecution = estado.contains('3');
    final hasLines = (detail.sourceOrder?['lines'] as List?)?.isNotEmpty == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeaderSection(controller: _ctrl),
          if (hasLines) ...[
            const SizedBox(height: 20),
            _sectionLabel(ct, 'LÍNEAS DEL PEDIDO'),
            LinesSection(controller: _ctrl),
          ],
          const SizedBox(height: 20),
          ServicesSection(controller: _ctrl),
          const SizedBox(height: 20),
          TasksSection(controller: _ctrl),
          const SizedBox(height: 20),
          ObservationsSection(controller: _ctrl),
          if (inExecution && family.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildFamilyPanel(context, ct, family),
          ],
          const SizedBox(height: 20),
          _sectionLabel(ct, 'DOCUMENTACIÓN'),
          QualitySection(controller: _ctrl),
          const SizedBox(height: 12),
          FilesSection(controller: _ctrl),
          const SizedBox(height: 20),
          LogSection(controller: _ctrl),
        ],
      ),
    );
  }

  // ── Right column (quality / files / log) ─────────────────────────────────

  Widget _buildRightColumn(BuildContext context, CobaltPalette ct) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel(ct, 'DOCUMENTACIÓN'),
          QualitySection(controller: _ctrl),
          const SizedBox(height: 12),
          FilesSection(controller: _ctrl),
          const SizedBox(height: 20),
          LogSection(controller: _ctrl),
        ],
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────

  Widget _sectionLabel(CobaltPalette ct, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: ct.textHint,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(height: 1, color: ct.border)),
        ],
      ),
    );
  }

  // ── Family panel routing ──────────────────────────────────────────────────

  Widget _buildFamilyPanel(
      BuildContext context, CobaltPalette ct, String family) {
    final f = family.toUpperCase();
    if (f.contains('SERIGRAFIA') || f.contains('SERIGRAFIADO')) {
      return SerigrafiaPanel(controller: _ctrl);
    }
    if (f.contains('SERVIDOR') || f.contains('SERVIDORES')) {
      return ServidorPanel(controller: _ctrl);
    }
    if (f.contains('MASTERIZ')) {
      return MasterizacionPanel(controller: _ctrl);
    }
    if (f.contains('XIAOMI')) {
      return XiaomiPanel(controller: _ctrl);
    }
    if (f.contains('CAMBIO DE SERIAL')) {
      return SerialChangePanel(controller: _ctrl);
    }
    if (f.contains('MANIPULAC') || f.contains('ETIQUETADO')) {
      return SerialLinkPanel(controller: _ctrl);
    }
    return _buildRightColumn(context, ct);
  }

  // ── Error view ────────────────────────────────────────────────────────────

  Widget _buildErrorView(BuildContext context, CobaltPalette ct) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Error al cargar la orden',
              style: TextStyle(
                color: ct.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _ctrl.error ?? '',
              style: TextStyle(color: ct.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _ctrl.load,
              style: FilledButton.styleFrom(
                backgroundColor: CobaltColors.cobalt,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
