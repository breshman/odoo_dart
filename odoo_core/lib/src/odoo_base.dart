// ============================================================
//  odoo_base_model.dart & architecture
//  Clase base y arquitectura SOLID para Odoo.
// ============================================================

import '../odoo_core.dart';
import 'network/model/base_model.dart';

// ─── Tipos auxiliares ────────────────────────────────────────

typedef OdooDomain = List<List<dynamic>>;
typedef OdooSpec = Map<String, dynamic>;

// ─── Arquitectura SOLID (Repositorios) ───────────────────────

/// Interfaz del cliente para no acoplar el generador a `http` o `dio`.
/// Deberás implementar esta clase en tu proyecto conectando con tu cliente preferido.
abstract class OdooClient {
  Future<dynamic> callKwRaw({
    required String model,
    required String method,
    List args = const [],
    Map<String, dynamic> kwargs = const {},
  });

  Future<RpcResponse<T>> callRpc<T>({
    required String path,
    required T Function(Object? json) fromJsonT,
    Map<String, dynamic>? params,
  });
}

/// Repositorio genérico que implementa todas las operaciones CRUD.
/// El generador creará una sub-clase tipada de esto para cada modelo.
abstract class OdooRepository<T extends OdooBaseModel> {
  const OdooRepository({
    required this.client,
    required this.modelName,
    required this.specification,
    required this.fromJson,
  });

  final OdooClient client;
  final String modelName;
  final OdooSpec specification;
  final T Function(Map<String, dynamic>) fromJson;

  /// Realiza búsquedas usando dominio y retorna solo IDs.
  Future<List<int>> searchIds({
    OdooDomain domain = const [],
    int limit = 80,
    int offset = 0,
    String? order,
    Map<String, dynamic>? context,
  }) async {
    final result = await client.callKwRaw(
      model: modelName,
      method: 'search',
      args: [domain],
      kwargs: {
        'limit': limit,
        'offset': offset,
        if (order != null) 'order': order,
        'context': context ?? {}
      },
    );
    return List<int>.from(result as List);
  }

  /// Realiza búsquedas con dominio y retorna los registros tipados listos para usar.
  Future<({List<T> records, int length})> searchFetch({
    OdooDomain domain = const [],
    int limit = 80,
    int offset = 0,
    String? order,
    String? countLimit,
    Map<String, dynamic>? context,
    OdooSpec? specification,
  }) async {
    final result = await client.callKwRaw(
      model: modelName,
      method: 'web_search_read',
      args: [],
      kwargs: {
        'domain': domain,
        'specification': specification ?? this.specification,
        'limit': limit,
        'offset': offset,
        if (order != null) 'order': order,
        'count_limit': countLimit ?? (limit + offset + 1),
        'context': context ?? {},
      },
    ) as Map<String, dynamic>;

    final records = List<Map<String, dynamic>>.from(
      result['records'] as List,
    ).map(fromJson).toList();
    final length = (result['length'] as num).toInt();
    return (records: records, length: length);
  }

  /// Guarda registros usando web_save asegurando tipado mediante OdooWriteParams
  Future<List<T>> webSave({
    required Map<String, dynamic> values,
    required List<int> ids,
    Map<String, dynamic>? context,
    OdooSpec? specification,
  }) async {
    final result = await client.callKwRaw(
      model: modelName,
      method: 'web_save',
      args: [ids, values],
      kwargs: {
        'specification': specification ?? this.specification,
        'context': context ?? {}
      },
    );
    return List<Map<String, dynamic>>.from(result as List)
        .map<T>(fromJson)
        .toList();
  }

  /// Lee un conjunto de IDs y retorna los registros completos.
  Future<List<T>> read(
    List<int> ids, {
    Map<String, dynamic>? context,
    OdooSpec? specification,
  }) async {
    if (ids.isEmpty) return [];
    final result = await client.callKwRaw(
      model: modelName,
      method: 'web_read',
      args: [ids],
      kwargs: {
        'specification': specification ?? this.specification,
        'context': context ?? {}
      },
    );
    return List<Map<String, dynamic>>.from(result as List)
        .map(fromJson)
        .toList();
  }

