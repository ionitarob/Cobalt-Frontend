import 'package:flutter/foundation.dart';
import 'serial_change_models.dart';
import 'serial_change_service.dart';
import 'label_generator.dart';

class SerialChangeController extends ChangeNotifier {
  final _svc = SerialChangeService.instance;

  SCStep step = SCStep.config;
  bool loading = false;
  String? error;

  List<SCOperator> operators = [];
  SCOperator? selectedOperator;
  List<SCLabelType> labelTypes = [];
  SCLabelType? selectedType;
  String orderNbr = '';
  String sku = '';
  String ean = '';
  int totalUnits = 0;
  int startSequence = 1;
  DateTime productionDate = DateTime.now();

  SCResumeData? resumeData;
  bool checkingOrder = false;

  List<String> allLabels = [];
  List<String> consumedLabels = [];
  bool configLocked = false;

  SCBoxSession? activeBox;
  List<SCBoxSession> completedBoxes = [];
  SCPrinter? cachedPrinter;

  Future<void> loadOperators() async {
    loading = true; error = null; notifyListeners();
    try {
      operators = await _svc.getOperators();
      if (operators.isNotEmpty && selectedOperator == null) {
        await selectOperator(operators.first);
      }
    } catch (e) { error = e.toString(); }
    loading = false; notifyListeners();
  }

  Future<void> selectOperator(SCOperator op) async {
    selectedOperator = op; selectedType = null; labelTypes = [];
    notifyListeners();
    try { labelTypes = await _svc.getLabelTypes(op.name); }
    catch (e) { error = e.toString(); }
    notifyListeners();
  }

  void selectType(SCLabelType t) { selectedType = t; notifyListeners(); }

  Future<SCResumeData?> checkOrderResume(String nr) async {
    if (nr.trim().isEmpty) return null;
    checkingOrder = true; notifyListeners();
    try {
      final rows = await _svc.byOrder(nr.trim());
      if (rows.isEmpty) { checkingOrder = false; notifyListeners(); return null; }
      final first = rows.first;
      int maxSuffix = 0;
      for (final r in rows) {
        final sn = (r['serial_new'] ?? '').toString();
        final m = RegExp(r'(\d+)$').firstMatch(sn);
        if (m != null) {
          final v = int.tryParse(m.group(1)!) ?? 0;
          if (v > maxSuffix) maxSuffix = v;
        }
      }
      resumeData = SCResumeData(
        existingCount: rows.length,
        operador: first['usuario']?.toString(),
        sku: (first['nr_sku'] ?? '').toString(),
        totalUnits: (first['nr_unidades'] as num?)?.toInt(),
        tipoId: (first['tipo_etiqueta_id'] as num?)?.toInt(),
        tipoName: first['tipo_etiqueta']?.toString(),
        ean: (first['ean'] ?? '').toString(),
        nextSequence: maxSuffix + 1,
        lastBox: rows.last['nr_box']?.toString(),
        productionDate: _parseDate(first['fecha_creacion']),
      );
      checkingOrder = false; notifyListeners();
      return resumeData;
    } catch (e) {
      error = 'Resume: $e';
      checkingOrder = false; notifyListeners(); return null;
    }
  }

  void applyResume(SCResumeData rd) {
    if (rd.sku != null && rd.sku!.isNotEmpty) sku = rd.sku!;
    if (rd.totalUnits != null && rd.totalUnits! > 0) totalUnits = rd.totalUnits!;
    if (rd.ean != null && rd.ean!.isNotEmpty) ean = rd.ean!;
    startSequence = rd.nextSequence;
    if (rd.productionDate != null) productionDate = rd.productionDate!;
    if (rd.operador != null) {
      final m = operators.where((o) => o.name.toLowerCase() == rd.operador!.toLowerCase());
      if (m.isNotEmpty) selectedOperator = m.first;
    }
    if (rd.tipoId != null) {
      final t = labelTypes.where((lt) => lt.id == rd.tipoId);
      if (t.isNotEmpty) selectedType = t.first;
    }
    notifyListeners();
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try { return DateTime.parse(v.toString()); } catch (_) { return null; }
  }

