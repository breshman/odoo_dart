import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../odoo_cookie.dart';
import '../odoo_session.dart';

/// Cliente WebSocket para recibir notificaciones en tiempo real de Odoo.
///
/// ## Uso recomendado — desde sesión activa
///
/// La forma más simple es usar [OdooRpcService.connectRealtime] después de
/// autenticar. Esto evita pasar parámetros manualmente:
///
/// ```dart
/// final session = await odooClient.authenticate('mydb', 'admin', 'admin');
/// final ws = odooClient.connectRealtime();
///
/// ws.connect(channels: ['discuss.channel_1']);
///
/// ws.messages.listen((event) {
///   final msg = event['message'];
///   if (msg?['type'] == 'mail.message/new') {
///     print('Nuevo mensaje: ${msg!['payload']['body']}');
///   }
/// });
///
/// // Al cerrar sesión:
/// ws.disconnect();
/// ```
///
/// ## Uso manual
///
/// Si prefieres construirlo a mano puedes usar el constructor por defecto
/// o [OdooRealtimeClient.fromSession]:
///
/// ```dart
/// final ws = OdooRealtimeClient.fromSession(
///   session: odooClient.currentSession!,
///   baseUrl: 'https://mi-odoo.com',
/// );
/// ```
class OdooRealtimeClient {
  /// Constructor manual. Requiere todos los parámetros explícitamente.
  ///
  /// Se recomienda usar [OdooRealtimeClient.fromSession] o
  /// [OdooRpcService.connectRealtime] en su lugar.
  OdooRealtimeClient({
    required this.baseUrl,
    required this.sessionId,
    required this.websocketWorkerVersion,
  });

  /// Constructor desde [OdooSession].
  ///
  /// Extrae automáticamente `sessionId` y `websocketWorkerVersion` de la sesión
  /// activa, por lo que no es necesario extraerlos manualmente:
  ///
  /// ```dart
  /// final ws = OdooRealtimeClient.fromSession(
  ///   session: odooClient.currentSession!,
  ///   baseUrl: 'https://mi-odoo.com',
  /// );
  /// ws.connect(channels: ['discuss.channel_1']);
  /// ```
  factory OdooRealtimeClient.fromSession({
    required OdooSession session,
    required String baseUrl,
  }) {
    // Formatea la cookie usando OdooCookie (RFC 6265, cross-platform)
    final cookie = OdooCookie('session_id', session.id);
    return OdooRealtimeClient(
      baseUrl: baseUrl,
      sessionId: cookie.toString(), // "session_id=abc123"
      websocketWorkerVersion: session.websocketWorkerVersion,
    );
  }

  /// URL base del servidor Odoo (e.g. `'https://mi-odoo.com'`).
  final String baseUrl;

  /// Valor de la cookie `session_id` incluyendo el prefijo, e.g. `'session_id=abc123'`.
  final String sessionId;

  /// Versión del WebSocket Worker de Odoo. Obtenida de [OdooSession.websocketWorkerVersion].
  final String websocketWorkerVersion;

  WebSocketChannel? _channel;

  /// StreamController que expone los eventos decodificados al resto de la app.
  final _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream de notificaciones recibidas desde Odoo en tiempo real.
  ///
  /// Cada evento es un `Map<String, dynamic>` que puede contener:
  /// - `message.type` — tipo de evento (e.g. `'mail.message/new'`)
  /// - `message.payload` — datos del evento
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  /// `true` si el canal WebSocket está abierto y conectado.
  bool get isConnected => _channel != null;

  /// Abre la conexión WebSocket y se suscribe a los [channels] indicados.
  ///
  /// Puede llamarse varias veces para reconectar o cambiar canales.
  /// Si ya estaba conectado, cierra la conexión anterior primero.
  ///
  /// ```dart
  /// ws.connect(channels: ['discuss.channel_1', 'res.partner_14']);
  /// ```
  void connect({List<String> channels = const []}) {
    // Cerrar conexión previa si existe
    _channel?.sink.close();

    final wsUrlString =
        '${baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://')}'
        '/websocket?version=$websocketWorkerVersion';

    final headers = {
      'Cookie': sessionId,
      'Origin': baseUrl,
    };

    try {
      _channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrlString),
        headers: headers,
        pingInterval: const Duration(seconds: 15),
      );

      _channel!.stream.listen(
        (message) => _handleIncomingMessage(message.toString()),
        onError: (Object error) {
          _messageController.addError(error);
        },
        onDone: () {
          _channel = null;
        },
      );

      if (channels.isNotEmpty) {
        _subscribeToChannels(channels);
      }
    } catch (e) {
      _messageController.addError(e);
    }
  }

  /// Cambia los canales suscritos en caliente sin reconectar.
  ///
  /// ```dart
  /// ws.subscribe(['discuss.channel_2', 'discuss.channel_3']);
  /// ```
  void subscribe(List<String> channels) {
    if (_channel == null) return;
    _subscribeToChannels(channels);
  }

  void _subscribeToChannels(List<String> channels) {
    final subscribeEvent = {
      'event_name': 'subscribe',
      'data': {
        'channels': channels,
        'last': 0,
      },
    };
    _channel!.sink.add(jsonEncode(subscribeEvent));
  }

  void _handleIncomingMessage(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        for (final notification in decoded) {
          if (notification is Map<String, dynamic>) {
            _messageController.add(notification);
          }
        }
      } else if (decoded is Map<String, dynamic>) {
        _messageController.add(decoded);
      }
    } catch (_) {
      // Silenciar mensajes no parseables
    }
  }

  /// Cierra la conexión WebSocket y el stream de mensajes.
  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _messageController.close();
  }
}
