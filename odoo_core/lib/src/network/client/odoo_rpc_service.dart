// filepath: lib/app/common/api_factory/odoo/services/odoo_rpc_service.dart
import 'package:dio/dio.dart';

import '../../odoo_base.dart';
import '../exceptions/odoo_exception.dart';
import '../params/odoo_rpc_params.dart';
import '../params/rpc_payload.dart';
import '../responses/rpc_response.dart';

/// Servicio RPC reutilizable para Odoo, usando Dio.
class OdooRpcService implements OdooClient {
  factory OdooRpcService({Dio? dio}) {
    _instance ??= OdooRpcService._internal(dio ?? Dio());
    return _instance!;
  }

  OdooRpcService._internal(this._dio);
  static OdooRpcService? _instance;

  final Dio _dio;

  /// Contexto dinámico para las llamadas RPC (idioma, zona horaria, etc).
  UserContext odooContext = const UserContext(lang: 'en_US', tz: 'America/Mexico_City', uid: 0);

  /// Permite actualizar el contexto dinámicamente sin chocar con BuildContext.
  void updateOdooContext(UserContext? newContext) {
    odooContext = newContext ?? odooContext;
  }

  /// Llama a cualquier método de modelo Odoo vía RPC.
  ///
  /// [model]: nombre del modelo Odoo (por ejemplo, 'res.partner').
  ///
  /// [method]: nombre del método a invocar (por ejemplo, 'search_read', 'create', etc).
  ///
  /// [args]: lista de argumentos posicionales para el método (opcional).
  ///
  /// [kwargs]: mapa de argumentos nombrados para el método (opcional).
  ///
  /// [fromJsonT]: función para convertir el resultado JSON a tipo T.
  ///
  /// Devuelve un [RpcResponse<T>] con el resultado o error de la llamada.
  Future<RpcResponse<T>> callKw<T>({
    required String model,
    required String method,
    List<dynamic>? args,
    Map<String, dynamic>? kwargs,
    required T Function(Object? json) fromJsonT,
  }) async {
    // Inyectar el odooContext automáticamente al igual que callKwRaw
    final finalKwargs = Map<String, dynamic>.from(kwargs ?? {});
    final contextMap = (finalKwargs['context'] as Map<String, dynamic>?) ?? {};
    finalKwargs['context'] = <String, dynamic>{...odooContext.toJson(), ...contextMap};

    final payload = {
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {'model': model, 'method': method, 'args': args ?? [], 'kwargs': finalKwargs},
    };
    final response = await _dio.post<Map<String, dynamic>>(
      '/web/dataset/call_kw/$model/$method',
      data: payload,
    );
    return RpcResponse<T>.fromJson(response.data as Map<String, dynamic>, fromJsonT);
  }

  @override
  Future<dynamic> callKwRaw({
    required String model,
    required String method,
    List<dynamic> args = const [],
    Map<String, dynamic> kwargs = const {},
  }) async {
    // Inyectar el odooContext automáticamente preservando contextos superpuestos
    final finalKwargs = Map<String, dynamic>.from(kwargs);
    final contextMap = (finalKwargs['context'] as Map<String, dynamic>?) ?? {};
    finalKwargs['context'] = <String, dynamic>{...odooContext.toJson(), ...contextMap};

    final payload = {
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {'model': model, 'method': method, 'args': args, 'kwargs': finalKwargs},
    };
    final response = await _dio.post<Map<String, dynamic>>(
      '/web/dataset/call_kw/$model/$method',
      data: payload,
    );
    final data = response.data!;
    if (data.containsKey('error')) {
      throw OdooException.fromJson(data['error'] as Map<String, dynamic>);
    }
    return data['result'];
  }

  /// Llama a un endpoint RPC personalizado de Odoo.
  ///
  /// [path]: ruta del endpoint (por ejemplo, '/web/dataset/call_kw/...').
  /// [params]: parámetros a enviar en la petición (opcional).
  /// [fromJsonT]: función para convertir el resultado JSON a tipo T.
  ///
  /// Devuelve un [RpcResponse<T>] con el resultado o error de la llamada.
  Future<RpcResponse<T>> callRpc<T>({
    required String path,
    Map<String, dynamic>? params,
    required T Function(Object? json) fromJsonT,
  }) async {
    final payload = {'jsonrpc': '2.0', 'method': 'call', 'params': params ?? {}};
    final response = await _dio.post<Map<String, dynamic>>(path, data: payload);
    return RpcResponse<T>.fromJson(response.data as Map<String, dynamic>, fromJsonT);
  }

  /// Llama a un endpoint RPC personalizado de Odoo usando un [RpcPayload] tipado.
  ///
  /// [path]: ruta del endpoint (por ejemplo, '/web/session/authenticate').
  /// [payload]: objeto RpcPayload<T> con los datos a enviar.
  /// [fromJsonT]: función para convertir el resultado JSON a tipo T.
  ///
  /// Devuelve un [RpcResponse<T>] con el resultado o error de la llamada.
  Future<RpcResponse<T>> callRpcPayload<T, P>({
    required String path,
    required RpcPayload<P> payload,
    required T Function(Object? json) fromJsonT,
    required Object? Function(P value) toJsonP,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(path, data: payload.toJson(toJsonP));
    return RpcResponse<T>.fromJson(response.data as Map<String, dynamic>, fromJsonT);
  }

  /// Llama a un endpoint GET y parsea la respuesta usando el tipo T.
  ///
  /// [T]: Tipo de dato que retorna (por ejemplo, Map<String, MenusApp>).
  /// [path]: Ruta del endpoint.
  /// [fromJsonT]: Función para convertir el JSON recibido al tipo T.
  Future<T?> getCall<T>({required String path, required T Function(Object? json) fromJsonT}) async {
    final response = await _dio.get<Map<String, dynamic>>(path);
    return response.data != null ? fromJsonT(response.data) : null;
  }

  /// Helper para obtener contenido en texto plano (como ZPL)
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
}
