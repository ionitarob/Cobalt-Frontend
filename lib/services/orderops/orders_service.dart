import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import '../../models/orderops/agent_order.dart';

class OrdersPage {
  final int count;
  final int? nextOffset;
  final List<AgentOrder> results;
  const OrdersPage({required this.count, required this.results, this.nextOffset});
}

class OrdersService {
  OrdersService._();
  static final OrdersService instance = OrdersService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<List<AgentOrder>> getAgentOrders({
    String? agentStatus,
    int? isBlocked,
    String? department,
    int? includeSource,
    int? limit,
    String? search,
  }) async {
    final params = <String, String>{};
    if (agentStatus != null) params['agent_status'] = agentStatus;
    if (isBlocked != null) params['is_blocked'] = isBlocked.toString();
    if (department != null) params['department'] = department;
    if (includeSource != null) params['include_source'] = includeSource.toString();
    if (limit != null) params['limit'] = limit.toString();
    if (search != null && search.isNotEmpty) params['search'] = search;

    final resp = await _dio.get<dynamic>('/orderops/agent-orders', queryParameters: params);
    final body = resp.data;
    final list = body is Map ? (body['results'] as List? ?? []) : (body as List? ?? []);
    return list.map((e) => AgentOrder.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<OrdersPage> getAgentOrdersPage({
    String? agentStatus,
    int? isBlocked,
    String? department,
    String? estado,
    int? includeSource,
    int offset = 0,
    int limit = 200,
    String? search,
  }) async {
    final params = <String, String>{
      'offset': offset.toString(),
      'limit': limit.toString(),
    };
    if (agentStatus != null) params['agent_status'] = agentStatus;
    if (isBlocked != null) params['is_blocked'] = isBlocked.toString();
    if (department != null) params['department'] = department;
    if (estado != null) params['estado'] = estado;
    if (includeSource != null) params['include_source'] = includeSource.toString();
    if (search != null && search.isNotEmpty) params['search'] = search;

    final resp = await _dio.get<dynamic>('/orderops/agent-orders', queryParameters: params);
    final body = resp.data;
    if (body is Map) {
      return OrdersPage(
        count: (body['count'] as num?)?.toInt() ?? 0,
        nextOffset: (body['next_offset'] as num?)?.toInt(),
        results: (body['results'] as List? ?? [])
            .map((e) => AgentOrder.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    }
    final list = (body as List? ?? [])
        .map((e) => AgentOrder.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return OrdersPage(count: list.length, results: list);
  }

  Future<void> updateAgentOrder(
    int idnbr, {
    String? estado,
    bool? forceEstado,
    String? family,
    List<String>? subfamilies,
    String? prioridad,
    String? assignedTo,
    String? assignedToName,
    String? stopReason,
    bool? markCompleted,
    String? completionSummary,
    String? completionAuthor,
    int? proyectoId,
    String? department,
  }) async {
    final body = <String, dynamic>{};
    if (estado != null) body['estado'] = estado;
    if (forceEstado == true) body['force_estado'] = true;
    if (family != null) body['family'] = family;
    if (subfamilies != null) body['subfamilies'] = subfamilies.join(',');
    if (prioridad != null) body['prioridad'] = prioridad;
    if (assignedTo != null) body['assigned_to'] = assignedTo;
    if (assignedToName != null) body['assigned_to_name'] = assignedToName;
    if (stopReason != null) body['stop_reason'] = stopReason;
    if (markCompleted != null) body['mark_completed'] = markCompleted;
    if (completionSummary != null) body['completion_summary'] = completionSummary;
    if (completionAuthor != null) body['completion_author'] = completionAuthor;
    if (proyectoId != null) body['proyecto'] = proyectoId;
    if (department != null) body['department'] = department;

    await _dio.patch('/orderops/agent-orders/$idnbr/update', data: body);
  }

  Future<Map<String, dynamic>> bulkUpdateOrders(
    List<int> idnbrs, {
    String? family,
    List<String>? subfamilies,
    String? estado,
    String? prioridad,
    String? assignedTo,
    String? assignedToName,
    String? observation,
    bool forceEstado = false,
  }) async {
    final body = <String, dynamic>{'idnbrs': idnbrs};
    if (family != null) body['family'] = family;
    if (subfamilies != null) body['subfamilies'] = subfamilies;
    if (estado != null) body['estado'] = estado;
    if (prioridad != null) body['prioridad'] = prioridad;
    if (assignedTo != null) body['assigned_to'] = assignedTo;
    if (assignedToName != null) body['assigned_to_name'] = assignedToName;
    if (observation != null && observation.isNotEmpty) body['observation'] = observation;
    if (forceEstado) body['force_estado'] = true;

    final resp = await _dio.post<dynamic>('/orderops/agent-orders/bulk-update', data: body);
    return Map<String, dynamic>.from(resp.data as Map);
  }

  Future<void> runTriage(int idnbr) async {
    await _dio.post('/orderops/triage/run', data: {'idnbr': idnbr});
  }

  Future<void> restartAgentOrder(
    int idnbr, {
    bool runTriage = true,
    bool deleteAnsweredClarifications = false,
    String? author,
  }) async {
    final body = <String, dynamic>{
      'run_triage': runTriage,
      'delete_answered_clarifications': deleteAnsweredClarifications,
    };
    if (author != null) body['author'] = author;
    await _dio.post('/orderops/agent-orders/$idnbr/restart', data: body);
  }

  Future<Uint8List> exportOrdersExcel({String? start, String? end}) async {
    final params = <String, String>{};
    if (start != null) params['start'] = start;
    if (end != null) params['end'] = end;

    final resp = await _dio.get<List<int>>(
      '/orderops/export/orders',
      queryParameters: params,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(resp.data ?? []);
  }

  Future<List<String>> getCatalogFamilies() async {
    final resp = await _dio.get<dynamic>('/orderops/catalog/families');
    final data = resp.data;
    if (data is List) return data.map((e) => e.toString()).toList();
    return [];
  }

  Future<List<Map<String, dynamic>>> getEmployees({
    String q = '',
    int limit = 50,
  }) async {
    final params = <String, String>{'limit': limit.toString()};
    if (q.isNotEmpty) params['q'] = q;

    final resp = await _dio.get<dynamic>('/orderops/employees', queryParameters: params);
    final body = resp.data;
    final list = (body is Map ? body['results'] : body) as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
