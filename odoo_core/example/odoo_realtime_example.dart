import 'dart:io';
import 'package:dio/dio.dart';
import 'package:odoo_core/odoo_core.dart';
import 'package:odoo_core/src/network/client/odoo_rpc_service.dart';
import 'package:odoo_core/src/network/client/odoo_realtime_client.dart';

void main() async {
  print('=== EJEMPLO ODOO WEBSOCKET (RunBot) ===');

  // URL de prueba basada en odoo runbot.
  // NOTA: Esta URL es efímera y cambiará. Actualízala a la de tu entorno si arroja ConnectException.
  const baseUrl = 'https://106987691-18-0-all.runbot303.odoo.com';

  print('1. Configurando cliente para $baseUrl ...');
  final dio = Dio(BaseOptions(baseUrl: baseUrl));

  String? sessionIdCookie;
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      if (sessionIdCookie != null) {
        options.headers['Cookie'] = sessionIdCookie;
      }
      return handler.next(options);
    },
    onResponse: (response, handler) {
      final cookies = response.headers['set-cookie'];
      if (cookies != null) {
        for (var cookie in cookies) {
          if (cookie.contains('session_id')) {
            sessionIdCookie = cookie.split(';').first;
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
      params: {'db': '106987691-18-0-all', 'login': 'admin', 'password': 'admin'},
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    print(authResponse.result);

    if (authResponse.error != null) {
      print('❌ Falló la autenticación: ${authResponse.error!.message}');
      return;
    }

    print("✅ Autenticación exitosa! UID: ${authResponse.result?['uid']}");
    print("🍪 Cookie obtenida: $sessionIdCookie");

    // Extraemos la versión exacta que el servidor está esperando para sus WebSockets
    final workerVersion = authResponse.result?['websocket_worker_version']?.toString() ?? '18.0-7';
    print("🔌 Websocket Worker Version detectado: $workerVersion");

    // 3. Conectar WebSockets en tiempo real
    print('\n3. Iniciando conexión WebSocket Odoo Realtime...');
    final wsClient = OdooRealtimeClient(
      baseUrl: baseUrl,
      sessionId: sessionIdCookie!,
      websocketWorkerVersion: workerVersion,
    );

    // Nos suscribimos explícitamente al canal 1 (usualmente "General" en Runbot) y al canal general de sistema general
    wsClient.connect(channels: ['discuss.channel_1']);

    print('\n🚀 Websocket conectado.');

    // Escuchar e interceptar el flujo decodificado de mensajes Odoo
    wsClient.messages.listen((event) {
      print(event);
      final message = event['message'];
      if (message != null && message['type'] == 'mail.message/new') {
        final body = message['payload']?['body'] ?? 'Sin texto';
        final author = message['payload']?['author_id']?[1] ?? 'Desconocido';
        print('\n  📩 [NUEVO CHAT] $author dice: $body');
      } else {
        // Otros eventos del sistema en el canal
        print('\n  🔔 [EVENTO ODOO] ${event['message']?['type'] ?? 'Desconocido'}');
      }
    });

    print(
        '\n4. Simulando actividad: Enviando mensaje al canal "discuss.channel" ID=1 por API Rest...');

    // Esperamos 2 segundos para dar tiempo al WebSocket de abrirse y registrar la subscripción de canales internamente en Odoo
    await Future.delayed(const Duration(seconds: 2));

    try {
      await odooClient.callKwRaw(
          model: 'discuss.channel',
          method: 'message_post',
          args: [
            1
          ], // ID del canal 1
          kwargs: {
            'body': '¡Hola desde Odoo Dart Client! 🚀 Probando WebSockets...',
            'message_type': 'comment',
            'subtype_xmlid': 'mail.mt_comment',
          });
      print('  ✅ Mensaje enviado de prueba enviado con éxito.');
      print(
          '  👀 El WebSocket de arriba debería imprimir la notificación del payload JSON en breve...');
    } catch (e) {
      print(
          '  ⚠️ Aviso: Error enviando mensaje simulado (Es totalmente normal si el canal ID 1 no existe en este runbot puntual): $e');
    }

    print('\n🚀 Escuchando eventos permanentemente (presiona Enter para detener programita)...');

    // Mantener la ejecución viva y permitir cerrar al presionar enter
    stdin.readLineSync();

    print('Deteniendo websocket...');
    wsClient.disconnect();
    print('Adios!');
  } catch (e) {
    print('\n❌ Error inesperado: $e');
  }
}




// final respuestaLogin = {uid: 2, is_system: true, is_admin: true, is_public: false, is_internal_user: true, user_context: {lang: en_US, tz: America/Mexico_City, uid: 2}, db: 106987691-18-0-all, user_settings: {id: 1, user_id: {id: 2}, homemenu_config: false, is_discuss_sidebar_category_channel_open: true, is_discuss_sidebar_category_chat_open: true, push_to_talk_key: false, use_push_to_talk: false, voice_active_duration: 200, channel_notifications: false, mute_until_dt: false, voip_provider_id: false, voip_username: false, voip_secret: false, should_call_from_another_device: false, external_device_number: false, should_auto_reject_incoming_calls: false, how_to_call_on_mobile: ask, is_discuss_sidebar_category_whatsapp_open: true, onsip_auth_username: false, livechat_username: false, livechat_lang_ids: [], volumes: [[ADD, []]]}, server_version: 18.0+e, server_version_info: [18, 0, 0, final, 0, e], support_url: https://www.odoo.com/help, name: Mitchell Admin, username: admin, quick_login: true, partner_write_date: 2026-04-10 23:34:40, partner_display_name: YourCompany, Mitchell Admin, partner_id: 3, web.base.url: https://106987691-18-0-all.runbot303.odoo.com, active_ids_limit: 20000, profile_session: null, profile_collectors: null, profile_params: null, max_file_upload_size: 67108863, home_action_id: false, cache_hashes: {translations: a3cdde922e9fe9f17edc1ab57dec8f0520b5489d, load_menus: 81e798c30fe482c1fd39aff48fcdee770df31bb49fcc30335bf57b38bc8ffac5}, currencies: {6: {symbol: ¥, position: before, digits: [69, 2]}, 126: {symbol: €, position: after, digits: [69, 2]}, 24: {symbol: $, position: before, digits: [69, 2]}, 89: {symbol: ₪, position: before, digits: [69, 2]}, 33: {symbol: $, position: before, digits: [69, 2]}, 157: {symbol: S/, position: before, digits: [69, 2]}, 1: {symbol: $, position: before, digits: [69, 2]}}, bundle_params: {lang: en_US}, test_mode: false, view_info: {list: {display_name: List, icon: oi oi-view-list, multi_record: true}, form: {display_name: Form, icon: fa fa-address-card, multi_record: false}, graph: {display_name: Graph, icon: fa fa-area-chart, multi_record: true}, pivot: {display_name: Pivot, icon: oi oi-view-pivot, multi_record: true}, calendar: {display_name: Calendar, icon: fa fa-calendar, multi_record: true}, kanban: {display_name: Kanban, icon: oi oi-view-kanban, multi_record: true}, search: {display_name: Search, icon: oi oi-search, multi_record: true}, cohort: {display_name: Cohort, icon: oi oi-view-cohort, multi_record: true}, gantt: {display_name: Gantt, icon: fa fa-tasks, multi_record: true}, grid: {display_name: Grid, icon: fa fa-th, multi_record: true}, hierarchy: {display_name: Hierarchy, icon: fa fa-share-alt fa-rotate-90, multi_record: true}, map: {display_name: Map, icon: fa fa-map-marker, multi_record: true}, activity: {display_name: Activity, icon: fa fa-clock-o, multi_record: true}}, user_companies: {current_company: 1, allowed_companies: {9: {id: 9, name: BE Company CoA, sequence: 0, child_ids: [], parent_id: false, timesheet_uom_id: 4, timesheet_uom_factor: 1.0}, 3: {id: 3, name: ESCUELA KEMPER URGATE, sequence: 10, child_ids: [], parent_id: false, timesheet_uom_id: 4, timesheet_uom_factor: 1.0}, 8: {id: 8, name: IL Company, sequence: 10, child_ids: [], parent_id: false, timesheet_uom_id: 4, timesheet_uom_factor: 1.0}, 2: {id: 2, name: My Company (Chicago), sequence: 10, child_ids: [], parent_id: false, timesheet_uom_id: 4, timesheet_uom_factor: 1.0}, 5: {id: 5, name: My Hong Kong Company, sequence: 10, child_ids: [], parent_id: false, timesheet_uom_id: 4, timesheet_uom_factor: 1.0}, 6: {id: 6, name: PE Company, sequence: 10, child_ids: [], parent_id: false, timesheet_uom_id: 4, timesheet_uom_factor: 1.0}, 7: {id: 7, name: Test Israel Localization, sequence: 10, child_ids: [], parent_id: false, timesheet_uom_id: 4, timesheet_uom_factor: 1.0}, 4: {id: 4, name: ZAPATERIA URTADO ÑERI, sequence: 10, child_ids: [], parent_id: false, timesheet_uom_id: 4, timesheet_uom_factor: 1.0}, 1: {id: 1, name: My Company (San Francisco), sequence: 0, child_ids: [], parent_id: false, timesheet_uom_id: 4, timesheet_uom_factor: 1.0}}, disallowed_ancestor_companies: {}}, show_effect: true, display_switch_company_menu: true, max_time_between_keys_in_ms: 100, websocket_worker_version: 18.0-7, tour_enabled: false, current_tour: null, warning: admin, expiration_date: false, expiration_reason: false, map_box_token: false, storeData: {Store: {action_discuss_id: 131, channel_types_with_seen_infos: [chat, group, livechat, whatsapp], hasDocumentsUserGroup: true, hasGifPickerFeature: false, hasLinkPreviewFeature: true, hasMessageTranslationFeature: false, has_access_livechat: true, helpdesk_livechat_active: false, internalUserGroupId: 1, mt_comment_id: 1, odoobot: {id: 2, type: partner}, self: {id: 3, type: partner}, settings: {id: 1, user_id: {id: 2}, homemenu_config: false, is_discuss_sidebar_category_channel_open: true, is_discuss_sidebar_category_chat_open: true, push_to_talk_key: false, use_push_to_talk: false, voice_active_duration: 200, channel_notifications: false, mute_until_dt: false, voip_provider_id: false, voip_username: false, voip_secret: false, should_call_from_another_device: false, external_device_number: false, should_auto_reject_incoming_calls: false, how_to_call_on_mobile: ask, is_discuss_sidebar_category_whatsapp_open: true, onsip_auth_username: false, livechat_username: false, livechat_lang_ids: [], volumes: [[ADD, []]]}, voipConfig: {mode: demo, missedCalls: 0, pbxAddress: localhost, webSocketUrl: ws://localhost}}, res.partner: [{active: false, avatar_128_access_token: dc48b911bf5de8085679b64d3841cc8a965c5ea20af2ae8626042139366fc843o0x6a07df51, email: odoobot@example.com, id: 2, im_status: bot, isInternalUser: true, is_company: false, name: OdooBot, out_of_office_date_end: false, userId: 1, write_date: 2026-04-10 23:34:40}, {active: true, avatar_128_access_token: 4d161a64164ca70f8df49161e98b1e3551f22bc22b1d3ce86d491a4a4dbfe6b2o0x6a07e078, id: 3, isAdmin: true, isInternalUser: true, name: Mitchell Admin, notification_preference: email, signature: <span data-o-mail-quote="1">-- <br data-o-mail-quote="1">Mitchell Admin</span>, userId: 2, write_date: 2026-04-10 23:34:40}]}, ocn_token_key: false, fcm_project_id: false, inbox_action: 131, iap_company_enrich: false, can_insert_in_spreadsheet: true, dbuuid: 87c9e921-34f9-11f1-87c6-4f109863ee5d, multi_lang: true, uom_ids: {4: {id: 4, name: Hours, rounding: 0.01, timesheet_widget: float_time}}}