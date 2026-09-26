import 'package:dio/dio.dart';
import '../../../core/api_client.dart';

/// API client for serial-change history (search, edit, delete).
class SerialHistoryService {
  SerialHistoryService._();
  static final instance = SerialHistoryService._();
  Dio get _dio => ApiClient.instance.dio;

  Future<List<Map<String, dynamic>>> search({String? serial, String? nrOrden, String? nrBox, String? q, int limit = 2000}) async {
    final qp = <String, dynamic>{'limit': limit};
    if (serial != null && serial.isNotEmpty) qp['serial'] = serial;
    if (nrOrden != null && nrOrden.isNotEmpty) qp['nr_orden'] = nrOrden;
    if (nrBox != null && nrBox.isNotEmpty) qp['nr_box'] = nrBox;
    if (q != null && q.isNotEmpty && qp.length == 1) qp['q'] = q;
    final r = await _dio.get<dynamic>('/serials/sc/search', queryParameters: qp);
    return ((r.data as Map)['results'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> list({int limit = 500}) async {
    final r = await _dio.get<dynamic>('/serials/sc/list', queryParameters: {'limit': limit});
    return ((r.data as Map)['results'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<int> delete(int id) async {
    final r = await _dio.delete<dynamic>('/serials/sc/$id');
    final data = r.data;
    if (data is Map) return (data['deleted'] as int?) ?? 1;
    return 1;
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    await _dio.put('/serials/sc/$id', data: data);
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