  /// Crea un nuevo registro en Odoo a partir de valores puritos JSON o `toOdoo().
  Future<int> create(
    Map<String, dynamic> values, {
    Map<String, dynamic>? context,
  }) async {
    final result = await client.callKwRaw(
      model: modelName,
      method: 'create',
      args: [values],
      kwargs: {'context': context ?? {}},
    );
    return (result as num).toInt();
  }

  /// Actualiza los registros especificados en `ids` pasándoles los nuevos campos `values`.
  Future<bool> write(
    List<int> ids,
    Map<String, dynamic> values, {
    Map<String, dynamic>? context,
  }) async {
    if (ids.isEmpty) return true;
    final result = await client.callKwRaw(
      model: modelName,
      method: 'write',
      args: [ids, values],
      kwargs: {'context': context ?? {}},
    );
    return result as bool;
  }

  /// Borra un número de registros.
  Future<bool> unlink(List<int> ids, {Map<String, dynamic>? context}) async {
    if (ids.isEmpty) return true;
    final result = await client.callKwRaw(
      model: modelName,
      method: 'unlink',
      args: [ids],
      kwargs: {'context': context ?? {}},
    );
    return result as bool;
  }

  /// Cuenta los registros que coinciden con el [domain] sin traer datos.
  ///
  /// Equivalente al método `search_count` de Odoo ORM. Mucho más eficiente
  /// que `searchFetch` cuando solo se necesita el total.
  ///
  /// ```dart
  /// final total = await partnerRepo.searchCount(
  ///   domain: [['is_company', '=', true]],
  /// );
  /// print('Hay $total empresas.');
  /// ```
  Future<int> searchCount({
    OdooDomain domain = const [],
    Map<String, dynamic>? context,
  }) async {
    final result = await client.callKwRaw(
      model: modelName,
      method: 'search_count',
      args: [domain],
      kwargs: {'context': context ?? {}},
    );
    return (result as num).toInt();
  }

  /// Invoca cualquier método de negocio de Odoo directamente desde el repositorio.
  ///
  /// Úsalo para llamadas como `action_confirm`, `button_validate`, `write_and_print`,
  /// o cualquier método Python expuesto en el modelo.
  ///
  /// [method]: nombre del método Python en el modelo.
  /// [ids]: lista de IDs sobre los que se ejecuta (puede ser vacía para métodos de clase).
  /// [args]: argumentos posicionales adicionales.
  /// [kwargs]: argumentos nombrados adicionales.
  /// [context]: contexto Odoo opcional (idioma, empresa, etc.).
  ///
  /// ```dart
  /// // Confirmar una orden de venta
  /// await saleOrderRepo.callMethod(
  ///   method: 'action_confirm',
  ///   ids: [orderId],
  /// );
  ///
  /// // Llamar un método con argumentos extra
  /// await invoiceRepo.callMethod(
  ///   method: 'action_post',
  ///   ids: [invoiceId],
  ///   context: {'move_type': 'out_invoice'},
  /// );
  /// ```
  Future<dynamic> callMethod({
    required String method,
    List<int> ids = const [],
    List<dynamic> args = const [],
    Map<String, dynamic> kwargs = const {},
    Map<String, dynamic>? context,
  }) async {
    return client.callKwRaw(
      model: modelName,
      method: method,
      args: ids.isNotEmpty ? [ids, ...args] : args,
      kwargs: {'context': context ?? {}, ...kwargs},
    );
  }

  Future<RpcResponse<T>> callRpc<T>({
    required String path,
    required T Function(Object? json) fromJsonT,
    Map<String, dynamic>? params,
  }) async {
    return client.callRpc<T>(path: path, fromJsonT: fromJsonT, params: params);
  }
}
