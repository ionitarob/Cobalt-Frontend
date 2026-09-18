import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/api_client.dart';

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  Dio get _dio => ApiClient.instance.dio;

  /// Streams SSE events from the SFTP/MSSQL order ingest endpoint.
  /// Each emitted map has the shape the server sends as JSON data lines.
  Stream<Map<String, dynamic>> ingestOrders() async* {
    final resp = await _dio.post<ResponseBody>(
      '/amz/orders/ingest',
      options: Options(responseType: ResponseType.stream),
    );

    final stream = resp.data!.stream;
    String buffer = '';

    await for (final chunk in stream) {
      buffer += utf8.decode(chunk);
      final lines = buffer.split('\n');
      // Keep incomplete last line in buffer
      buffer = lines.removeLast();

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('data: ')) {
          final data = trimmed.substring(6).trim();
          if (data.isNotEmpty) {
            try {
              yield json.decode(data) as Map<String, dynamic>;
            } catch (_) {
              // Skip malformed lines
            }
          }
        }
      }
    }

    // Process any remaining buffered line
    if (buffer.trim().startsWith('data: ')) {
      final data = buffer.trim().substring(6).trim();
      if (data.isNotEmpty) {
        try {
          yield json.decode(data) as Map<String, dynamic>;
        } catch (_) {}
      }
    }
  }
}
