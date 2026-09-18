import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';

import '../core/api_client.dart';

class SerigrafiaStandard {
  final int? id;
  final String name;
  final String url;
  final List<String> variables;
  final String? image;

  const SerigrafiaStandard({
    this.id,
    required this.name,
    required this.url,
    required this.variables,
    this.image,
  });

  factory SerigrafiaStandard.fromJson(Map<String, dynamic> j) =>
      SerigrafiaStandard(
        id: j['id'] as int?,
        name: j['name'] as String,
        url: j['url'] as String,
        variables: List<String>.from(j['variables'] ?? []),
        image: j['image'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'url': url,
        'variables': variables,
        if (image != null) 'image': image,
      };
}

class SerigrafiaService {
  SerigrafiaService._();
  static final SerigrafiaService instance = SerigrafiaService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<List<SerigrafiaStandard>> getStandards() async {
    final resp = await _dio.get<dynamic>('/orderops/serigrafia/standards');
    final data = resp.data;
    List<dynamic> results = [];
    if (data is Map && data.containsKey('results')) {
      results = data['results'] as List? ?? [];
    } else if (data is List) {
      results = data;
    }
    return results
        .map((j) => SerigrafiaStandard.fromJson(
            Map<String, dynamic>.from(j as Map)))
        .toList();
  }

  Future<void> saveStandard(SerigrafiaStandard s) async {
    if (s.id != null) {
      await _dio.put('/orderops/serigrafia/standards/${s.id}',
          data: s.toJson());
    } else {
      await _dio.post('/orderops/serigrafia/standards', data: s.toJson());
    }
  }

  Future<void> deleteStandard(int id) async {
    await _dio.delete('/orderops/serigrafia/standards/$id');
  }

  Future<bool> uploadExcel(
      int idnbr, Uint8List bytes, String fileName) async {
    final formData = FormData.fromMap({
      'overwrite': 'true',
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final resp = await _dio.post(
      '/orderops/agent-orders/$idnbr/photos',
      data: formData,
    );
    return (resp.statusCode ?? 0) < 300;
  }

  Future<bool> saveRegistry(
    int idnbr,
    String labelName,
    Map<String, String> data, {
    String? operator,
  }) async {
    String? ci;
    String? serial;
    for (final key in data.keys) {
      final upper = key.toUpperCase();
      if (upper == 'CI' || upper == 'CI_CODE') ci = data[key];
      if (upper == 'SERIAL') serial = data[key];
    }
    final payload = <String, dynamic>{
      'idnbr': idnbr,
      'label_name': labelName,
      'data': jsonEncode(data),
      if (operator != null) 'operator': operator,
      if (ci != null) 'ci': ci,
      if (serial != null) 'serial': serial,
    };
    final resp =
        await _dio.post('/orderops/serigrafia/registry', data: payload);
    return (resp.statusCode ?? 0) < 300;
  }

  Future<List<Map<String, dynamic>>> getRegistries(
    int idnbr, {
    String? labelName,
    bool includeProject = false,
  }) async {
    final params = <String, String>{'idnbr': idnbr.toString()};
    if (labelName != null) params['label_name'] = labelName;
    if (includeProject) params['include_project'] = 'true';
    final resp = await _dio.get<dynamic>(
      '/orderops/serigrafia/registries',
      queryParameters: params,
    );
    final data = resp.data;
    List<dynamic> results = [];
    if (data is Map && data.containsKey('results')) {
      results = data['results'] as List? ?? [];
    } else if (data is List) {
      results = data;
    }
    return results
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<bool> updateRegistry(int id, Map<String, dynamic> data) async {
    final resp =
        await _dio.put('/orderops/serigrafia/registry/$id', data: data);
    return (resp.statusCode ?? 0) < 300;
  }

  Future<bool> deleteRegistry(int id) async {
    final resp = await _dio.delete('/orderops/serigrafia/registry/$id');
    return (resp.statusCode ?? 0) < 300;
  }

  Future<Excel?> downloadAndParseExcel(String filePath) async {
    try {
      final cleanPath =
          filePath.startsWith('/') ? filePath.substring(1) : filePath;
      final cacheBuster = DateTime.now().millisecondsSinceEpoch;
      final resp = await _dio.get<List<int>>(
        '/uploads/$cleanPath?t=$cacheBuster',
        options: Options(responseType: ResponseType.bytes),
      );
      if (resp.data == null) return null;
      return Excel.decodeBytes(resp.data!);
    } catch (e, st) {
      debugPrint('SerigrafiaService.downloadAndParseExcel: $e\n$st');
      rethrow;
    }
  }

  List<String> getExcelHeaders(Excel excel) {
    try {
      if (excel.sheets.isEmpty) return [];
      final sheet = excel.sheets.values.first;
      if (sheet.maxRows == 0 || sheet.rows.isEmpty) return [];
      return sheet.rows.first
          .map((c) => c?.value?.toString().trim() ?? '')
          .toList();
    } catch (e) {
      debugPrint('SerigrafiaService.getExcelHeaders: $e');
      return [];
    }
  }

  Future<bool> printLabel(
    SerigrafiaStandard standard,
    Map<String, String> values,
  ) async {
    final isAbsolute = standard.url.startsWith('http://') ||
        standard.url.startsWith('https://');
    final Response<dynamic> resp;
    if (isAbsolute) {
      resp = await _dio.post('/orderops/serigrafia/print', data: {
        'url': standard.url,
        'label_name': standard.name,
        'data': values,
        ...values,
      });
    } else {
      resp = await _dio.post(standard.url, data: values);
    }
    return (resp.statusCode ?? 0) < 300;
  }

  Future<String?> getNextInventoryCode() async {
    final resp = await _dio.get<dynamic>('/serials/claim');
    final data = resp.data;
    if (data is Map) return data['inventory_code'] as String?;
    return null;
  }
}