  String? generateLabels() {
    if (selectedOperator == null || selectedType == null) return 'Selecciona operador y tipo';
    if (orderNbr.trim().isEmpty) return 'Introduce nº de orden';
    if (sku.trim().isEmpty) return 'Introduce el SKU';
    if (totalUnits <= 0) return 'Introduce unidades válidas';
    allLabels = LabelGenerator.generate(
      operatorName: selectedOperator!.name, date: productionDate, totalUnits: totalUnits,
      article: selectedType!.article, sapClient: selectedType!.sapClient,
      codeLetter: selectedType!.codeLetter, startSequence: startSequence,
    );
    consumedLabels = []; configLocked = true; step = SCStep.scan;
    notifyListeners(); return null;
  }

  List<String> get pendingLabels => allLabels.where((l) => !consumedLabels.contains(l)).toList();

  String? startBox(String boxNumber, int unitsPerBox) {
    if (boxNumber.trim().isEmpty) return 'Introduce nº de caja';
    if (unitsPerBox <= 0) return 'Introduce unidades válidas';
    final labels = pendingLabels.take(unitsPerBox).toList();
    if (labels.isEmpty) return 'No quedan etiquetas pendientes';
    activeBox = SCBoxSession(boxNumber: boxNumber.trim(), units: unitsPerBox, labels: labels);
    notifyListeners(); return null;
  }

  Future<String?> scanOldSerial(String oldSerial) async {
    if (activeBox == null) return 'No hay caja activa';
    if (activeBox!.isComplete) return 'Caja completa';
    final newLabel = activeBox!.currentLabel;
    if (newLabel == null) return 'Sin etiquetas';
    final trimmed = oldSerial.trim();
    if (trimmed.isEmpty) return 'Serial vacío';
    try {
      final id = await _svc.addRegistry({
        'nr_orden': orderNbr, 'nr_sku': sku, 'nr_unidades': totalUnits,
        'tipo_etiqueta': selectedType?.displayName, 'tipo_etiqueta_id': selectedType?.id,
        'nr_box': activeBox!.boxNumber, 'nr_unidades_box': activeBox!.units,
        'serial_old': trimmed, 'serial_new': newLabel, 'usuario': selectedOperator?.name,
        if (ean.isNotEmpty) 'ean': ean,
      });
      activeBox!.mappings.add(SCMapping(id: id, oldSerial: trimmed, newSerial: newLabel, scannedAt: DateTime.now()));
      notifyListeners();
      if (activeBox!.isComplete) _completeBox();
      return null;
    } catch (e) { return 'Error: $e'; }
  }

  void _completeBox() {
    if (activeBox == null) return;
    for (final m in activeBox!.mappings) consumedLabels.add(m.newSerial);
    completedBoxes.add(activeBox!); activeBox = null;
    step = pendingLabels.isEmpty ? SCStep.finish : SCStep.summary;
    notifyListeners();
  }

  void nextBox() { step = SCStep.scan; notifyListeners(); }

  Future<Map<String, dynamic>> printBox(SCBoxSession box, {String? printerIp, int? printerId}) {
    return _svc.print(
      printerIp: printerIp, printerId: printerId,
      snBatches: [box.mappings.map((m) => m.newSerial).toList()],
      serialBatches: [box.mappings.map((m) => m.oldSerial).toList()],
      data: box.boxNumber, orden: orderNbr, totalSerials: box.scannedCount,
      ean: ean.isNotEmpty ? ean : null,
    );
  }

  Future<String?> finishAndUpload() async {
    if (orderNbr.trim().isEmpty) return null;
    try {
      final r = await _svc.finishOrder(orderNbr.trim());
      return r['filename'] as String?;
    } catch (_) { return null; }
  }

  void reset() {
    step = SCStep.config; configLocked = false; allLabels = [];
    consumedLabels = []; activeBox = null; completedBoxes = [];
    error = null; resumeData = null; ean = ''; startSequence = 1;
    notifyListeners();
  }

  int get totalScanned => completedBoxes.fold(0, (s, b) => s + b.scannedCount) + (activeBox?.scannedCount ?? 0);
  double get progressPct => totalUnits > 0 ? totalScanned / totalUnits : 0;
}

