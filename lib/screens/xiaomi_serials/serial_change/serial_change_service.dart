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

  Future<List<Map<String, dynamic>>> listByOrder(String nrOrden) async {
    final r = await _dio.get<dynamic>('/serials/sc/list', queryParameters: {'nr_orden': nrOrden});
    final list = (r.data as Map)['results'] as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<SCPrinter>> getPrinters({String? q}) async {
    final r = await _dio.get<dynamic>('/serials/sc/printers', queryParameters: {if (q != null) 'q': q});
    final list = (r.data as Map)['results'] as List? ?? [];
    return list.map((e) => SCPrinter.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }
}
