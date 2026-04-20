// ignore_for_file: avoid_print
import 'package:dio/dio.dart';
import 'package:odoo_core/odoo_core.dart';

import 'runbot_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SCRIPT DE EJEMPLO — odoo_core v2.2.0
// RunBot: https://107503898-18-0-all.runbot215.odoo.com
// ─────────────────────────────────────────────────────────────────────────────

const _baseUrl = 'https://107897960-18-0-all.runbot213.odoo.com';
const _db = '107897960-18-0-all';
const _user = 'admin';
const _pass = 'admin';

void main() async {
  print('═══════════════════════════════════════════════════════');
  print('  odoo_core v2.2.0 — Ejemplo completo con RunBot');
  print('═══════════════════════════════════════════════════════\n');

  // ── 1. Configurar Dio + interceptor de cookie ──────────────────────────────
  final dio = Dio(BaseOptions(baseUrl: _baseUrl));

  String? sessionCookie;
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      if (sessionCookie != null) options.headers['Cookie'] = sessionCookie!;
      handler.next(options);
    },
    onResponse: (response, handler) {
      // Usar OdooCookie (RFC 6265) para parsear Set-Cookie correctamente
      final rawCookies = response.headers['set-cookie'] ?? [];
      final sessionId = OdooCookie.extractSessionId(rawCookies);
      if (sessionId != null) {
        // Reconstruir la cookie correctamente formateada
        sessionCookie = OdooCookie('session_id', sessionId).toString();
      }
      handler.next(response);
    },
  ));

  final odoo = OdooRpcService(dio: dio);

  // ── 2. Indicador de carga global ──────────────────────────────────────────
  odoo.inRequestStream.listen(
    (loading) => print('  ⏳ Loading: $loading'),
  );

  try {
    // ── 3. Autenticar con OdooSession tipado ────────────────────────────────
    print('1. Autenticando en $_baseUrl ...');
    final session = await odoo.authenticate(_db, _user, _pass);

    print('   ✅ Bienvenido: ${session.userName} (uid: ${session.userId})');
    print('   🏢 Empresa: ${session.companyId} | DB: ${session.dbName}');
    print('   🏢 Empresa: ${session.csrfToken} | DB: ${session.csrfToken}');
    print('   🔖 | WS: ${session.websocketWorkerVersion}');
    print('   🔐 isAuthenticated: ${session.isAuthenticated}\n');

    // Serialización de sesión (para SharedPreferences, Hive, etc.)
    final json = session.toJson();
    final restored = OdooSession.fromJson(json);
    final idPreview = restored.id.isEmpty
        ? '(via cookie)'
        : '${restored.id.substring(0, restored.id.length.clamp(0, 8))}...';
    print('   📦 Round-trip JSON: id=$idPreview\n');

    // ── 4. Verificar sesión activa ────────────────────────────────────────
    print('2. Verificando sesión activa (checkSession)...');
    await odoo.checkSession();
    print('   ✅ Sesión válida.\n');

    final currentUser = await odoo.checkCurrentUser();
    print('   ✅ Chequeanso usuario.\n');
    print(currentUser);

    // ── 5. Repositorios ───────────────────────────────────────────────────
    final partnerRepo = PartnerRepository(client: odoo);
    final userRepo = UserRepository(client: odoo);
    final empRepo = EmployeeRepository(client: odoo);

    // ── 6. searchFetch res.partner ────────────────────────────────────────
    print('3. searchFetch — 5 primeros res.partner...');
    final partners = await partnerRepo.searchFetch(limit: 5, order: 'name asc');
    print(
        '   📋 ${partners.length} registros en total, mostrando ${partners.records.length}:');
    for (final p in partners.records) {
      print('      · ${p.id}: ${p.name} — ${p.email ?? "sin email"}');
    }
    print('');

    // ── 7. searchCount ────────────────────────────────────────────────────
    print('4. searchCount — empresas activas...');
    final totalEmpresas = await partnerRepo.searchCount(
      domain: [
        ['is_company', '=', true]
      ],
    );
    print('   📊 Total empresas: $totalEmpresas\n');

    // ── 8. searchIds ──────────────────────────────────────────────────────
    print('5. searchIds — primeros 10 IDs de res.users...');
    final userIds = await userRepo.searchIds(
      domain: [
        ['active', '=', true]
      ],
      limit: 10,
    );
    print('   🔢 IDs: $userIds\n');

    // ── 9. CRUD completo ──────────────────────────────────────────────────
    print('6. CRUD completo en res.partner...');

    // CREATE
    final newId = await partnerRepo.create({
      'name': 'Dart Example Contact',
      'email': 'dart@example.dev',
      'phone': '555-0001',
    });
    print('   ✅ CREATE — nuevo ID: $newId');

    // READ
    final read = await partnerRepo.read([newId]);
    print('   ✅ READ  — ${read.first.name} | tel: ${read.first.phone}');

    // WRITE
    await partnerRepo.write([newId], {'phone': '555-9999'});
    print('   ✅ WRITE — teléfono actualizado a 555-9999');

    // WEBSAVE
    final saved = await partnerRepo.webSave(
      ids: [newId],
      values: {'name': 'Dart Example Contact V2'},
    );
    print(
        '   ✅ WEBSAVE — nombre: ${saved.first.name} | tel: ${saved.first.phone}');

    // callMethod — name_search
    final found = await partnerRepo.callMethod(
      method: 'name_search',
      kwargs: {'name': 'Dart Example', 'limit': 5},
    );
    print(
        '   ✅ callMethod(name_search) — ${(found as List).length} coincidencia(s)');

    // UNLINK
    await partnerRepo.unlink([newId]);
    print('   ✅ UNLINK — registro $newId eliminado\n');

    // ── 10. Empleados ─────────────────────────────────────────────────────
    print('7. hr.employee — primeros 3 empleados...');
    final emps = await empRepo.searchFetch(limit: 3);
    if (emps.records.isEmpty) {
      print('   ℹ️  Sin empleados en este RunBot.');
    } else {
      for (final e in emps.records) {
        print('      · ${e.id}: ${e.name} — ${e.jobTitle ?? "sin puesto"}');
      }
    }
    print('');

    // ── 11. WebSocket Realtime ────────────────────────────────────────────
    print('8. WebSocket Realtime — conectando...');
    final ws = odoo.connectRealtime();

    final events = <String>[];
    final sub = ws.messages.listen((event) {
      final type =
          (event['message'] as Map?)?['type'] as String? ?? event.keys.first;
      events.add(type);
      print('   📨 Evento: $type');
    });

    ws.connect(channels: ['odoo', 'discuss.channel_1']);

    // Esperar un momento para que se establezca la conexión WS
    await Future<void>.delayed(const Duration(seconds: 2));

    // ── Enviar mensaje "Hello World" vía RPC ──────────────────────────────
    // Una vez conectado el WS, cualquier mensaje_post en el canal
    // llegará como evento al stream de mensajes.
    print('   ✉️  Enviando mensaje de prueba al canal 1...');
    try {
      // Obtener el ID del canal "general" o usar el primero disponible
      final channels = await odoo.callKwRaw(
        model: 'discuss.channel',
        method: 'search_read',
        args: [[]],
        kwargs: {
          'fields': ['id', 'name'],
          'limit': 1,
          'order': 'id asc',
        },
      );

      if (channels is List && channels.isNotEmpty) {
        final channelId = (channels.first as Map)['id'] as int;
        final channelName = (channels.first as Map)['name'] as String;
        print('   📢 Enviando a canal "$channelName" (ID: $channelId)...');

        await odoo.callKwRaw(
          model: 'discuss.channel',
          method: 'message_post',
          args: [channelId],
          kwargs: {
            'body': 'Hello World! Testing with Flutter 🐦',
            'message_type': 'comment',
            'subtype_xmlid': 'mail.mt_comment',
          },
        );
        print('   ✅ Mensaje enviado a "$channelName".');
      } else {
        print('   ⚠️  No se encontraron canales activos.');
      }
    } catch (e) {
      print('   ⚠️  No se pudo enviar el mensaje: $e');
    }

    print('   ℹ️  Escuchando 10 segundos para recibir el evento WS...');
    await Future<void>.delayed(const Duration(seconds: 10));

    // Suscribirse a canal adicional en caliente
    ws.subscribe(['discuss.channel_2']);
    await Future<void>.delayed(const Duration(seconds: 2));

    await sub.cancel();
    ws.disconnect();
    print('   ✅ WS desconectado. Eventos recibidos: ${events.length}\n');

    // ── 12. Logout ────────────────────────────────────────────────────────
    print('9. Cerrando sesión (destroySession)...');
    await odoo.destroySession();
    print('   ✅ Sesión cerrada. currentSession: ${odoo.currentSession}');
    OdooRpcService.reset();
    print('   ✅ Singleton reseteado.\n');

    print('═══════════════════════════════════════════════════════');
    print('  ✅ Todos los flujos completados exitosamente.');
    print('═══════════════════════════════════════════════════════');
  } on OdooSessionExpiredException {
    print('\n❌ Sesión expirada o credenciales inválidas.');
    print('   Actualiza la URL/credenciales del RunBot si caducó.');
  } on OdooException catch (e) {
    print('\n❌ Error Odoo (código ${e.code}): ${e.message}');
    if (e.data != null) print('   Data: ${e.data}');
  } catch (e) {
    print('\n❌ Error inesperado: $e');
    print('   (La URL del RunBot puede haber expirado)');
  } finally {
    OdooRpcService.reset();
  }
}
