import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class OdooRealtimeClient {
  final String baseUrl;
  final String sessionId;
  final String websocketWorkerVersion;

  WebSocketChannel? _channel;

  // StreamController para exponer los eventos decodificados al resto de la App
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  OdooRealtimeClient({
    required this.baseUrl,
    required this.sessionId,
    required this.websocketWorkerVersion,
  });

  void connect({List<String> channels = const []}) {
    // 1. Construir la URL
    // Construimos como String puro y anexando la versión exacta del Worker WebSocket exigida por Odoo.
    final wsUrlString =
        '${baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://')}/websocket?version=$websocketWorkerVersion';

    // 2. Configurar Headers Críticos
    // El header 'Cookie' es OBLIGATORIO para que Odoo sepa quién eres.
    final headers = {
      'Cookie': sessionId,
      'Origin': baseUrl, // Muchas veces Odoo bloquea la solicitud HTTP 400 si falta el Origin
    };

    try {
      _channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrlString),
        headers: headers,
        pingInterval: const Duration(seconds: 15), // Mantener conexión viva
      );

      // 3. Escuchar mensajes
      _channel!.stream.listen(
        (message) {
          _handleIncomingMessage(message.toString());
        },
        onError: (error) => print("Error WS: $error"),
        onDone: () => print("Socket cerrado."),
      );

      // 4. Suscribirse a canales inmediatamente después de conectar
      // Los canales suelen ser strings como 'discuss.channel_1', 'res.partner_14', etc.
      if (channels.isNotEmpty) {
        _subscribeToChannels(channels);
      }
    } catch (e) {
      print("Excepción conectando: $e");
    }
  }

  void _subscribeToChannels(List<String> channels) {
    if (_channel == null) return;

    // Payload específico que espera Odoo (verificado en websocket_worker.js)
    final subscribeEvent = {
      "event_name": "subscribe",
      "data": {
        "channels": channels,
        "last": 0 // Último ID de notificación recibido (0 para empezar)
      }
    };

    _channel!.sink.add(jsonEncode(subscribeEvent));
    print("Suscripción enviada: $channels");
  }

  void _handleIncomingMessage(String jsonString) {
    try {
      // Odoo envía un array de notificaciones
      final notifications = jsonDecode(jsonString) as List<dynamic>;

      for (final notification in notifications) {
        if (notification is Map<String, dynamic>) {
          _messageController.add(notification);
        } else {
          print("No se pudo decodificar mensaje: $notification");
        }
      }
    } catch (e) {
      print("No se pudo decodificar mensaje: $jsonString");
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _messageController.close();
  }
}
