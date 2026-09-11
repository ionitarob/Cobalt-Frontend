import 'package:flutter_test/flutter_test.dart';
import 'package:configtool_cobalt/services/api_client.dart';

// Runs against a real Django backend (started by CI before this suite).
// Local: start the backend with GRANITE_USE_SQLITE=true python manage.py runserver
//        then run: flutter test test_integration/
void main() {
  late ApiClient client;

  setUpAll(() {
    client = ApiClient(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://127.0.0.1:8000',
      ),
    );
  });

  group('Health endpoint', () {
    test('returns 200 and status=ok', () async {
      final data = await client.health();
      expect(data['status'], equals('ok'));
    });

    test('returns correct service name', () async {
      final data = await client.health();
      expect(data['service'], equals('ConfigTool Cobalt'));
    });
  });
}
