import 'package:dio/dio.dart';

import '../core/api_client.dart';

class ServerRegistroService {
  ServerRegistroService._();
  static final ServerRegistroService instance = ServerRegistroService._();

  Dio get _dio => ApiClient.instance.dio;

  static const _base = '/orderops/servers';

  Future<List<Map<String, dynamic>>> getServidoresByOrder(int idnbr) async {
    final resp = await _dio.get<dynamic>(
      '$_base/',
      queryParameters: {'idnbr': idnbr},
    );
    final data = resp.data;
    final list = data is Map
        ? (data['results'] as List? ?? [])
        : (data as List? ?? []);
    return list
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> registerServidor(
      Map<String, dynamic> data) async {
    final resp = await _dio.post<dynamic>('$_base/', data: data);
    return Map<String, dynamic>.from(resp.data as Map);
  }

  Future<void> deleteServidor(int id) async {
    await _dio.delete<dynamic>('$_base/$id/');
  }
}
