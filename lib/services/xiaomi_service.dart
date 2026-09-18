import 'package:dio/dio.dart';

import '../core/api_client.dart';

class XiaomiRegistro {
  final int id;
  final String cesb;
  final String sku;
  final String? partNumber;
  final int quantity;
  final int? cartons;
  final String? operario;
  final DateTime? fechaHoraRegistro;

  const XiaomiRegistro({
    required this.id,
    required this.cesb,
    required this.sku,
    this.partNumber,
    required this.quantity,
    this.cartons,
    this.operario,
    this.fechaHoraRegistro,
  });

  factory XiaomiRegistro.fromJson(Map<String, dynamic> json) => XiaomiRegistro(
        id: (json['id'] as num?)?.toInt() ?? 0,
        cesb: json['cesb']?.toString() ?? '',
        sku: json['sku']?.toString() ?? '',
        partNumber: json['partn']?.toString(),
        quantity: (json['qty'] as num?)?.toInt() ?? 0,
        cartons: (json['cartons'] as num?)?.toInt(),
        operario: json['operario']?.toString(),
        fechaHoraRegistro: json['fecha_hora_registro'] != null
            ? DateTime.tryParse(json['fecha_hora_registro'].toString())
            : null,
      );
}

class XiaomiCesbStatus {
  final String cesb;
  final bool valid;
  final String? statusLabel;

  const XiaomiCesbStatus({
    required this.cesb,
    required this.valid,
    this.statusLabel,
  });

  factory XiaomiCesbStatus.fromJson(Map<String, dynamic> json) =>
      XiaomiCesbStatus(
        cesb: json['cesb']?.toString() ?? '',
        valid: json['valid'] as bool? ?? false,
        statusLabel: json['status']?.toString(),
      );
}

class XiaomiService {
  XiaomiService._();
  static final XiaomiService instance = XiaomiService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<List<XiaomiRegistro>> getXiaomiRegistros(int idnbr) async {
    final resp = await _dio.get<dynamic>(
      '/xiaomieco/registros/',
      queryParameters: {'idnbr': idnbr},
    );
    final body = resp.data;
    final list = body is Map
        ? (body['results'] as List? ?? body['data'] as List? ?? [])
        : (body as List? ?? []);
    return list
        .map((e) => XiaomiRegistro.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<XiaomiRegistro> registerXiaomiUnit(Map<String, dynamic> data) async {
    final resp = await _dio.post<dynamic>(
      '/xiaomieco/add_xiaomieco',
      data: data,
    );
    final body = resp.data;
    if (body is Map && body['inserted'] is List && (body['inserted'] as List).isNotEmpty) {
      return XiaomiRegistro.fromJson(
        Map<String, dynamic>.from((body['inserted'] as List).first as Map),
      );
    }
    return XiaomiRegistro.fromJson(Map<String, dynamic>.from(body as Map));
  }

  Future<XiaomiCesbStatus> getXiaomiCesbStatus(String cesb) async {
    final resp = await _dio.post<dynamic>(
      '/xiaomieco/validar_cesb/',
      data: {'cesb': cesb},
    );
    final body = resp.data;
    if (body is Map) {
      return XiaomiCesbStatus.fromJson(Map<String, dynamic>.from(body));
    }
    return XiaomiCesbStatus(cesb: cesb, valid: resp.statusCode == 200);
  }
}
