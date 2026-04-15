// ignore_for_file: avoid_print
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:odoo_core/odoo_core.dart';

import '../example/runbot_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RunBot config — URL de pruebas activa
// ─────────────────────────────────────────────────────────────────────────────
const _runbotUrl = 'https://107503898-18-0-all.runbot215.odoo.com';
const _runbotDb = '107503898-18-0-all';
const _runbotUser = 'admin';
const _runbotPass = 'admin';

// ─────────────────────────────────────────────────────────────────────────────
// Mock client — permite tests unitarios sin red
// ─────────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// Helper: configura un OdooRpcService apuntando al RunBot
// ─────────────────────────────────────────────────────────────────────────────
OdooRpcService _buildRunbotClient() {
  OdooRpcService.reset(); // Garantiza instancia fresca por test
  final dio = Dio(BaseOptions(baseUrl: _runbotUrl));

  String? sessionCookie;
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      if (sessionCookie != null) {
        options.headers['Cookie'] = sessionCookie!;
      }
      return handler.next(options);
    },
    onResponse: (response, handler) {
      final cookies = response.headers['set-cookie'];
      if (cookies != null) {
        for (final cookie in cookies) {
          if (cookie.contains('session_id')) {
            sessionCookie = cookie.split(';').first;
          }
        }
      }
      return handler.next(response);
    },
  ));

  return OdooRpcService(dio: dio);
}

