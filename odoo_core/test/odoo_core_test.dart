import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:odoo_core/odoo_core.dart';

import '../example/runbot_models.dart';

// 1. Mock the client for testing to respect clean architecture
class MockOdooClient implements OdooClient {
  final dynamic mockResponse;
  final Exception? throwException;

  MockOdooClient({this.mockResponse, this.throwException});

  @override
  Future<dynamic> callKwRaw({
    required String model,
    required String method,
    List args = const [],
    Map<String, dynamic> kwargs = const {},
  }) async {
    if (throwException != null) throw throwException!;
    return mockResponse;
  }
}

void main() {
  group('1. OdooException Parsing', () {
    test('Parse intelligently from deep data.message', () {
      final json = {
        'code': 100,
        'message': 'Odoo Server Error',
        'data': {
          'message': 'Validation details: name can not be empty',
          'type': 'server_exception'
        }
      };
      final ex = OdooException.fromJson(json);
      expect(ex.code, 100);
      expect(ex.message, 'Validation details: name can not be empty');
      expect(ex.data?['type'], 'server_exception');
    });

    test('Parse from root message fallback', () {
      final json = {'code': 300, 'message': 'Session expired'};
      final ex = OdooException.fromJson(json);
      expect(ex.message, 'Session expired');
    });

    test('Parse with no data handles defaults', () {
      final json = <String, dynamic>{};
      final ex = OdooException.fromJson(json);
      expect(ex.message, 'Unknown Odoo error');
      expect(ex.code, 0);
    });
  });

  group('2. OdooRepository CRUD Tests', () {
    test('searchFetch decodes correctly into models', () async {
      final client = MockOdooClient(mockResponse: {
        'records': [
          {
            'id': 1,
            'name': 'John Doe',
            'create_uid': [2, 'Admin']
          },
        ],
        'length': 1,
      });
      final repo = EmployeeRepository(client: client);

      final res = await repo.searchFetch();
      expect(res.records, isNotEmpty);
      expect(res.length, equals(1));

      final emp = res.records.first;
      expect(emp.name, equals('John Doe'));
      expect(emp.createUid, equals(2)); // Verifying the parsed many2one ID
    });

    test('searchFetch handles empty lists', () async {
      final client = MockOdooClient(mockResponse: {'records': [], 'length': 0});
      final repo = EmployeeRepository(client: client);
      final res = await repo.searchFetch();
      expect(res.records, isEmpty);
      expect(res.length, equals(0));
    });

    test('searchIds returns list of integers', () async {
      final client = MockOdooClient(mockResponse: [1, 2, 3]);
      final repo = EmployeeRepository(client: client);
      final ids = await repo.searchIds();
      expect(ids.length, 3);
      expect(ids[1], 2);
    });

    test('read correctly maps to objects', () async {
      final client = MockOdooClient(mockResponse: [
        {'id': 1, 'name': 'Emp 1'},
        {'id': 2, 'name': 'Emp 2'}
      ]);
      final repo = EmployeeRepository(client: client);

      final records = await repo.read([1, 2]);
      expect(records, hasLength(2));
      expect(records.last.name, 'Emp 2');
    });

    test('read with empty ids returns immediately', () async {
      final repo = EmployeeRepository(client: MockOdooClient());
      final records = await repo.read([]);
      expect(records, isEmpty);
    });

    test('create returns new database ID', () async {
      final client = MockOdooClient(mockResponse: 99);
      final repo = EmployeeRepository(client: client);
      final newId = await repo.create({'name': 'Jane Doe'});
      expect(newId, equals(99));
    });

    test('write returns boolean success flag', () async {
      final client = MockOdooClient(mockResponse: true);
      final repo = EmployeeRepository(client: client);
      final success = await repo.write([99], {'name': 'Updated'});
      expect(success, isTrue);
    });

    test('write with empty ids returns true instantly', () async {
      final repo = EmployeeRepository(client: MockOdooClient());
      final success = await repo.write([], {'name': 'Updated'});
      expect(success, isTrue);
    });

    test('unlink returns boolean success flag', () async {
      final client = MockOdooClient(mockResponse: true);
      final repo = EmployeeRepository(client: client);
      final success = await repo.unlink([99]);
      expect(success, isTrue);
    });

    test('unlink with empty ids returns true instantly', () async {
      final repo = EmployeeRepository(client: MockOdooClient());
      final success = await repo.unlink([]);
      expect(success, isTrue);
    });

    test('webSave correctly maps response to typed objects', () async {
      final client = MockOdooClient(mockResponse: [
        {'id': 99, 'name': 'Jane Doe Modified'}
      ]);
      final repo = EmployeeRepository(client: client);

      final returnedObjects = await repo.webSave(
        ids: [99],
        values: {'name': 'Jane Doe Modified'},
      );
      expect(returnedObjects.length, 1);
      expect(returnedObjects.first.name, 'Jane Doe Modified');
    });

    test('Repository propagates exceptions', () async {
      final client = MockOdooClient(
          throwException: OdooException(code: 500, message: 'Server Failed'));
      final repo = EmployeeRepository(client: client);

      expect(
          () async => await repo.searchFetch(),
          throwsA(isA<OdooException>()
              .having((e) => e.message, 'message', 'Server Failed')));
    });
  });

  group('3. Integration Tests (RunBot API)', () {
    test('Authenticate and perform full CRUD on res.partner', () async {
      // Setup Dio with interceptors like in example
      const baseUrl = 'https://106987691-18-0-all.runbot303.odoo.com';
      final dio = Dio(BaseOptions(baseUrl: baseUrl));

      String? sessionId;
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (sessionId != null) {
            options.headers['Cookie'] = sessionId;
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          final cookies = response.headers['set-cookie'];
          if (cookies != null) {
            for (var cookie in cookies) {
              if (cookie.contains('session_id')) {
                sessionId = cookie.split(';').first;
              }
            }
          }
          return handler.next(response);
        },
      ));

      final odooClient = OdooRpcService(dio: dio);

      // 1. Authenticate
      final authResponse = await odooClient.callRpc<Map<String, dynamic>>(
        path: '/web/session/authenticate',
        params: {
          'db': '106987691-18-0-all',
          'login': 'admin',
          'password': 'admin'
        },
        fromJsonT: (json) => json as Map<String, dynamic>,
      );

      expect(authResponse.error, isNull);
      expect(authResponse.result?['uid'], isNotNull);

      final partnerRepo = PartnerRepository(client: odooClient);

      // 2. CREATE
      final newPartnerId = await partnerRepo.create({
        'name': 'Dart Integration Test',
        'email': 'test@dart-odoo.dev',
        'phone': '555-1234'
      });
      expect(newPartnerId, isA<int>());

      // 3. READ
      final readRecords = await partnerRepo.read([newPartnerId]);
      expect(readRecords, isNotEmpty);
      expect(readRecords.first.name, 'Dart Integration Test');

      // 4. WRITE
      final writeSuccess =
          await partnerRepo.write([newPartnerId], {'phone': '555-9876'});
      expect(writeSuccess, isTrue);

      // 5. WEBSAVE

      final webSavedRecords = await partnerRepo.webSave(
        ids: [newPartnerId],
        values: {'name': 'Dart Integration Test V2'},
      );
      expect(webSavedRecords.first.name, 'Dart Integration Test V2');
      expect(webSavedRecords.first.phone, '555-9876');

      // 6. UNLINK
      final unlinkSuccess = await partnerRepo.unlink([newPartnerId]);
      expect(unlinkSuccess, isTrue);
    },
        skip:
            'Real API test depends on ephemeral runbot URL. Actualízala para ejecutar.');
  });
}
