// ============================================================
//  odoo_base_model.dart & architecture
//  Clase base y arquitectura SOLID para Odoo.
// ============================================================

import 'network/model/base_model.dart';
import 'network/params/odoo_rpc_params.dart';

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
}

/// Repositorio genérico que implementa todas las operaciones CRUD.
/// El generador creará una sub-clase tipada de esto para cada modelo.
abstract class OdooRepository<T extends OdooBaseModel> {
  final OdooClient client;
  final String modelName;
  final OdooSpec specification;
  final T Function(Map<String, dynamic>) fromJson;

  const OdooRepository({
    required this.client,
    required this.modelName,
    required this.specification,
    required this.fromJson,
  });

  /// Realiza búsquedas usando dominio y retorna solo IDs.
  Future<List<int>> searchIds({
    OdooDomain domain = const [],
    int limit = 80,
    int offset = 0,
    String? order,
  }) async {
    final result = await client.callKwRaw(
      model: modelName,
      method: 'search',
      args: [domain],
      kwargs: {'limit': limit, 'offset': offset, if (order != null) 'order': order, 'context': {}},
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
  }) async {
    final result = await client.callKwRaw(
      model: modelName,
      method: 'web_search_read',
      args: [],
      kwargs: {
        'domain': domain,
        'specification': specification,
        'limit': limit,
        'offset': offset,
        if (order != null) 'order': order,
        'count_limit': countLimit ?? (limit + offset + 1),
        'context': {},
      },
    ) as Map<String, dynamic>;

    final records = List<Map<String, dynamic>>.from(
      result['records'] as List,
    ).map(fromJson).toList();
    final length = (result['length'] as num).toInt();
    return (records: records, length: length);
  }

  /// Lee un conjunto de IDs y retorna los registros completos.
  Future<List<T>> read(List<int> ids) async {
    if (ids.isEmpty) return [];
    final result = await client.callKwRaw(
      model: modelName,
      method: 'web_read',
      args: [ids],
      kwargs: {'specification': specification, 'context': {}},
    );
    return List<Map<String, dynamic>>.from(result as List).map(fromJson).toList();
  }

  /// Crea un nuevo registro en Odoo a partir de valores puritos JSON o `toOdoo().
  Future<int> create(Map<String, dynamic> values) async {
    final result = await client.callKwRaw(
      model: modelName,
      method: 'create',
      args: [values],
      kwargs: {'context': {}},
    );
    return (result as num).toInt();
  }

  /// Actualiza los registros especificados en `ids` pasándoles los nuevos campos `values`.
  Future<bool> write(List<int> ids, Map<String, dynamic> values) async {
    if (ids.isEmpty) return true;
    final result = await client.callKwRaw(
      model: modelName,
      method: 'write',
      args: [ids, values],
      kwargs: {'context': {}},
    );
    return result as bool;
  }

  /// Borra un número de registros.
  Future<bool> unlink(List<int> ids) async {
    if (ids.isEmpty) return true;
    final result = await client.callKwRaw(
      model: modelName,
      method: 'unlink',
      args: [ids],
      kwargs: {'context': {}},
    );
    return result as bool;
  }

  /// Guarda registros usando web_save asegurando tipado mediante OdooWriteParams
  Future<List<T>> webSave<V>(OdooWriteParams<T, V> params) async {
    final result = await client.callKwRaw(
      model: modelName,
      method: 'web_save',
      args: [params.ids, params.toJson(params.values)],
      kwargs: {'specification': specification, 'context': {}},
    );
    return List<Map<String, dynamic>>.from(result as List).map<T>(params.fromJsonT).toList();
  }
}
