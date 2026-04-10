// ============================================================
//  odoo_base_model.dart & architecture
//  Clase base y arquitectura SOLID para Odoo.
// ============================================================

import 'network/params/odoo_rpc_params.dart';

// ─── Tipos auxiliares ────────────────────────────────────────

typedef OdooDomain = List<List<dynamic>>;
typedef OdooSpec = Map<String, dynamic>;

// ─── Clase base abstracta ────────────────────────────────────

/// Clase base de la que deben extender todos los modelos Odoo.
/// Ahora incluye soporte nativo y automático para Timestamps Odoo.
abstract class OdooBaseModel {
  final int id;
  final String name;
  final String? displayName;
  final bool active;

  // Timestamps de auditoría
  final DateTime? createDate;
  final DateTime? writeDate;
  final int? createUid;
  final int? writeUid;

  const OdooBaseModel({
    required this.id,
    required this.name,
    this.displayName,
    this.active = true,
    this.createDate,
    this.writeDate,
    this.createUid,
    this.writeUid,
  });

  // ── Serialización base ──────────────────────────────────────

  static ({
    int id,
    String name,
    String? displayName,
    bool active,
    DateTime? createDate,
    DateTime? writeDate,
    int? createUid,
    int? writeUid,
  })
  baseFromJson(Map<String, dynamic> json) {
    DateTime? parseOdooDate(dynamic raw) {
      if (raw == false || raw == null) return null;
      return DateTime.parse((raw as String).replaceFirst(' ', 'T') + 'Z').toLocal();
    }

    int? parseUid(dynamic raw) {
      if (raw == false || raw == null) return null;
      if (raw is List && raw.isNotEmpty) return (raw[0] as num).toInt();
      if (raw is num) return raw.toInt();
      return null;
    }

    return (
      id: json['id'] == false || json['id'] == null ? 0 : (json['id'] as num).toInt(),
      name: json['name'] == false || json['name'] == null ? '' : (json['name'] as String),
      displayName: json['display_name'] == false || json['display_name'] == null
          ? null
          : (json['display_name'] as String),
      active: json['active'] is bool ? json['active'] as bool : true,
      createDate: parseOdooDate(json['create_date']),
      writeDate: parseOdooDate(json['write_date']),
      createUid: parseUid(json['create_uid']),
      writeUid: parseUid(json['write_uid']),
    );
  }

  Map<String, dynamic> baseToJson({bool toOdoo = false}) {
    return {
      if (!toOdoo) 'id': id,
      'name': name,
      if (displayName != null) 'display_name': displayName,
      'active': active,
      if (createDate != null)
        'create_date': toOdoo
            ? createDate!.toUtc().toIso8601String().substring(0, 19).replaceFirst('T', ' ')
            : createDate!.toIso8601String(),
      if (writeDate != null)
        'write_date': toOdoo
            ? writeDate!.toUtc().toIso8601String().substring(0, 19).replaceFirst('T', ' ')
            : writeDate!.toIso8601String(),
      if (createUid != null) 'create_uid': createUid, // Enviar int
      if (writeUid != null) 'write_uid': writeUid,
    };
  }

  static const Map<String, dynamic> baseSpecification = {
    'id': {},
    'name': {},
    'display_name': {},
    'active': {},
    'create_date': {},
    'write_date': {},
    'create_uid': {
      'fields': {'id': {}, 'name': {}},
    },
    'write_uid': {
      'fields': {'id': {}, 'name': {}},
    },
  };

  @override
  String toString() => '${runtimeType}(id: $id, name: $name, active: $active)';
}

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
    final result =
        await client.callKwRaw(
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
            )
            as Map<String, dynamic>;

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