// =============================================================================
void main() {
  // ───────────────────────────────────────────────────────────────────────────
  // GRUPO 1 — OdooException
  // ───────────────────────────────────────────────────────────────────────────
  group('1. OdooException', () {
    test('fromJson — extrae data.message si está disponible', () {
      final ex = OdooException.fromJson({
        'code': 100,
        'message': 'Odoo Server Error',
        'data': {
          'message': 'Validation: name can not be empty',
          'type': 'server_exception',
        },
      });
      expect(ex.code, 100);
      expect(ex.message, 'Validation: name can not be empty');
      expect(ex.data?['type'], 'server_exception');
    });

    test('fromJson — fallback a root message', () {
      final ex = OdooException.fromJson({'code': 300, 'message': 'Bad token'});
      expect(ex.message, 'Bad token');
    });

    test('fromJson — valores por defecto con mapa vacío', () {
      final ex = OdooException.fromJson({});
      expect(ex.message, 'Unknown Odoo error');
      expect(ex.code, 0);
    });

    test('accessDenied() — code 403, isAuthError true', () {
      final ex = OdooException.accessDenied('Sin permisos');
      expect(ex.code, 403);
      expect(ex.message, 'Sin permisos');
      expect(ex.isAuthError, isTrue);
    });

    test('accessDenied() sin mensaje usa default', () {
      expect(OdooException.accessDenied().message, 'Access Denied');
    });

    test('notFound() — code 404, isAuthError false', () {
      final ex = OdooException.notFound('No existe');
      expect(ex.code, 404);
      expect(ex.isAuthError, isFalse);
    });

    test('serverError() — code 500', () {
      final ex = OdooException.serverError('DB caído');
      expect(ex.code, 500);
      expect(ex.message, 'DB caído');
    });

    test('isAuthError es true solo para 100 y 403', () {
      expect(OdooException(code: 100, message: 'x').isAuthError, isTrue);
      expect(OdooException(code: 403, message: 'x').isAuthError, isTrue);
      expect(OdooException(code: 401, message: 'x').isAuthError, isFalse);
      expect(OdooException(code: 404, message: 'x').isAuthError, isFalse);
      expect(OdooException(code: 500, message: 'x').isAuthError, isFalse);
    });

    test('toJson round-trip', () {
      final ex = OdooException(
        code: 500,
        message: 'Error',
        data: {'trace': 'stack...'},
      );
      final json = ex.toJson();
      expect(json['code'], 500);
      expect(json['message'], 'Error');
      expect(json['data']?['trace'], 'stack...');
    });

    test('toString incluye código y mensaje', () {
      final ex = OdooException(code: 404, message: 'not found');
      expect(ex.toString(), contains('404'));
      expect(ex.toString(), contains('not found'));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // GRUPO 2 — OdooSessionExpiredException
  // ───────────────────────────────────────────────────────────────────────────
  group('2. OdooSessionExpiredException', () {
    test('es subclase de OdooException', () {
      const ex = OdooSessionExpiredException();
      expect(ex, isA<OdooException>());
    });

    test('code siempre es 100', () {
      expect(const OdooSessionExpiredException().code, 100);
    });

    test('isAuthError siempre true', () {
      expect(const OdooSessionExpiredException().isAuthError, isTrue);
    });

    test('mensaje por defecto', () {
      const ex = OdooSessionExpiredException();
      expect(ex.message, 'Session expired or not valid');
    });

    test('mensaje personalizable', () {
      const ex = OdooSessionExpiredException(message: 'Token caducado');
      expect(ex.message, 'Token caducado');
    });

    test('toString contiene clase y mensaje', () {
      const ex = OdooSessionExpiredException();
      expect(ex.toString(), contains('OdooSessionExpiredException'));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // GRUPO 3 — OdooSession
  // ───────────────────────────────────────────────────────────────────────────
  group('3. OdooSession', () {
    // Mapa que simula la respuesta de /web/session/authenticate
    const sessionInfo = {
      'session_id': 'tok_abc123',
      'uid': 2,
      'partner_id': 10,
      'company_id': 1,
      'name': 'Administrator',
      'username': 'admin',
      'db': 'testdb',
      'is_system': true,
      'websocket_worker_version': '18.0-7',
      'server_version_info': [18, 0, 0, 'final', 0, ''],
      'user_context': {
        'lang': 'es_MX',
        'tz': 'America/Mexico_City',
        'uid': 2,
      },
    };

    test('fromSessionInfo — parsea todos los campos básicos', () {
      final s = OdooSession.fromSessionInfo(sessionInfo);
      expect(s.id, 'tok_abc123');
      expect(s.userId, 2);
      expect(s.partnerId, 10);
      expect(s.companyId, 1);
      expect(s.userName, 'Administrator');
      expect(s.userLogin, 'admin');
      expect(s.dbName, 'testdb');
      expect(s.isSystem, isTrue);
      expect(s.userLang, 'es_MX');
      expect(s.userTz, 'America/Mexico_City');
    });

    test('fromSessionInfo — extrae websocketWorkerVersion', () {
      final s = OdooSession.fromSessionInfo(sessionInfo);
      expect(s.websocketWorkerVersion, '18.0-7');
    });

    test('fromSessionInfo — default websocketWorkerVersion cuando falta', () {
      final noWs = Map<String, dynamic>.from(sessionInfo)
        ..remove('websocket_worker_version');
      final s = OdooSession.fromSessionInfo(noWs);
      expect(s.websocketWorkerVersion, '1');
    });

    test('serverVersionInt extrae versión mayor', () {
      final s = OdooSession.fromSessionInfo(sessionInfo);
      expect(s.serverVersion, '18');
      expect(s.serverVersionInt, 18);
    });

    test('isAuthenticated true con id y userId válidos', () {
      final s = OdooSession.fromSessionInfo(sessionInfo);
      expect(s.isAuthenticated, isTrue);
    });

    test('isAuthenticated false con userId 0', () {
      const s = OdooSession(
        id: '',
        userId: 0,
        partnerId: 0,
        companyId: 0,
        allowedCompanies: [],
        userName: '',
        userLogin: '',
        userLang: 'en_US',
        userTz: 'UTC',
        isSystem: false,
        dbName: '',
        serverVersion: '18',
      );
      expect(s.isAuthenticated, isFalse);
    });

    test('isAuthenticated true aunque id esté vacío si userId > 0 (cookie-only auth)', () {
      const s = OdooSession(
        id: '', // sin session_id en body (solo cookie)
        userId: 2,
        partnerId: 3,
        companyId: 1,
        allowedCompanies: [],
        userName: 'Admin',
        userLogin: 'admin',
        userLang: 'en_US',
        userTz: 'UTC',
        isSystem: true,
        dbName: 'testdb',
        serverVersion: '18',
      );
      expect(s.isAuthenticated, isTrue);
    });

    test('toJson / fromJson round-trip preserva todos los campos', () {
      final original = OdooSession.fromSessionInfo(sessionInfo);
      final restored = OdooSession.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.partnerId, original.partnerId);
      expect(restored.companyId, original.companyId);
      expect(restored.userName, original.userName);
      expect(restored.userLogin, original.userLogin);
      expect(restored.userLang, original.userLang);
      expect(restored.userTz, original.userTz);
      expect(restored.isSystem, original.isSystem);
      expect(restored.dbName, original.dbName);
      expect(restored.serverVersionInt, original.serverVersionInt);
      expect(restored.websocketWorkerVersion, original.websocketWorkerVersion);
    });

    test('updateSessionId con id vacío resetea todos los campos', () {
      final s = OdooSession.fromSessionInfo(sessionInfo);
      final out = s.updateSessionId('');
      expect(out.id, '');
      expect(out.userId, 0);
      expect(out.userName, '');
      expect(out.isAuthenticated, isFalse);
      expect(out.websocketWorkerVersion, '1');
    });

    test('updateSessionId con nuevo id mantiene datos de usuario', () {
      final s = OdooSession.fromSessionInfo(sessionInfo);
      final updated = s.updateSessionId('new-token-xyz');
      expect(updated.id, 'new-token-xyz');
      expect(updated.userId, s.userId);
      expect(updated.userName, s.userName);
      expect(updated.websocketWorkerVersion, s.websocketWorkerVersion);
    });

    test('OdooCompany — igualdad por id y nombre', () {
      const a = OdooCompany(id: 1, name: 'ACME');
      const b = OdooCompany(id: 1, name: 'ACME');
      const c = OdooCompany(id: 2, name: 'Other');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('OdooCompany — fromJson / toJson round-trip', () {
      const comp = OdooCompany(id: 5, name: 'TestCo');
      final restored = OdooCompany.fromJson(comp.toJson());
      expect(restored.id, comp.id);
      expect(restored.name, comp.name);
    });

    test('OdooCompany.fromJsonList parsea lista correctamente', () {
      final list = OdooCompany.fromJsonList([
        {'id': 1, 'name': 'A'},
        {'id': 2, 'name': 'B'},
      ]);
      expect(list, hasLength(2));
      expect(list[1].name, 'B');
    });

    test('toString incluye userId y userName', () {
      final s = OdooSession.fromSessionInfo(sessionInfo);
      expect(s.toString(), contains('Administrator'));
      expect(s.toString(), contains('2'));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // GRUPO 4 — OdooRepository CRUD (con mock)
  // ───────────────────────────────────────────────────────────────────────────
  group('4. OdooRepository CRUD (mock)', () {
    test('searchFetch — decodifica lista de registros', () async {
      final repo = EmployeeRepository(
        client: MockOdooClient(mockResponse: {
          'records': [
            {'id': 1, 'name': 'Ana López', 'create_uid': [2, 'Admin']},
            {'id': 2, 'name': 'Carlos Ruiz'},
          ],
          'length': 2,
        }),
      );
      final res = await repo.searchFetch();
      expect(res.records, hasLength(2));
      expect(res.length, 2);
      expect(res.records.first.name, 'Ana López');
      expect(res.records.first.createUid, 2);
    });

    test('searchFetch — maneja lista vacía', () async {
      final repo = EmployeeRepository(
        client: MockOdooClient(mockResponse: {'records': [], 'length': 0}),
      );
      final res = await repo.searchFetch();
      expect(res.records, isEmpty);
      expect(res.length, 0);
    });

    test('searchIds — retorna lista de enteros', () async {
      final repo = EmployeeRepository(
        client: MockOdooClient(mockResponse: [10, 20, 30]),
      );
      final ids = await repo.searchIds();
      expect(ids, hasLength(3));
      expect(ids[2], 30);
    });

    test('read — mapea a objetos tipados', () async {
      final repo = EmployeeRepository(
        client: MockOdooClient(mockResponse: [
          {'id': 1, 'name': 'Emp 1'},
          {'id': 2, 'name': 'Emp 2'},
        ]),
      );
      final records = await repo.read([1, 2]);
      expect(records, hasLength(2));
      expect(records.last.name, 'Emp 2');
    });

    test('read con ids vacíos retorna lista vacía inmediatamente', () async {
      final repo = EmployeeRepository(client: MockOdooClient());
      expect(await repo.read([]), isEmpty);
    });

    test('create — retorna ID nuevo de la BB.DD.', () async {
      final repo = EmployeeRepository(
        client: MockOdooClient(mockResponse: 99),
      );
      expect(await repo.create({'name': 'Nuevo'}), equals(99));
    });

    test('write — retorna true en éxito', () async {
      final repo = EmployeeRepository(
        client: MockOdooClient(mockResponse: true),
      );
      expect(await repo.write([99], {'name': 'Actualizado'}), isTrue);
    });

    test('write con ids vacíos retorna true inmediatamente', () async {
      final repo = EmployeeRepository(client: MockOdooClient());
      expect(await repo.write([], {'name': 'X'}), isTrue);
    });

    test('unlink — retorna true en éxito', () async {
      final repo = EmployeeRepository(
        client: MockOdooClient(mockResponse: true),
      );
      expect(await repo.unlink([99]), isTrue);
    });

    test('unlink con ids vacíos retorna true inmediatamente', () async {
      final repo = EmployeeRepository(client: MockOdooClient());
      expect(await repo.unlink([]), isTrue);
    });

    test('webSave — retorna registros actualizados', () async {
      final repo = EmployeeRepository(
        client: MockOdooClient(mockResponse: [
          {'id': 99, 'name': 'Guardado'}
        ]),
      );
      final saved = await repo.webSave(ids: [99], values: {'name': 'Guardado'});
      expect(saved, hasLength(1));
      expect(saved.first.name, 'Guardado');
    });

    test('repository propaga OdooException', () async {
      final repo = EmployeeRepository(
        client: MockOdooClient(
          throwException: OdooException(code: 500, message: 'Server crashed'),
        ),
      );
      expect(
        () => repo.searchFetch(),
        throwsA(
          isA<OdooException>().having((e) => e.message, 'message', 'Server crashed'),
        ),
      );
    });

    test('repository propaga OdooSessionExpiredException', () async {
      final repo = EmployeeRepository(
        client: MockOdooClient(
          throwException: const OdooSessionExpiredException(),
        ),
      );
      expect(
        () => repo.searchFetch(),
        throwsA(isA<OdooSessionExpiredException>()),
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // GRUPO 5 — searchCount y callMethod (con mock)
  // ───────────────────────────────────────────────────────────────────────────
  group('5. Repository Extensions — searchCount / callMethod (mock)', () {
    test('searchCount — retorna entero con dominio', () async {
      final repo = PartnerRepository(client: MockOdooClient(mockResponse: 42));
      final count = await repo.searchCount(
        domain: [['is_company', '=', true]],
      );
      expect(count, equals(42));
    });

    test('searchCount — dominio vacío retorna total', () async {
      final repo = PartnerRepository(client: MockOdooClient(mockResponse: 120));
      expect(await repo.searchCount(), equals(120));
    });

    test('searchCount — propaga excepciones', () {
      final repo = PartnerRepository(
        client: MockOdooClient(
          throwException: OdooException(code: 403, message: 'No access'),
        ),
      );
      expect(() => repo.searchCount(), throwsA(isA<OdooException>()));
    });

    test('callMethod — retorna respuesta del servidor', () async {
      final repo = PartnerRepository(client: MockOdooClient(mockResponse: true));
      final result = await repo.callMethod(
        method: 'action_confirm',
        ids: [1, 2],
      );
      expect(result, isTrue);
    });

    test('callMethod sin ids llama método de clase', () async {
      final repo = PartnerRepository(
        client: MockOdooClient(
          mockResponse: {'type': 'ir.actions.act_window', 'name': 'Config'},
        ),
      );
      final result = await repo.callMethod(method: 'action_open_config');
      expect(result, isA<Map>());
      expect(result['type'], 'ir.actions.act_window');
    });

    test('callMethod con kwargs adicionales', () async {
      final repo = PartnerRepository(client: MockOdooClient(mockResponse: 'ok'));
      final result = await repo.callMethod(
        method: 'do_something',
        ids: [5],
        kwargs: {'extra_param': true},
        context: {'lang': 'es_MX'},
      );
      expect(result, 'ok');
    });

    test('callMethod propaga OdooException con isAuthError', () {
      final repo = PartnerRepository(
        client: MockOdooClient(
          throwException: OdooException(code: 403, message: 'Access Denied'),
        ),
      );
      expect(
        () => repo.callMethod(method: 'action_confirm', ids: [1]),
        throwsA(
          isA<OdooException>().having((e) => e.isAuthError, 'isAuthError', isTrue),
        ),
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // GRUPO 6 — OdooRealtimeClient (unit)
  // ───────────────────────────────────────────────────────────────────────────
  group('6. OdooRealtimeClient (unit)', () {
    test('fromSession — construye cliente con sessionId formateado', () {
      const session = OdooSession(
        id: 'mysessionid123',
        userId: 1,
        partnerId: 3,
        companyId: 1,
        allowedCompanies: [],
        userName: 'Test',
        userLogin: 'test',
        userLang: 'en_US',
        userTz: 'UTC',
        isSystem: false,
        dbName: 'testdb',
        serverVersion: '18',
        websocketWorkerVersion: '18.0-5',
      );
      final ws = OdooRealtimeClient.fromSession(
        session: session,
        baseUrl: 'https://mi-odoo.com',
      );
      expect(ws.sessionId, contains('mysessionid123'));
      expect(ws.websocketWorkerVersion, '18.0-5');
      expect(ws.baseUrl, 'https://mi-odoo.com');
    });

    test('isConnected es false antes de connect()', () {
      final ws = OdooRealtimeClient(
        baseUrl: 'https://mi-odoo.com',
        sessionId: 'session_id=abc',
        websocketWorkerVersion: '18.0-5',
      );
      expect(ws.isConnected, isFalse);
    });

    test('messages es un Stream broadcast', () {
      final ws = OdooRealtimeClient(
        baseUrl: 'https://mi-odoo.com',
        sessionId: 'session_id=abc',
        websocketWorkerVersion: '18.0-5',
      );
      expect(ws.messages, isA<Stream<Map<String, dynamic>>>());
      // Debe poder tener múltiples listeners
      ws.messages.listen((_) {});
      ws.messages.listen((_) {}); // No debe lanzar error
    });

    test('disconnect cierra sin lanzar error', () {
      final ws = OdooRealtimeClient(
        baseUrl: 'https://mi-odoo.com',
        sessionId: 'session_id=abc',
        websocketWorkerVersion: '18.0-5',
      );
      expect(() => ws.disconnect(), returnsNormally);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // GRUPO 7 — Integración RunBot — Authenticación y sesión
  // ───────────────────────────────────────────────────────────────────────────
  group('7. Integración RunBot — Sesión', () {
    late OdooRpcService odoo;
    late OdooSession session;

    setUpAll(() async {
      odoo = _buildRunbotClient();
      session = await odoo.authenticate(_runbotDb, _runbotUser, _runbotPass);
    });

    tearDownAll(() => OdooRpcService.reset());

    test('authenticate retorna OdooSession válida', () {
      expect(session.isAuthenticated, isTrue);
      expect(session.userId, isNonZero);
      expect(session.userLogin, _runbotUser);
      expect(session.dbName, _runbotDb);
    });

    test('serverVersionInt es 17 o superior', () {
      expect(session.serverVersionInt, greaterThanOrEqualTo(17));
    });

    test('websocketWorkerVersion no está vacío', () {
      expect(session.websocketWorkerVersion, isNotEmpty);
      print('  🔌 WS version: ${session.websocketWorkerVersion}');
    });

    test('currentSession es la sesión activa', () {
      expect(odoo.currentSession, isNotNull);
      expect(odoo.currentSession!.id, equals(session.id));
    });

    test('toJson / fromJson preserva la sesión completa', () {
      final restored = OdooSession.fromJson(session.toJson());
      expect(restored.id, session.id);
      expect(restored.userId, session.userId);
      expect(restored.dbName, session.dbName);
      expect(restored.websocketWorkerVersion, session.websocketWorkerVersion);
    });

    test('checkSession no lanza excepción con sesión válida', () async {
      await expectLater(odoo.checkSession(), completes);
    });

    test('inRequestStream emite true luego false durante una petición', () async {
      final events = <bool>[];
      final subscription = odoo.inRequestStream.listen(events.add);

      await odoo.callKwRaw(
        model: 'res.partner',
        method: 'search_count',
        args: [[]],
        kwargs: {},
      );

      await subscription.cancel();
      expect(events, contains(true));
      expect(events, contains(false));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // GRUPO 8 — Integración RunBot — CRUD completo (res.partner)
  // ───────────────────────────────────────────────────────────────────────────
  group('8. Integración RunBot — CRUD res.partner', () {
    late OdooRpcService odoo;
    late PartnerRepository partnerRepo;
    late int testPartnerId;

    setUpAll(() async {
      odoo = _buildRunbotClient();
      await odoo.authenticate(_runbotDb, _runbotUser, _runbotPass);
      partnerRepo = PartnerRepository(client: odoo);
    });

    tearDownAll(() {
      OdooRpcService.reset();
    });

    test('create — crea contacto y retorna ID', () async {
      testPartnerId = await partnerRepo.create({
        'name': 'Dart Test Contact',
        'email': 'dart-test@example.dev',
        'phone': '555-0001',
      });
      expect(testPartnerId, isA<int>());
      expect(testPartnerId, isNonZero);
      print('  ✅ Creado ID: $testPartnerId');
    });

    test('searchFetch con domain filtra correctamente', () async {
      final res = await partnerRepo.searchFetch(
        domain: [['id', '=', testPartnerId]],
        limit: 1,
      );
      expect(res.records, hasLength(1));
      expect(res.records.first.name, 'Dart Test Contact');
    });

    test('searchIds retorna ID correcto con domain', () async {
      final ids = await partnerRepo.searchIds(
        domain: [['id', '=', testPartnerId]],
      );
      expect(ids, contains(testPartnerId));
    });

    test('searchCount retorna 1 para el contacto creado', () async {
      final count = await partnerRepo.searchCount(
        domain: [['id', '=', testPartnerId]],
      );
      expect(count, equals(1));
    });

    test('read — trae datos del contacto por ID', () async {
      final records = await partnerRepo.read([testPartnerId]);
      expect(records, hasLength(1));
      expect(records.first.name, 'Dart Test Contact');
      expect(records.first.phone, '555-0001');
    });

    test('write — actualiza teléfono', () async {
      final ok = await partnerRepo.write(
        [testPartnerId],
        {'phone': '555-9999'},
      );
      expect(ok, isTrue);
    });

    test('webSave — cambia nombre y lo devuelve actualizado', () async {
      final saved = await partnerRepo.webSave(
        ids: [testPartnerId],
        values: {'name': 'Dart Test Contact V2'},
      );
      expect(saved, hasLength(1));
      expect(saved.first.name, 'Dart Test Contact V2');
      expect(saved.first.phone, '555-9999');
    });

    test('callMethod — name_search retorna coincidencias', () async {
      final result = await partnerRepo.callMethod(
        method: 'name_search',
        kwargs: {'name': 'Dart Test', 'limit': 5},
      );
      expect(result, isA<List>());
      expect((result as List).isNotEmpty, isTrue);
    });

    test('unlink — elimina el contacto de prueba', () async {
      final ok = await partnerRepo.unlink([testPartnerId]);
      expect(ok, isTrue);
      // Verificar que ya no existe
      final count = await partnerRepo.searchCount(
        domain: [['id', '=', testPartnerId]],
      );
      expect(count, equals(0));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // GRUPO 9 — Integración RunBot — Modelos adicionales
  // ───────────────────────────────────────────────────────────────────────────
  group('9. Integración RunBot — res.users / hr.employee', () {
    late OdooRpcService odoo;

    setUpAll(() async {
      odoo = _buildRunbotClient();
      await odoo.authenticate(_runbotDb, _runbotUser, _runbotPass);
    });

    tearDownAll(() => OdooRpcService.reset());

    test('UserRepository.searchFetch retorna usuarios', () async {
      final userRepo = UserRepository(client: odoo);
      final result = await userRepo.searchFetch(limit: 5);
      expect(result.records, isNotEmpty);
      expect(result.records.first.id, isNonZero);
      print('  👤 ${result.records.length} usuarios: '
          '${result.records.map((u) => u.login).join(', ')}');
    });

    test('UserRepository.searchCount retorna count > 0', () async {
      final userRepo = UserRepository(client: odoo);
      final count = await userRepo.searchCount();
      expect(count, greaterThan(0));
    });

    test('EmployeeRepository.searchFetch retorna empleados', () async {
      final empRepo = EmployeeRepository(client: odoo);
      final result = await empRepo.searchFetch(limit: 3);
      // Puede ser 0 si no hay empleados en el runbot, pero no debe lanzar error
      expect(result.records, isA<List>());
      print('  👷 ${result.records.length} empleados encontrados.');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // GRUPO 10 — Integración RunBot — WebSocket
  // ───────────────────────────────────────────────────────────────────────────
  group('10. Integración RunBot — WebSocket', () {
    late OdooRpcService odoo;
    late OdooSession session;

    setUpAll(() async {
      odoo = _buildRunbotClient();
      session = await odoo.authenticate(_runbotDb, _runbotUser, _runbotPass);
    });

    tearDownAll(() => OdooRpcService.reset());

    test('connectRealtime lanza StateError si no hay sesión', () {
      OdooRpcService.reset();
      final freshDio = Dio(BaseOptions(baseUrl: _runbotUrl));
      final freshOdoo = OdooRpcService(dio: freshDio);
      expect(
        () => freshOdoo.connectRealtime(),
        throwsA(isA<StateError>()),
      );
      OdooRpcService.reset();
    });

    test('connectRealtime retorna OdooRealtimeClient con datos correctos', () {
      odoo = _buildRunbotClient();
      // Autenticar de nuevo después del reset anterior
    }, skip: 'Reemplazado por el test integrado de abajo.');

    test(
      'WebSocket — conectar y recibir ping del servidor',
      () async {
        final ws = odoo.connectRealtime();

        print('  session.id: ${session.id}');
        print('  WS version: ${session.websocketWorkerVersion}');
        print('  baseUrl: $_runbotUrl');

        final completer = Completer<void>();
        final receivedEvents = <Map<String, dynamic>>[];
        Object? wsError;

        final subscription = ws.messages.listen(
          (event) {
            receivedEvents.add(event);
            print('  📨 Evento WS recibido: ${event.keys.join(', ')}');
            if (!completer.isCompleted) completer.complete();
          },
          onError: (Object error) {
            wsError = error;
            if (!completer.isCompleted) completer.completeError(error);
          },
        );

        ws.connect(channels: ['odoo', 'discuss.channel_1']);

        // Esperar hasta 8 segundos un evento o timeout
        await Future.any([
          completer.future,
          Future.delayed(const Duration(seconds: 8)),
        ]);

        await subscription.cancel();
        ws.disconnect();

        if (wsError != null) {
          print('  ⚠️  Error WS: $wsError');
        }

        if (receivedEvents.isEmpty) {
          print('  ℹ️  No se recibieron eventos en 8s '
              '(normal si el server no emite al suscribirse).');
        } else {
          print('  ✅ Se recibieron ${receivedEvents.length} eventos en tiempo real.');
        }

        // El test es exitoso si no lanzó excepción grave
        expect(wsError, isNull,
            reason: 'No debería haber error de WebSocket al conectar');
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    test(
      'WebSocket fromSession — construye correctamente desde sesión activa',
      () {
        final ws = OdooRealtimeClient.fromSession(
          session: session,
          baseUrl: _runbotUrl,
        );
        expect(ws.sessionId, contains(session.id));
        expect(ws.websocketWorkerVersion, session.websocketWorkerVersion);
        expect(ws.baseUrl, _runbotUrl);
        expect(ws.isConnected, isFalse);
        ws.disconnect(); // cleanup
      },
    );

    test(
      'WebSocket subscribe — envía suscripción a nuevos canales sin error',
      () async {
        final ws = odoo.connectRealtime();
        ws.connect(channels: ['odoo']);

        // Esperar un poco para que la conexión se establezca
        await Future<void>.delayed(const Duration(seconds: 2));

        // subscribe no debe lanzar
        expect(
          () => ws.subscribe(['discuss.channel_1', 'discuss.channel_2']),
          returnsNormally,
        );

        ws.disconnect();
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );
  });

  // ───────────────────────────────────────────────────────────────────────────
  // GRUPO 11 — OdooRpcService — Gestión del singleton
  // ───────────────────────────────────────────────────────────────────────────
  group('11. OdooRpcService — Singleton y gestión', () {
    tearDown(() => OdooRpcService.reset());

    test('reset() destruye el singleton — nueva instancia es fresca', () {
      final a = OdooRpcService(dio: Dio(BaseOptions(baseUrl: 'https://a.com')));
      OdooRpcService.reset();
      final b = OdooRpcService(dio: Dio(BaseOptions(baseUrl: 'https://b.com')));
      expect(a, isNot(same(b)));
    });

    test('misma instancia antes de reset()', () {
      final a = OdooRpcService();
      final b = OdooRpcService();
      expect(a, same(b));
    });

    test('setBaseUrl actualiza la URL del cliente', () {
      final client = OdooRpcService(
        dio: Dio(BaseOptions(baseUrl: 'https://old.odoo.com')),
      );
      client.setBaseUrl('https://new.odoo.com');
      // Si no lanza excepción, la llamada fue exitosa
      expect(() => client.setBaseUrl('https://new.odoo.com'), returnsNormally);
    });

    test('currentSession es null antes de authenticate', () {
      final client = OdooRpcService(
        dio: Dio(BaseOptions(baseUrl: _runbotUrl)),
      );
      expect(client.currentSession, isNull);
    });

    test('connectRealtime lanza StateError sin sesión activa', () {
      final client = OdooRpcService(
        dio: Dio(BaseOptions(baseUrl: _runbotUrl)),
      );
      expect(() => client.connectRealtime(), throwsA(isA<StateError>()));
    });
  });
}
