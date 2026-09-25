import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/cobalt_theme.dart';
import '../../../core/colors.dart';
import 'serial_change_controller.dart';
import 'serial_change_models.dart';
import 'steps/config_step.dart';
import 'steps/scan_step.dart';
import 'steps/summary_step.dart';
import 'steps/finish_step.dart';

class SerialChangeScreen extends StatefulWidget {
  const SerialChangeScreen({super.key});
  @override
  State<SerialChangeScreen> createState() => _SerialChangeScreenState();
}

class _SerialChangeScreenState extends State<SerialChangeScreen> {
  final _ctrl = SerialChangeController();

  @override
  void initState() {
    super.initState();
    _ctrl.loadOperators();
    _ctrl.addListener(_rebuild);
  }

  @override
  void dispose() { _ctrl.removeListener(_rebuild); _ctrl.dispose(); super.dispose(); }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    final stepNames = {SCStep.config: 'Configuracion', SCStep.scan: 'Escaneo', SCStep.summary: 'Resumen', SCStep.finish: 'Finalizado'};
    return Scaffold(
      backgroundColor: ct.background,
      body: SafeArea(child: Column(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), color: ct.surface, child: Row(children: [
          IconButton(icon: Icon(Icons.arrow_back_rounded, color: ct.textPrimary, size: 20), onPressed: () => context.pop()),
          const SizedBox(width: 4),
          Icon(Icons.swap_horiz_rounded, size: 18, color: CobaltColors.cobaltLight),
          const SizedBox(width: 8),
          Text('Cambio de Serials', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ct.textPrimary)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: CobaltColors.cobalt.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(stepNames[_ctrl.step] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CobaltColors.cobaltLight))),
        ])),
        Divider(height: 1, color: ct.border),
        Expanded(child: _stepWidget()),
      ])),
    );
  }

  Widget _stepWidget() => switch (_ctrl.step) {
    SCStep.config  => ConfigStep(ctrl: _ctrl),
    SCStep.scan    => ScanStep(ctrl: _ctrl),
    SCStep.summary => SummaryStep(ctrl: _ctrl),
    SCStep.finish  => FinishStep(ctrl: _ctrl),
  };
}

