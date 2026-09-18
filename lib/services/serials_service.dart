import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../core/api_client.dart';

class SerialsService {
  SerialsService._();
  static final SerialsService instance = SerialsService._();

  Dio get _dio => ApiClient.instance.dio;

  static const String _base = '/serials';

  Future<Map<String, dynamic>> assignSerial(
      String orderNbr, String serial) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '$_base/serial-to-inventory/ensure',
      data: {'serial': serial, 'num_orden': orderNbr},
    );
    return res.data ?? {};
  }

  Future<Map<String, dynamic>> matchSerials(
      String orderNbr, String serial, String inventoryCode) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '$_base/match',
      data: {
        'num_orden': orderNbr,
        'serial': serial,
        'inventory_code': inventoryCode,
      },
    );
    return res.data ?? {};
  }

  Future<Map<String, dynamic>> uploadSerials(
      Uint8List bytes, String fileName) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final res = await _dio.post<Map<String, dynamic>>(
      '$_base/import-orders',
      data: formData,
    );
    return res.data ?? {};
  }

  Future<List<Map<String, String?>>> getRecentSerials(String orderNbr) async {
    final encoded = Uri.encodeQueryComponent(orderNbr);
    final res = await _dio.get<List<dynamic>>(
      '$_base/mappings?num_orden=$encoded&limit=50',
    );
    final raw = res.data ?? [];
    return raw.whereType<Map>().map<Map<String, String?>>((e) {
      return {
        'serial': e['serial']?.toString(),
        'inventory_code': e['inventory_code']?.toString(),
        'assigned_at': e['assigned_at']?.toString(),
      };
    }).toList();
  }
}
