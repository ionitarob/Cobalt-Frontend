import 'package:flutter/foundation.dart';
import 'serial_change_models.dart';
import 'serial_change_service.dart';
import 'label_generator.dart';

/// State machine controller for the Serial Change workflow.
class SerialChangeController extends ChangeNotifier {
  final _svc = SerialChangeService.instance;

  // ── State ──────────────────────────────────────────────────────────────
  SCStep step = SCStep.config;
  bool loading = false;
  String? error;

  // Config
  List<SCOperator> operators = [];
  SCOperator? selectedOperator;
  List<SCLabelType> labelTypes = [];
  SCLabelType? selectedType;
  String orderNbr = '';
  String sku = '';
  int totalUnits = 0;
  int startSequence = 1;
  DateTime productionDate = DateTime.now();

  // Generated
  List<String> allLabels = [];
  List<String> consumedLabels = [];
  bool configLocked = false;

  // Active box
  SCBoxSession? activeBox;
  List<SCBoxSession> completedBoxes = [];

  // ── Init ───────────────────────────────────────────────────────────────
  Future<void> loadOperators() async {
    loading = true; error = null; notifyListeners();
    try {
      operators = await _svc.getOperators();
    } catch (e) { error = e.toString(); }
    loading = false; notifyListeners();
  }

  Future<void> selectOperator(SCOperator op) async {
    selectedOperator = op;
    selectedType = null;
    labelTypes = [];
    notifyListeners();
    try {
      labelTypes = await _svc.getLabelTypes(op.name);
    } catch (e) { error = e.toString(); }
    notifyListeners();
  }

  void selectType(SCLabelType t) {
    selectedType = t;
    notifyListeners();
  }

  // ── Generate labels ────────────────────────────────────────────────────
  String? generateLabels() {
    if (selectedOperator == null || selectedType == null) return 'Selecciona operador y tipo';
    if (orderNbr.trim().isEmpty) return 'Introduce el nº de orden';
    if (sku.trim().isEmpty) return 'Introduce el SKU';
    if (totalUnits <= 0) return 'Introduce unidades válidas';

    allLabels = LabelGenerator.generate(
      operatorName: selectedOperator!.name,
      date: productionDate,
      totalUnits: totalUnits,
      article: selectedType!.article,
      sapClient: selectedType!.sapClient,
      codeLetter: selectedType!.codeLetter,
      startSequence: startSequence,
    );
    consumedLabels = [];
    configLocked = true;
    step = SCStep.scan;
    notifyListeners();
    return null; // success
  }

  // ── Box management ─────────────────────────────────────────────────────
  List<String> get pendingLabels =>
      allLabels.where((l) => !consumedLabels.contains(l)).toList();

  String? startBox(String boxNumber, int unitsPerBox) {
    if (boxNumber.trim().isEmpty) return 'Introduce nº de caja';
    if (unitsPerBox <= 0) return 'Introduce unidades válidas';
    final labels = pendingLabels.take(unitsPerBox).toList();
    if (labels.isEmpty) return 'No quedan etiquetas pendientes';
    activeBox = SCBoxSession(
      boxNumber: boxNumber.trim(),
      units: unitsPerBox,
      labels: labels,
    );
    notifyListeners();
    return null;
  }

  // ── Scan & register ────────────────────────────────────────────────────
  Future<String?> scanOldSerial(String oldSerial) async {
    if (activeBox == null) return 'No hay caja activa';
    if (activeBox!.isComplete) return 'Caja completa';
    final newLabel = activeBox!.currentLabel;
    if (newLabel == null) return 'Sin etiquetas disponibles';
    final trimmed = oldSerial.trim();
    if (trimmed.isEmpty) return 'Serial vacío';

    try {
      final id = await _svc.addRegistry({
        'nr_orden': orderNbr,
        'nr_sku': sku,
        'nr_unidades': totalUnits,
        'tipo_etiqueta': selectedType?.displayName,
        'tipo_etiqueta_id': selectedType?.id,
        'nr_box': activeBox!.boxNumber,
        'nr_unidades_box': activeBox!.units,
        'serial_old': trimmed,
        'serial_new': newLabel,
        'usuario': selectedOperator?.name,
      });
      activeBox!.mappings.add(SCMapping(
        id: id, oldSerial: trimmed, newSerial: newLabel, scannedAt: DateTime.now(),
      ));
      notifyListeners();

      if (activeBox!.isComplete) {
        _completeBox();
      }
      return null; // success
    } catch (e) {
      return 'Error: $e';
    }
  }

  void _completeBox() {
    if (activeBox == null) return;
    for (final m in activeBox!.mappings) {
      consumedLabels.add(m.newSerial);
    }
    completedBoxes.add(activeBox!);
    activeBox = null;

    if (pendingLabels.isEmpty) {
      step = SCStep.finish;
    } else {
      step = SCStep.summary;
    }
    notifyListeners();
  }

  void nextBox() {
    step = SCStep.scan;
    notifyListeners();
  }

  void reset() {
    step = SCStep.config;
    configLocked = false;
    allLabels = [];
    consumedLabels = [];
    activeBox = null;
    completedBoxes = [];
    error = null;
    notifyListeners();
  }

  // ── Stats ──────────────────────────────────────────────────────────────
  int get totalScanned => completedBoxes.fold(0, (s, b) => s + b.scannedCount)
      + (activeBox?.scannedCount ?? 0);
  double get progressPct => totalUnits > 0 ? totalScanned / totalUnits : 0;
}

