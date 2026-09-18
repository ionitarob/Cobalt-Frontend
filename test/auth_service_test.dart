import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

import 'package:configtool_cobalt/core/auth_service.dart';

// ---------------------------------------------------------------------------
// Minimal in-memory FlutterSecureStorage for tests
// ---------------------------------------------------------------------------

class _FakeStorage extends FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _data[key];

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _data.remove(key);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _FakeStorage fakeStorage;

  setUp(() {
    fakeStorage = _FakeStorage();
    AuthService.instance.setStorageForTesting(fakeStorage);
    // Reset in-memory state between tests
    AuthService.instance.clearSession();
  });

  group('AuthService — state', () {
    test('initially not authenticated', () {
      expect(AuthService.instance.isAuthenticated, isFalse);
      expect(AuthService.instance.accessToken, isNull);
      expect(AuthService.instance.currentUser, isNull);
    });

    test('persistSession stores tokens and user in memory', () async {
      final user = AuthUser.fromJson({
        'id': 1,
        'username': 'ana.garcia',
        'nombre': 'Ana',
        'apellido': 'Garcia',
        'turno': 'M',
        'empresa_id': 1,
        'role': 'operario',
      });

      await AuthService.instance.persistSession(
        accessToken: 'access-abc',
        refreshToken: 'refresh-xyz',
        user: user,
      );

      expect(AuthService.instance.isAuthenticated, isTrue);
      expect(AuthService.instance.accessToken, equals('access-abc'));
      expect(AuthService.instance.currentUser?.username, equals('ana.garcia'));
    });

    test('access token lives only in memory — not in storage', () async {
      await AuthService.instance.persistSession(
        accessToken: 'access-abc',
        refreshToken: 'refresh-xyz',
        user: AuthUser.fromJson({
          'id': 1, 'username': 'x', 'nombre': 'X', 'apellido': 'Y',
        }),
      );

      // Storage must NOT contain the access token
      final storedAccess = await fakeStorage.read(key: 'cobalt_access_token');
      expect(storedAccess, isNull);
    });

    test('refresh token is persisted to secure storage', () async {
      await AuthService.instance.persistSession(
        accessToken: 'access-abc',
        refreshToken: 'refresh-xyz',
        user: AuthUser.fromJson({
          'id': 1, 'username': 'x', 'nombre': 'X', 'apellido': 'Y',
        }),
      );

      final stored = await AuthService.instance.getRefreshToken();
      expect(stored, equals('refresh-xyz'));
    });

    test('clearSession removes access token from memory and refresh from storage', () async {
      await AuthService.instance.persistSession(
        accessToken: 'access-abc',
        refreshToken: 'refresh-xyz',
        user: AuthUser.fromJson({
          'id': 1, 'username': 'x', 'nombre': 'X', 'apellido': 'Y',
        }),
      );

      await AuthService.instance.clearSession();

      expect(AuthService.instance.isAuthenticated, isFalse);
      expect(AuthService.instance.accessToken, isNull);
      expect(await AuthService.instance.getRefreshToken(), isNull);
    });
  });

  group('AuthUser', () {
    test('fromJson maps all fields', () {
      final user = AuthUser.fromJson({
        'id': 42,
        'username': 'luis.ramos',
        'nombre': 'Luis',
        'apellido': 'Ramos',
        'turno': 'T',
        'empresa_id': 2,
        'role': 'admin',
      });

      expect(user.id, equals(42));
      expect(user.username, equals('luis.ramos'));
      expect(user.turno, equals('T'));
      expect(user.role, equals('admin'));
    });

    test('displayName concatenates nombre and apellido', () {
      final user = AuthUser.fromJson({
        'id': 1, 'username': 'x', 'nombre': 'Ana', 'apellido': 'Garcia',
      });
      expect(user.displayName, equals('Ana Garcia'));
    });

    test('fromJson handles null optional fields', () {
      final user = AuthUser.fromJson({
        'id': 1, 'username': 'x', 'nombre': 'X', 'apellido': 'Y',
      });
      expect(user.role, isNull);
      expect(user.turno, isNull);
      expect(user.empresaId, isNull);
    });
  });
}
