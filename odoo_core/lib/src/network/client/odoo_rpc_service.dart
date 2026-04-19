// filepath: lib/src/network/client/odoo_rpc_service.dart
import 'dart:async';

import 'package:dio/dio.dart';

import '../../odoo_base.dart';
import '../exceptions/odoo_exception.dart';
import '../odoo_cookie.dart';
import '../odoo_session.dart';
import '../params/odoo_rpc_params.dart';
import '../params/rpc_payload.dart';
import '../responses/rpc_response.dart';
import 'odoo_realtime_client.dart';

/// Servicio RPC reutilizable para Odoo, usando Dio.
///
/// ## Uso básico
/// ```dart
/// // Obtener la instancia singleton
/// final odoo = OdooRpcService();
///
/// // Autenticar
/// final session = await odoo.authenticate('mydb', 'admin', 'admin');
/// print(session.userName); // "Administrator"
///
/// // Verificar peticiones en curso (loading global)
/// odoo.inRequestStream.listen((loading) => showSpinner(loading));
///
/// // Al cerrar sesión
/// await odoo.destroySession();
/// OdooRpcService.reset();
/// ```
class OdooRpcService implements OdooClient {
  factory OdooRpcService({Dio? dio}) {
    _instance ??= OdooRpcService._internal(dio ?? Dio());
    return _instance!;
  }

