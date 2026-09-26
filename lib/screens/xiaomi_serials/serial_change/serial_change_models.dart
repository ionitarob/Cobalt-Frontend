/// Models for the Serial Change (RMA) workflow.

class SCOperator {
  final String name;
  final int totalTypes;
  final int activeTypes;

  const SCOperator({required this.name, required this.totalTypes, required this.activeTypes});

  factory SCOperator.fromJson(Map<String, dynamic> j) => SCOperator(
    name: j['operador'] as String? ?? '',
    totalTypes: (j['tipos'] as num?)?.toInt() ?? 0,
    activeTypes: (j['activos'] as num?)?.toInt() ?? 0,
  );
}

class SCLabelType {
  final int? id;
  final String operatorName;
  final String? article;
  final String? sapClient;
  final String? codeLetter;
  final bool active;

  const SCLabelType({
    this.id, required this.operatorName, this.article,
    this.sapClient, this.codeLetter, this.active = true,
  });

  String get displayName => article ?? codeLetter ?? 'Tipo ${id ?? "?"}';

  factory SCLabelType.fromJson(Map<String, dynamic> j) => SCLabelType(
    id: (j['id'] as num?)?.toInt(),
    operatorName: j['operador'] as String? ?? '',
    article: j['articulo'] as String?,
    sapClient: j['sap_cliente'] as String?,
    codeLetter: j['codigo_letra'] as String?,
    active: j['activo'] == true,
  );
}

class SCPrinter {
  final int id;
  final String name;
  final String ip;

  const SCPrinter({required this.id, required this.name, required this.ip});

  factory SCPrinter.fromJson(Map<String, dynamic> j) => SCPrinter(
    id: (j['id_printer'] as num?)?.toInt() ?? 0,
    name: j['printer_name'] as String? ?? '',
    ip: j['ip_address'] as String? ?? '',
  );
}

class SCMapping {
  final int? id;
  String oldSerial;
  final String newSerial;
  final DateTime scannedAt;

  SCMapping({this.id, required this.oldSerial, required this.newSerial, required this.scannedAt});
}

class SCBoxSession {
  final String boxNumber;
  final int units;
  final List<String> labels;
  final List<SCMapping> mappings;
  final DateTime startTime;

  SCBoxSession({
    required this.boxNumber,
    required this.units,
    required this.labels,
  }) : mappings = [], startTime = DateTime.now();

  int get scannedCount => mappings.length;
  bool get isComplete => scannedCount >= units;
  String? get currentLabel => scannedCount < labels.length ? labels[scannedCount] : null;
}

/// Resume data extracted from existing server records.
class SCResumeData {
  final int existingCount;
  final String? operador;
  final String? sku;
  final int? totalUnits;
  final int? tipoId;
  final String? tipoName;
  final String? ean;
  final int nextSequence;
  final String? lastBox;
  final DateTime? productionDate;

  const SCResumeData({
    required this.existingCount,
    this.operador,
    this.sku,
    this.totalUnits,
    this.tipoId,
    this.tipoName,
    this.ean,
    required this.nextSequence,
    this.lastBox,
    this.productionDate,
  });
}

enum SCStep { config, scan, summary, finish }
