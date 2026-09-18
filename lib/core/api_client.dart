import 'package:dio/dio.dart';
import 'auth_service.dart';

const _kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://cobalt-staging.eba-2efgir7w.eu-west-3.elasticbeanstalk.com',
);

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  late final Dio dio = _buildDio();

  Dio _buildDio() {
    final d = Dio(BaseOptions(
      baseUrl: _kBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {'Content-Type': 'application/json'},
    ));
    d.interceptors.add(_AuthInterceptor(d));
    return d;
  }
}

class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;

  _AuthInterceptor(this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = AuthService.instance.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only intercept 401s that are not themselves auth calls
    final path = err.requestOptions.path;
    final is401 = err.response?.statusCode == 401;
    final isAuthEndpoint = path.contains('/api/auth/');

    if (!is401 || isAuthEndpoint || _isRefreshing) {
      handler.next(err);
      return;
    }

    _isRefreshing = true;
    try {
      final refreshToken = await AuthService.instance.getRefreshToken();
      if (refreshToken == null) {
        await AuthService.instance.clearSession();
        handler.next(err);
        return;
      }

      final resp = await _dio.post(
        '/api/auth/refresh/',
        data: {'refresh_token': refreshToken},
      );
      final body = resp.data as Map<String, dynamic>;
      await AuthService.instance.persistSession(
        accessToken: body['access_token'] as String,
        refreshToken: body['refresh_token'] as String,
        user: AuthUser.fromJson(body['user'] as Map<String, dynamic>),
      );

      // Retry original request with new token
      final opts = err.requestOptions;
      opts.headers['Authorization'] =
          'Bearer ${AuthService.instance.accessToken}';
      final retried = await _dio.fetch(opts);
      handler.resolve(retried);
    } on DioException {
      await AuthService.instance.clearSession();
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }
}
