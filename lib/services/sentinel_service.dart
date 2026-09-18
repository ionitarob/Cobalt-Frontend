import 'package:dio/dio.dart';
import '../core/api_client.dart';

class PhysicalTable {
  final int id;
  final String name;
  final List<TableSlot> slots;

  const PhysicalTable({
    required this.id,
    required this.name,
    required this.slots,
  });

  factory PhysicalTable.fromJson(Map<String, dynamic> j) {
    final raw = j['ports'] as List? ?? [];
    return PhysicalTable(
      id: j['id'] as int? ?? j['switch_id'] as int? ?? 0,
      name: j['name']?.toString() ?? '',
      slots: raw
          .map((p) => TableSlot.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList(),
    );
  }

  int get totalSlots => slots.length;
  int get completedSlots =>
      slots.where((s) => s.stage == 'completo').length;
  int get inProgressSlots =>
      slots.where((s) => s.stage == 'maquetando').length;
}

class TableSlot {
  final int id;
  final int portNumber;
  final String? connectedMac;
  final String? hostname;
  final String stage;
  final int? orderId;

  const TableSlot({
    required this.id,
    required this.portNumber,
    this.connectedMac,
    this.hostname,
    this.stage = 'libre',
    this.orderId,
  });

  factory TableSlot.fromJson(Map<String, dynamic> j) => TableSlot(
        id: j['id'] as int? ?? j['port_id'] as int? ?? 0,
        portNumber: j['port_number'] as int? ?? 0,
        connectedMac: j['connected_mac']?.toString(),
        hostname: j['hostname']?.toString(),
        stage: j['stage']?.toString() ?? 'libre',
        orderId: j['order_id'] as int?,
      );
}

class SentinelService {
  SentinelService._();
  static final SentinelService instance = SentinelService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<List<PhysicalTable>> getPhysicalTables(int idnbr) async {
    final resp = await _dio.get<dynamic>(
      '/sentinel/api/switches/',
      queryParameters: {'order_id': idnbr},
    );
    final body = resp.data;
    final list = body is List
        ? body
        : (body is Map ? (body['results'] as List? ?? []) : <dynamic>[]);
    return list
        .map((e) =>
            PhysicalTable.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> registerDevice(Map<String, dynamic> data) async {
    await _dio.post<dynamic>('/sentinel/api/devices/', data: data);
  }

  Future<void> updateDeviceStatus(int portId, String status) async {
    await _dio.patch<dynamic>(
      '/sentinel/api/ports/$portId/status/',
      data: {'stage': status},
    );
  }
}
