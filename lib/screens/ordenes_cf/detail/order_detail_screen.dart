import 'package:flutter/material.dart';

import '../../../core/cobalt_theme.dart';
import '../../../core/colors.dart';
import 'order_detail_controller.dart';
import 'sections/files_section.dart';
import 'sections/log_section.dart';
import 'sections/observations_section.dart';
import 'sections/quality_section.dart';
import 'sections/services_section.dart';
import 'sections/tasks_section.dart';
import 'widgets/order_tab_bar.dart';
import 'widgets/order_top_bar.dart';
import 'widgets/workflow_action_bar.dart';

class OrderDetailScreen extends StatefulWidget {
  final int idnbr;
  const OrderDetailScreen({super.key, required this.idnbr});
  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen>
    with SingleTickerProviderStateMixin {
  late final OrderDetailController _ctrl;
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _ctrl = OrderDetailController(idnbr: widget.idnbr);
    _tabs = TabController(length: 4, vsync: this);
    _ctrl.load();
  }

  @override
  void dispose() {
    _tabs.dispose();
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
            return _errorView(ct);
          }
          return Column(children: [
            OrderTopBar(controller: _ctrl),
            WorkflowActionBar(controller: _ctrl),
            OrderTabBar(controller: _tabs),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _serviciosTab(),
                  _tareasTab(),
                  _archivosTab(),
                  _historialTab(),
                ],
              ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _serviciosTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ServicesSection(controller: _ctrl),
      );

  Widget _tareasTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TasksSection(controller: _ctrl),
            const SizedBox(height: 20),
            ObservationsSection(controller: _ctrl),
          ],
        ),
      );

  Widget _archivosTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            QualitySection(controller: _ctrl),
            const SizedBox(height: 16),
            FilesSection(controller: _ctrl),
          ],
        ),
      );

  Widget _historialTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: LogSection(controller: _ctrl),
      );

  Widget _errorView(CobaltPalette ct) => Center(
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