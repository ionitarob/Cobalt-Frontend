import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import '../../models/orderops/order_detail.dart';
import '../../models/orderops/order_task.dart';

class OrderDetailService {
  OrderDetailService._();
  static final OrderDetailService instance = OrderDetailService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<OrderOpsDetail> getOrderDetail(int idnbr) async {
    final resp = await _dio.get<dynamic>('/orderops/agent-orders/$idnbr/detail');
    return OrderOpsDetail.fromJson(Map<String, dynamic>.from(resp.data as Map));
  }

  Future<List<AgentOrderTask>> getOrderTasks(int idnbr) async {
    final resp = await _dio.get<dynamic>('/orderops/agent-orders/$idnbr/tasks');
    final list = resp.data is List
        ? resp.data as List
        : ((resp.data as Map?))?['results'] as List? ?? [];
    return list
        .map((e) => AgentOrderTask.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<AgentServiceAlert>> getServiceAlerts(int idnbr) async {
    final resp = await _dio.get<dynamic>('/orderops/service-alerts');
    final list = resp.data is List
        ? resp.data as List
        : ((resp.data as Map?))?['results'] as List? ?? [];
    return list
        .where((e) => (e as Map)['idnbr'] == idnbr)
        .map((e) => AgentServiceAlert.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<AgentOrderObservation> addObservation(int idnbr, String body) async {
    final resp = await _dio.post<dynamic>(
      '/orderops/agent-orders/$idnbr/observations',
      data: {'body': body},
    );
    return AgentOrderObservation.fromJson(
        Map<String, dynamic>.from(resp.data as Map));
  }

  Future<void> editObservation(int idnbr, int obsId, String newBody) async {
    await _dio.patch(
      '/orderops/agent-orders/$idnbr/observations/$obsId',
      data: {'body': newBody},
    );
  }

  Future<void> deleteObservation(int idnbr, int obsId) async {
    await _dio.delete('/orderops/agent-orders/$idnbr/observations/$obsId');
  }

  Future<AgentOrderPhoto> uploadFile(
    int idnbr, {
    required Uint8List bytes,
    required String fileName,
    required String scope,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
      'scope': scope,
    });
    final resp = await _dio.post<dynamic>(
      '/orderops/agent-orders/$idnbr/photos',
      data: formData,
    );
    return AgentOrderPhoto.fromJson(Map<String, dynamic>.from(resp.data as Map));
  }

  Future<void> deleteFile(int idnbr, int photoId) async {
    await _dio.delete('/orderops/agent-orders/$idnbr/photos/$photoId');
  }

  Future<AgentOrderTask> addTask(int idnbr, String titulo) async {
    final resp = await _dio.post<dynamic>(
      '/orderops/agent-orders/$idnbr/tasks',
      data: {'titulo': titulo},
    );
    return AgentOrderTask.fromJson(Map<String, dynamic>.from(resp.data as Map));
  }

  Future<void> deleteTask(int idnbr, int taskId) async {
    await _dio.delete('/orderops/tasks/$taskId');
  }

  Future<List<AgentOrderService>> getOrderServices(int idnbr) async {
    final resp = await _dio.get<dynamic>(
      '/orderops/agent-orders/$idnbr/services',
    );
    final list = resp.data is Map
        ? ((resp.data as Map)['results'] as List? ?? [])
        : (resp.data as List? ?? []);
    return list
        .map((e) =>
            AgentOrderService.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> addManualService(int idnbr, Map<String, dynamic> data) async {
    await _dio.post('/orderops/agent-orders/$idnbr/manual-services', data: data);
  }

  Future<void> removeManualService(int idnbr, int manualId) async {
    await _dio.delete('/orderops/agent-orders/$idnbr/manual-services/$manualId');
  }

  Future<void> updateServiceAlert(
      int idnbr, String sku, String status, String notes) async {
    await _dio.patch(
      '/orderops/agent-orders/$idnbr/service-alerts/$sku',
      data: {'status': status, 'notes': notes},
    );
  }

  Future<List<Map<String, dynamic>>> searchCatalogServices(String q) async {
    final resp = await _dio.get<dynamic>(
      '/orderops/catalog/services',
      queryParameters: {'q': q},
    );
    final list = resp.data is List
        ? resp.data as List
        : ((resp.data as Map?))?['results'] as List? ?? [];
    return list
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
}
