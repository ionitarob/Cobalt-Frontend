import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import 'serial_change_models.dart';

/// API client for /serials/sc/* endpoints.
class SerialChangeService {
  SerialChangeService._();
  static final instance = SerialChangeService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<List<SCOperator>> getOperators() async {
    final r = await _dio.get<dynamic>('/serials/sc/operators');
    final list = (r.data as Map)['results'] as List? ?? [];
    return list.map((e) => SCOperator.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<SCLabelType>> getLabelTypes(String operador) async {
    final r = await _dio.get<dynamic>('/serials/sc/label-types', queryParameters: {'operador': operador});
    final list = (r.data as Map)['results'] as List? ?? [];
    return list.map((e) => SCLabelType.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<int?> addRegistry(Map<String, dynamic> data) async {
    final r = await _dio.post<dynamic>('/serials/sc/registry', data: data);
    return (r.data as Map?)?['id'] as int?;
  }

  /// All rows for an order — no limit. Used by order-resume.
  Future<List<Map<String, dynamic>>> byOrder(String nrOrden) async {
    final r = await _dio.get<dynamic>('/serials/sc/by-order', queryParameters: {'nr_orden': nrOrden});
    final list = (r.data as Map)['results'] as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<SCPrinter>> getPrinters({String? q}) async {
    final r = await _dio.get<dynamic>('/serials/sc/printers', queryParameters: {if (q != null) 'q': q});
    final list = (r.data as Map)['results'] as List? ?? [];
    return list.map((e) => SCPrinter.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// Server-side label generation.
  Future<Map<String, dynamic>> generateLabels({
    required String operador,
    required String articulo,
    required int units,
    required String fecha,
    int startSeq = 1,
    int? tipoId,
  }) async {
    final r = await _dio.post<dynamic>('/serials/sc/generate-labels', data: {
      'operador': operador,
      'articulo': articulo,
      'nr_unidades': units,
      'fecha': fecha,
      'inicio': startSeq,
      if (tipoId != null) 'tipo_id': tipoId,
    });
    return Map<String, dynamic>.from(r.data as Map);
  }

  /// ZPL print to local printer.
  Future<Map<String, dynamic>> print({
    String? printerIp,
    int? printerId,
    required List<List<String>> snBatches,
    required List<List<String>> serialBatches,
    String? data,
    String? orden,
    int? totalSerials,
    String? ean,
    int labelCounter = 1,
  }) async {
    final r = await _dio.post<dynamic>('/serials/sc/print', data: {
      if (printerIp != null) 'printer_ip': printerIp,
      if (printerId != null) 'printer_id': printerId,
      'sn_batches': snBatches,
      'serial_batches': serialBatches,
      if (data != null) 'data': data,
      if (orden != null) 'orden': orden,
      if (totalSerials != null) 'total_serials': totalSerials,
      if (ean != null) 'ean': ean,
      'label_counter': labelCounter,
    });
    return Map<String, dynamic>.from(r.data as Map);
  }

  /// SFTP upload (generates Excel + uploads).
  Future<Map<String, dynamic>> finishOrder(String nrOrden) async {
    final r = await _dio.post<dynamic>('/serials/sc/finish-order', data: {'nr_orden': nrOrden});
    return Map<String, dynamic>.from(r.data as Map);
  }

  /// Check SFTP file exists.
  Future<bool> checkSftp(String filename) async {
    final r = await _dio.get<dynamic>('/serials/sc/check-sftp', queryParameters: {'filename': filename});
    return (r.data as Map)['exists'] == true;
  }

  /// Create label type.
  Future<Map<String, dynamic>> addLabelType({
    required String operador,
    required String articulo,
    String? codigoLetra,
    String? sapCliente,
  }) async {
    final r = await _dio.post<dynamic>('/serials/sc/label-type/add', data: {
      'operador': operador,
      'articulo': articulo,
      if (codigoLetra != null) 'codigo_letra': codigoLetra,
      if (sapCliente != null) 'sap_cliente': sapCliente,
    });
    return Map<String, dynamic>.from(r.data as Map);
  }

  /// Delete label type.
  Future<void> eraseLabelType({int? id, String? operador, String? articulo}) async {
    await _dio.post<dynamic>('/serials/sc/label-type/erase', data: {
      if (id != null) 'id': id,
      if (operador != null) 'operador': operador,
      if (articulo != null) 'articulo': articulo,
    });
  }

  /// Export order as xlsx bytes.
  Future<List<int>> exportOrder(String nrOrden) async {
    final r = await _dio.get<List<int>>(
      '/serials/sc/export',
      queryParameters: {'nr_orden': nrOrden},
      options: Options(responseType: ResponseType.bytes),
    );
    return r.data ?? [];
  }
}