  OdooRpcService._internal(this._dio) {
    // Interceptor para emitir estados de carga al inRequestStream
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_inRequestStreamActive) _inRequestController.add(true);
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (_inRequestStreamActive) _inRequestController.add(false);
          handler.next(response);
        },
        onError: (error, handler) {
          if (_inRequestStreamActive) _inRequestController.add(false);
          handler.next(error);
        },
      ),
    );
  }

  static OdooRpcService? _instance;
  final Dio _dio;

  /// Contexto dinámico para las llamadas RPC (idioma, zona horaria, etc).
  UserContext odooContext =
      const UserContext(lang: 'en_US', tz: 'America/Mexico_City', uid: 0);

  /// Sesión activa del usuario. Disponible después de [authenticate].
  OdooSession? _currentSession;

  /// Retorna la sesión activa, o `null` si no se ha autenticado.
  OdooSession? get currentSession => _currentSession;

  // ── inRequestStream ──────────────────────────────────────
  bool _inRequestStreamActive = false;
  final StreamController<bool> _inRequestController =
      StreamController<bool>.broadcast();

  /// Stream que emite `true` cuando comienza una petición HTTP y `false`
  /// cuando termina (con éxito o error). Útil para indicadores de carga globales.
  ///
  /// ```dart
  /// odooClient.inRequestStream.listen((isLoading) {
  ///   ref.read(globalLoadingProvider.notifier).state = isLoading;
  /// });
  /// ```
  Stream<bool> get inRequestStream {
    _inRequestStreamActive = true;
    return _inRequestController.stream;
  }

  // ── Contexto ─────────────────────────────────────────────

  /// Actualiza el contexto de usuario (idioma, zona horaria, uid).
  void updateOdooContext(UserContext? newContext) {
    odooContext = newContext ?? odooContext;
  }

  /// Crea y retorna un [OdooRealtimeClient] usando la sesión activa.
  ///
  /// Lanza [StateError] si no hay sesión activa (no se ha autenticado).
  ///
  /// La URL base y la versión del worker se extraen automáticamente de
  /// [currentSession] y de la configuración del cliente Dio.
  ///
  /// ```dart
  /// final session = await odooClient.authenticate('mydb', 'admin', 'admin');
  ///
  /// final ws = odooClient.connectRealtime();
  /// ws.connect(channels: ['discuss.channel_1']);
  ///
  /// ws.messages.listen((event) {
  ///   final type = event['message']?['type'];
  ///   print('Evento Odoo: $type');
  /// });
  ///
  /// // Al cerrar sesión:
  /// ws.disconnect();
  /// await odooClient.destroySession();
  /// ```
  OdooRealtimeClient connectRealtime() {
    final session = _currentSession;
    if (session == null || !session.isAuthenticated) {
      throw StateError(
        'No hay sesión activa. Llama a authenticate() antes de connectRealtime().',
      );
    }
    final baseUrl = _dio.options.baseUrl.isNotEmpty
        ? _dio.options.baseUrl
        : throw StateError(
            'No se ha configurado una baseUrl en el cliente Dio.');

    return OdooRealtimeClient.fromSession(
      session: session,
      baseUrl: baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl,
    );
  }

  // ── Gestión del singleton ─────────────────────────────────

  /// Destruye la instancia singleton. El próximo acceso creará una nueva.
  ///
  /// Úsalo al cambiar de servidor Odoo o después de un logout completo:
  /// ```dart
  /// await odooClient.destroySession();
  /// OdooRpcService.reset();
  /// final newClient = OdooRpcService(); // instancia fresca
  /// ```
  static void reset() {
    _instance = null;
  }

  /// Actualiza la URL base del cliente Dio en tiempo de ejecución.
  ///
  /// Útil cuando el usuario cambia de servidor sin reiniciar la app:
  /// ```dart
  /// odooClient.setBaseUrl('https://nuevo-servidor.odoo.com');
  /// ```
  void setBaseUrl(String newUrl) {
    _dio.options.baseUrl = newUrl;
  }

  // ── Sesión / Auth ─────────────────────────────────────────

  /// Autentica al usuario contra el servidor Odoo.
  ///
  /// Retorna una [OdooSession] tipada con todos los datos del usuario.
  /// La sesión queda almacenada en [currentSession] para consultas posteriores.
  ///
  /// Lanza [OdooSessionExpiredException] si las credenciales son inválidas
  /// (UID retornado como `false` por Odoo) y [OdooException] para otros errores.
  ///
  /// ```dart
  /// final session = await odooClient.authenticate('mydb', 'admin', 'admin');
  /// print('Bienvenido ${session.userName}');
  /// ```
  Future<OdooSession> authenticate(
    String db,
    String login,
    String password,
  ) async {
    final payload = {
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {'db': db, 'login': login, 'password': password},
    };

    final response = await _dio.post<Map<String, dynamic>>(
      '/web/session/authenticate',
      data: payload,
    );
    final data = response.data!;

    if (data.containsKey('error')) {
      _throwOdooError(data['error'] as Map<String, dynamic>);
    }

    final result = data['result'] as Map<String, dynamic>;

    // Odoo retorna uid: false cuando las credenciales son incorrectas
    if (result['uid'] is bool && result['uid'] == false) {
      throw const OdooSessionExpiredException(
        message: 'Authentication failed: invalid credentials',
      );
    }

    _currentSession = OdooSession.fromSessionInfo(result);

    // Si no vino el CSRF token (común en Odoo 18+ JSON RPC), intentamos obtenerlo explícitamente
    if (_currentSession!.csrfToken.isEmpty) {
      try {
        await fetchCsrfToken();
      } catch (e) {
        // No es crítico para el login, solo para uploads posteriores
        print('Warning: could not fetch CSRF token automatically: $e');
      }
    }

    // En algunos servidores Odoo (incluido RunBot) el session_id no viene en
    // el body sino sólo en el header Set-Cookie. Usamos OdooCookie (RFC 6265)
    // para extraerlo correctamente sin depender de dart:io.
    if (_currentSession!.id.isEmpty) {
      final rawCookies = response.headers['set-cookie'] ?? [];
      final cookieSessionId = OdooCookie.extractSessionId(rawCookies);
      if (cookieSessionId != null) {
        _currentSession = _currentSession!.updateSessionId(cookieSessionId);
      }
    }

    return _currentSession!;
  }

  /// Invalida la sesión actual en el servidor Odoo (logout).
  ///
  /// Aunque falle la llamada al servidor, limpia [currentSession] localmente.
  /// Combina con [reset] para una limpieza completa:
  /// ```dart
  /// await odooClient.destroySession();
  /// OdooRpcService.reset();
  /// ```
  Future<void> destroySession() async {
    try {
      await callKwRaw(
        model: 'res.users',
        method: 'check_access_rights',
        args: [],
        kwargs: {},
      );
      final payload = {
        'jsonrpc': '2.0',
        'method': 'call',
        'params': <String, dynamic>{},
      };
      await _dio.post<Map<String, dynamic>>(
        '/web/session/destroy',
        data: payload,
      );
    } on OdooException {
      // Si falla, se limpia igualmente de forma local
    } finally {
      _currentSession = null;
    }
  }

  /// Verifica si la sesión actual sigue siendo válida en el servidor.
  ///
  /// Lanza [OdooSessionExpiredException] si la sesión expiró.
  ///
  /// ```dart
  /// try {
  ///   await odooClient.checkSession();
  /// } on OdooSessionExpiredException {
  ///   // Redirigir a Login
  /// }
  /// ```
  Future<void> checkSession() async {
    final response = await callRpc(
      path: '/web/session/check',
      fromJsonT: (json) {
        if (json is Map) return json as Map<String, dynamic>;
        return null;
      },
    );
    final data = response.result;
    if (data != null && data.containsKey('error')) {
      _throwOdooError(data['error'] as Map<String, dynamic>);
    }
  }

  /// Obtiene el token CSRF del servidor.
  Future<String> fetchCsrfToken() async {
    try {
      final response = await _dio.get<String>('/web');
      final html = response.data ?? '';

      // Regex robusto para capturar:
      // csrf_token: "..."
      // "csrf_token": "..."
      // 'csrf_token': "..."
      final regex = RegExp(r'''["']?csrf_token["']?\s*:\s*["']([^"']+)["']''');
      final match = regex.firstMatch(html);
      if (match != null) {
        final token = match.group(1)!;
        if (_currentSession != null) {
          _currentSession = _currentSession!.updateCsrfToken(token);
        }
        return token;
      }
    } catch (_) {
      // Ignorar fallo
    }

    return '';
  }

  Future<OdooSession?> checkCurrentUser() async {
    try {
      final response = await callRpc(
        path: '/web/session/get_session_info',
        fromJsonT: (json) {
          if (json is Map) {
            return OdooSession.fromJson(json as Map<String, dynamic>);
          }
          return null;
        },
      );
      _currentSession = response.result;

      if (_currentSession!.csrfToken.isEmpty) {
        try {
          await fetchCsrfToken();
        } catch (e) {
          print('Warning: could not fetch CSRF token automatically: $e');
        }
      }

      return currentSession;
    } on OdooException {
      _currentSession = null;
      return null;
    }
  }

  // ── Core RPC ──────────────────────────────────────────────

  /// Llama a cualquier método de modelo Odoo vía RPC con deserialización tipada.
  ///
  /// Retorna un [RpcResponse<T>] con el resultado o el error encapsulado.
  Future<RpcResponse<T>> callKw<T>({
    required String model,
    required String method,
    List<dynamic>? args,
    Map<String, dynamic>? kwargs,
    required T Function(Object? json) fromJsonT,
  }) async {
    final finalKwargs = Map<String, dynamic>.from(kwargs ?? {});
    final contextMap = (finalKwargs['context'] as Map<String, dynamic>?) ?? {};
    finalKwargs['context'] = <String, dynamic>{
      ...odooContext.toJson(),
      ...contextMap,
    };

    final payload = {
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'model': model,
        'method': method,
        'args': args ?? [],
        'kwargs': finalKwargs,
      },
    };
    final response = await _dio.post<Map<String, dynamic>>(
      '/web/dataset/call_kw/$model/$method',
      data: payload,
    );
    return RpcResponse<T>.fromJson(
      response.data as Map<String, dynamic>,
      fromJsonT,
    );
  }

  @override
  Future<dynamic> callKwRaw({
    required String model,
    required String method,
    List<dynamic> args = const [],
    Map<String, dynamic> kwargs = const {},
  }) async {
    final finalKwargs = Map<String, dynamic>.from(kwargs);
    final contextMap = (finalKwargs['context'] as Map<String, dynamic>?) ?? {};
    finalKwargs['context'] = <String, dynamic>{
      ...odooContext.toJson(),
      ...contextMap,
    };

    final payload = {
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'model': model,
        'method': method,
        'args': args,
        'kwargs': finalKwargs,
      },
    };
    final response = await _dio.post<Map<String, dynamic>>(
      '/web/dataset/call_kw/$model/$method',
      data: payload,
    );
    final data = response.data!;
    if (data.containsKey('error')) {
      _throwOdooError(data['error'] as Map<String, dynamic>);
    }
    return data['result'];
  }

  /// Llama a un endpoint RPC personalizado de Odoo.
  ///
  /// [path]: ruta del endpoint (e.g. `/web/session/authenticate`).
  /// [params]: parámetros a enviar en la petición (opcional).
  /// [fromJsonT]: función para convertir el resultado JSON al tipo T.
  Future<RpcResponse<T>> callRpc<T>({
    required String path,
    Map<String, dynamic>? params,
    required T Function(Object? json) fromJsonT,
  }) async {
    final payload = {
      'jsonrpc': '2.0',
      'method': 'call',
      'params': params ?? {},
    };
    final response = await _dio.post<Map<String, dynamic>>(path, data: payload);
    return RpcResponse<T>.fromJson(
      response.data as Map<String, dynamic>,
      fromJsonT,
    );
  }

  /// Llama a un endpoint RPC usando un [RpcPayload] tipado.
  Future<RpcResponse<T>> callRpcPayload<T, P>({
    required String path,
    required RpcPayload<P> payload,
    required T Function(Object? json) fromJsonT,
    required Object? Function(P value) toJsonP,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: payload.toJson(toJsonP),
    );
    return RpcResponse<T>.fromJson(
      response.data as Map<String, dynamic>,
      fromJsonT,
    );
  }

  /// Llama a un endpoint GET y parsea la respuesta usando el tipo T.
  Future<T?> getCall<T>({
    required String path,
    required T Function(Object? json) fromJsonT,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(path);
    return response.data != null ? fromJsonT(response.data) : null;
  }

  /// Helper para obtener contenido en texto plano (como ZPL).
  Future<String?> getTextCall({required String path}) async {
    try {
      final response = await _dio.get<String>(
        path,
        options: Options(responseType: ResponseType.plain),
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.data is String) {
        throw e.response!.data as String;
      }
      rethrow;
    }
  }

  // ── Helper privado ────────────────────────────────────────

  /// Lanza [OdooSessionExpiredException] para code==100, o [OdooException]
  /// para cualquier otro error del servidor Odoo.
  Never _throwOdooError(Map<String, dynamic> error) {
    final code = error['code'] as int? ?? 0;
    if (code == 100) {
      throw OdooSessionExpiredException(
        message: (error['data']?['message'] as String?) ??
            (error['message'] as String?) ??
            'Session expired',
      );
    }
    throw OdooException.fromJson(error);
  }
}
