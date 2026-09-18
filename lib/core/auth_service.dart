import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthUser {
  final int id;
  final String username;
  final String nombre;
  final String apellido;
  final String? turno;
  final int? empresaId;
  final String? role;

  const AuthUser({
    required this.id,
    required this.username,
    required this.nombre,
    required this.apellido,
    this.turno,
    this.empresaId,
    this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
        id: (j['id'] as num).toInt(),
        username: j['username'] as String,
        nombre: j['nombre'] as String? ?? '',
        apellido: j['apellido'] as String? ?? '',
        turno: j['turno'] as String?,
        empresaId: (j['empresa_id'] as num?)?.toInt(),
        role: j['role'] as String?,
      );

  String get displayName => '$nombre $apellido'.trim();
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _kRefresh = 'cobalt_refresh_token';
  // Fallback key used when keychain is unavailable (e.g. unsigned macOS debug)
  static const _kRefreshFallback = 'cobalt_refresh_token_fb';

  // Access token lives only in memory — never written to disk
  String? _accessToken;
  AuthUser? _currentUser;

  String? get accessToken => _accessToken;
  AuthUser? get currentUser => _currentUser;
  bool get isAuthenticated => _accessToken != null;

  void setStorageForTesting(FlutterSecureStorage s) => _storage = s;

  Future<void> persistSession({
    required String accessToken,
    required String refreshToken,
    required AuthUser user,
  }) async {
    _accessToken = accessToken;
    _currentUser = user;
    bool secureOk = false;
    try {
      await _storage.write(key: _kRefresh, value: refreshToken);
      secureOk = true;
    } catch (_) {}
    // Fall back to shared_preferences when keychain is unavailable
    if (!secureOk) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kRefreshFallback, refreshToken);
      } catch (_) {}
    }
  }

  Future<String?> getRefreshToken() async {
    // Secure storage first
    try {
      final t = await _storage.read(key: _kRefresh);
      if (t != null) return t;
    } catch (_) {}
    // Fallback
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kRefreshFallback);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSession() async {
    _accessToken = null;
    _currentUser = null;
    try {
      await _storage.delete(key: _kRefresh);
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kRefreshFallback);
    } catch (_) {}
  }
}
