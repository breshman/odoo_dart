import 'package:dio/dio.dart';
import 'package:odoo_core/odoo_core.dart';

import 'runbot_models.dart';

// =========================================================
// SCRIPT PRINCIPAL DE EJEMPLO
// =========================================================

void main() async {
  print('=== EJEMPLO CLIENTE ODOO (RunBot) ===');
  
  // URL de prueba basada en odoo runbot. 
  // NOTA: Esta URL es efímera y cambiará. Actualízala a la de tu entorno si arroja ConnectException.
  const baseUrl = 'https://106987691-18-0-all.runbot303.odoo.com';
  
  print('1. Configurando cliente para $baseUrl ...');
  final dio = Dio(BaseOptions(baseUrl: baseUrl));
  
  // Agregar un interceptor básico para manejar la sesión vía Cookie (requerido por Odoo)
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

  try {
    print('2. Autenticando (admin / admin)...');
    final authResponse = await odooClient.callRpc<Map<String, dynamic>>(
      path: '/web/session/authenticate',
      params: {
        'db': '106987691-18-0-all', // Usualmente en runbot el nombre de bd es igual al subdominio o '18-0-all'
        'login': 'admin',
        'password': 'admin'
      },
      fromJsonT: (json) => json as Map<String, dynamic>,
    );

    if (authResponse.error != null) {
      print('❌ Falló la autenticación: ${authResponse.error!.message}');
      return;
    }

    print("✅ Autenticación exitosa! uid: ${authResponse.result?['uid']}");

    // 3. Obtener Clientes (res.partner)
    print('\n3. Obteniendo Clientes (res.partner)...');
    final partnerRepo = PartnerRepository(client: odooClient);
    final partnersSet = await partnerRepo.searchFetch(limit: 5);
    print('  📌 Se obtuvieron ${partnersSet.records.length} clientes:');
    for (var p in partnersSet.records) {
      print('   - ID: ${p.id} | Nombre: ${p.name} | Teléfono: ${p.phone ?? "N/A"}');
    }

    // 4. Obtener Usuarios (res.users)
    print('\n4. Obteniendo Usuarios (res.users)...');
    final userRepo = UserRepository(client: odooClient);
    final usersSet = await userRepo.searchFetch(limit: 5);
    print('  📌 Se obtuvieron ${usersSet.records.length} usuarios:');
    for (var u in usersSet.records) {
      print('   - ID: ${u.id} | Nombre: ${u.name} | Login: ${u.login ?? "N/A"}');
    }

    // 5. Obtener Empleados (hr.employee)
    print('\n5. Obteniendo Empleados (hr.employee)...');
    final employeeRepo = EmployeeRepository(client: odooClient);
    final employeesSet = await employeeRepo.searchFetch(limit: 5);
    print('  📌 Se obtuvieron ${employeesSet.records.length} empleados:');
    for (var e in employeesSet.records) {
      print('   - ID: ${e.id} | Nombre: ${e.name} | Puesto: ${e.jobTitle ?? "N/A"}');
    }

    print('\n🚀 Flujo de lectura básica completado.');
    print('\n======================================================');
    print('          PROBANDO TODAS LAS OPERACIONES CRUD         ');
    print('======================================================');

    // --- CREATE ---
    print('\n[CREATE] Creando nuevo contacto de prueba...');
    final newPartnerId = await partnerRepo.create({
      'name': 'Dart Integration Test',
      'email': 'test@dart-odoo.dev',
      'phone': '555-1234'
    });
    print('  ✅ Contacto creado exitosamente con ID: $newPartnerId');

    // --- READ ---
    print('\n[READ] Leyendo el contacto recien creado (ID $newPartnerId)...');
    final readRecords = await partnerRepo.read([newPartnerId]);
    if (readRecords.isNotEmpty) {
      print('  ✅ Contacto leído de la BBDD: ${readRecords.first.name} - Tel: ${readRecords.first.phone}');
    }

    // --- WRITE ---
    print('\n[WRITE] Actualizando teléfono mediante escritura silenciosa...');
    final writeSuccess = await partnerRepo.write([newPartnerId], {'phone': '555-9876'});
    print('  ✅ Registro actualizado (boolean result): $writeSuccess');

    // --- WEBSAVE (Save + Read All in One) ---
    print('\n[WEBSAVE] Cambiando nombre y obteniendo objeto retornado todo junto...');
    final webSaveParams = OdooWriteParams<Partner, Map<String, dynamic>>(
      model: 'res.partner',
      ids: [newPartnerId],
      values: {'name': 'Dart Integration Test V2'},
      fromJsonT: (json) => Partner.fromJson(json as Map<String, dynamic>),
      toJson: (v) => v,
    );
    final webSavedRecords = await partnerRepo.webSave(webSaveParams);
    print('  ✅ Contacto retornado de web_save: ${webSavedRecords.first.name} - Nuevo tel es ${webSavedRecords.first.phone}');

    // --- UNLINK (Delete) ---
    print('\n[UNLINK] Eliminando el registro para no ensuciar el RunBot...');
    final unlinkSuccess = await partnerRepo.unlink([newPartnerId]);
    print('  ✅ Registro borrado de manera permanente: $unlinkSuccess');

    print('\n🚀 TODOS LOS MÉTODOS CRUD PROBADOS EXITOSAMENTE.');

  } on OdooException catch (e) {
    print('\n❌ Error de Odoo devuelto por la API:');
    print('   Código: ${e.code}');
    print('   Mensaje: ${e.message}');
  } catch (e) {
    print('\n❌ Error inesperado de conexión o ejecución:');
    print('   Detalles: $e');
    print('   (Recuerda que la URL de RunBot desaparece luego de un tiempo)');
  }
}
