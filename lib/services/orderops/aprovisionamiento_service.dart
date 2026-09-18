import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import '../../models/orderops/aprovisionamiento.dart';

class AprovisionamientoService {
  AprovisionamientoService._();
  static final AprovisionamientoService instance = AprovisionamientoService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<List<AprovisionamientoRecord>> getAll() async {
    final resp = await _dio.get<dynamic>('/orderops/aprovisionamiento');
    final list = resp.data as List? ?? [];
    return list
        .map((e) => AprovisionamientoRecord.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<AprovisionamientoRecord> create({
    required String customer,
    String? orderNbr,
    String? notas,
    String? family,
    String? prioridad,
    String? assignedTo,
    String? assignedToName,
    bool autoApply = true,
  }) async {
    final body = <String, dynamic>{'customer': customer, 'auto_apply': autoApply};
    if (orderNbr != null && orderNbr.isNotEmpty) body['order_nbr'] = orderNbr;
    if (notas != null && notas.isNotEmpty) body['notas'] = notas;
    if (family != null && family.isNotEmpty) body['family'] = family;
    if (prioridad != null && prioridad.isNotEmpty) body['prioridad'] = prioridad;
    if (assignedTo != null && assignedTo.isNotEmpty) body['assigned_to'] = assignedTo;
    if (assignedToName != null && assignedToName.isNotEmpty) body['assigned_to_name'] = assignedToName;

    final resp = await _dio.post<dynamic>('/orderops/aprovisionamiento', data: body);
    return AprovisionamientoRecord.fromJson(Map<String, dynamic>.from(resp.data as Map));
  }

  Future<AprovisionamientoRecord> update(
    int id, {
    String? customer,
    String? orderNbr,
    String? notas,
    String? family,
    String? prioridad,
    String? assignedTo,
    String? assignedToName,
    bool? autoApply,
  }) async {
    final body = <String, dynamic>{};
    if (customer != null) body['customer'] = customer;
    if (orderNbr != null) body['order_nbr'] = orderNbr;
    if (notas != null) body['notas'] = notas;
    if (family != null) body['family'] = family;
    if (prioridad != null) body['prioridad'] = prioridad;
    if (assignedTo != null) body['assigned_to'] = assignedTo;
    if (assignedToName != null) body['assigned_to_name'] = assignedToName;
    if (autoApply != null) body['auto_apply'] = autoApply;

    final resp = await _dio.patch<dynamic>('/orderops/aprovisionamiento/$id', data: body);
    return AprovisionamientoRecord.fromJson(Map<String, dynamic>.from(resp.data as Map));
  }

  Future<void> delete(int id) async {
    await _dio.delete('/orderops/aprovisionamiento/$id');
  }

  Future<Map<String, dynamic>> link(int id, {required String orderNbr}) async {
    final resp = await _dio.post<dynamic>(
      '/orderops/aprovisionamiento/$id/link',
      data: {'order_nbr': orderNbr},
    );
    return Map<String, dynamic>.from(resp.data as Map);
  }

  // ── Tasks ──────────────────────────────────────────────────────────────

  Future<AprovisionamientoTask> addTask(int recordId, String titulo) async {
    final resp = await _dio.post<dynamic>(
      '/orderops/aprovisionamiento/$recordId/tasks',
      data: {'titulo': titulo},
    );
    return AprovisionamientoTask.fromJson(Map<String, dynamic>.from(resp.data as Map));
  }

  Future<void> toggleTask(int recordId, int taskId, bool done) async {
    await _dio.patch(
      '/orderops/aprovisionamiento/$recordId/tasks/$taskId',
      data: {'done': done},
    );
  }

  Future<void> deleteTask(int recordId, int taskId) async {
    await _dio.delete('/orderops/aprovisionamiento/$recordId/tasks/$taskId');
  }
}
