import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/flavor.dart';

enum HealthStatus { checking, ok, degraded, unreachable }

class HealthService extends ChangeNotifier {
  static final HealthService instance = HealthService._();
  HealthService._();

  HealthStatus _status = HealthStatus.checking;
  String? _version;
  DateTime? _lastChecked;
  Timer? _timer;

  HealthStatus get status => _status;
  String? get version => _version;
  DateTime? get lastChecked => _lastChecked;

  static final _dio = Dio(BaseOptions(
    baseUrl: kApiBaseUrl,
    connectTimeout: const Duration(seconds: 4),
    receiveTimeout: const Duration(seconds: 4),
    sendTimeout: const Duration(seconds: 4),
  ));

  Future<void> check() async {
    _status = HealthStatus.checking;
    notifyListeners();
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/health/');
      final data = response.data ?? {};
      final raw = data['status'] as String? ?? '';
      _version = data['version'] as String?;
      _status = switch (raw) {
        'ok' => HealthStatus.ok,
        'degraded' => HealthStatus.degraded,
        _ => HealthStatus.unreachable,
      };
    } on DioException {
      _status = HealthStatus.unreachable;
    } catch (_) {
      _status = HealthStatus.unreachable;
    }
    _lastChecked = DateTime.now();
    notifyListeners();
  }

  void startPolling({Duration interval = const Duration(seconds: 30)}) {
    _timer?.cancel();
    check();
    _timer = Timer.periodic(interval, (_) => check());
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
