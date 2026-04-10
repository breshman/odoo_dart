import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class OdooRealtimeClient {
  final String baseUrl;
  final String sessionId;
  WebSocketChannel? _channel;

  // Odoo 18.0 suele usar esta versión, pero puede cambiar.
  // Es más seguro hacerse pasar por un cliente sin User-Agent (ver abajo).
  final String odooVersion = "18.0-3";

  OdooRealtimeClient({required this.baseUrl, required this.sessionId});

  void connect() {
    // 1. Construir la URL
    // Nota: Odoo espera el parámetro 'version' si detecta un User-Agent de navegador.
    final uri = Uri.parse('$baseUrl/websocket?version=$odooVersion');
    final wsUrl = uri.replace(scheme: uri.scheme == 'https' ? 'wss' : 'ws');

    // 2. Configurar Headers Críticos
    // El header 'Cookie' es OBLIGATORIO para que Odoo sepa quién eres.
    // Omitir 'User-Agent' o usar uno personalizado ayuda a evitar,
    // que Odoo te desconecte por 'Version Outdated'.
    final headers = {
      'Cookie': sessionId,
      // 'User-Agent': '' // A veces necesario vaciarlo para evitar chequeos de versión de Odoo
    };

    try {
      _channel = IOWebSocketChannel.connect(
        wsUrl,
        headers: headers,
        pingInterval: Duration(seconds: 15), // Mantener conexión viva
      );

      print("Conectando al socket...");

      // 3. Escuchar mensajes
      _channel!.stream.listen(
        (message) {
          _handleIncomingMessage(message.toString());
        },
        onError: (error) => print("Error WS: $error"),
        onDone: () => print("Socket cerrado."),
      );

      // 4. Suscribirse a canales inmediatamente después de conectar
      // Los canales suelen ser strings como 'mail.channel_1', 'res.partner_14', etc.
      _subscribeToChannels(['discuss.channel_1', 'discuss.channel_10']);
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
    // Odoo envía un array de notificaciones
    try {
      // final List<dynamic> notifications = jsonDecode(jsonString);

      // for (var notification in notifications) {
      // Estructura típica: {"id": 123, "message": {"type": "...", "payload": ...}}
      // O a veces directamente el payload.
      print("Nueva notificación: $jsonString");

      // Aquí procesas el chat, p.ej. si el tipo es 'mail.message/new'
      // }
    } catch (e) {
      print("No se pudo decodificar mensaje: $jsonString");
    }
  }

  void disconnect() {
    _channel?.sink.close();
  }
}
