// ============================================================
//  odoo_base_model.dart & architecture
//  Clase base y arquitectura SOLID para Odoo.
// ============================================================

import '../odoo_core.dart';

// ─── Tipos auxiliares ────────────────────────────────────────

typedef OdooDomain = List<List<dynamic>>;
typedef OdooSpec = Object; // Acepta Map<String, dynamic> o SpecificationBuilder

/// Interfaz base generada para construir especificaciones tipadas.
// ignore: one_member_abstracts
abstract class SpecificationBuilder {
  Map<String, dynamic> build();
}

Map<String, dynamic> resolveOdooSpec(
    OdooSpec? spec, Map<String, dynamic> defaultSpec) {
  if (spec == null) return defaultSpec;
  if (spec is SpecificationBuilder) return spec.build();
  if (spec is Map<String, dynamic>) return spec;
  if (spec is Map) return Map<String, dynamic>.from(spec);
  return defaultSpec;
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
    final effectiveSpec =
        resolveOdooSpec(specification, resolveOdooSpec(this.specification, {}));
    final result = await client.callKwRaw(
      model: modelName,
      method: 'web_search_read',
      args: [],
      kwargs: {
        'domain': domain,
        'specification': effectiveSpec,
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
    final effectiveSpec =
        resolveOdooSpec(specification, resolveOdooSpec(this.specification, {}));
    final sanitizedValues = _normalizeValues(values);
    final result = await client.callKwRaw(
      model: modelName,
      method: 'web_save',
      args: [ids, sanitizedValues],
      kwargs: {'specification': effectiveSpec, 'context': context ?? {}},
    );
    return List<Map<String, dynamic>>.from(result as List)
        .map<T>(fromJson)
        .toList();
  }

  /// Crea un nuevo registro en Odoo 16/17/18+ usando `web_save` con lista de IDs vacía.
  ///
  /// A diferencia de [create], que solo retorna el ID entero, [webCreate] crea y
  /// retorna directamente la entidad [T] completamente tipada con los campos
  /// de la [specification] en una sola llamada de red (estándar moderno de Odoo).
  Future<T> webCreate({
    required Map<String, dynamic> values,
    Map<String, dynamic>? context,
    OdooSpec? specification,
  }) async {
    final records = await webSave(
      values: values,
      ids: const [],
      context: context,
      specification: specification,
    );
    if (records.isEmpty) {
      throw StateError('web_save no retornó registros al crear en $modelName.');
    }
    return records.first;
  }

  /// Lee un conjunto de IDs y retorna los registros completos.
  Future<List<T>> read(
    List<int> ids, {
    Map<String, dynamic>? context,
    OdooSpec? specification,
  }) async {
    if (ids.isEmpty) return [];
    final effectiveSpec =
        resolveOdooSpec(specification, resolveOdooSpec(this.specification, {}));
    final result = await client.callKwRaw(
      model: modelName,
      method: 'web_read',
      args: [ids],
      kwargs: {'specification': effectiveSpec, 'context': context ?? {}},
    );
    return List<Map<String, dynamic>>.from(result as List)
        .map(fromJson)
        .toList();
  }

  /// Crea un nuevo registro en Odoo a partir de valores puritos JSON o `toOdoo()`.
  Future<int> create(
    Map<String, dynamic> values, {
    Map<String, dynamic>? context,
  }) async {
    final sanitizedValues = _normalizeValues(values);
    final result = await client.callKwRaw(
      model: modelName,
      method: 'create',
      args: [sanitizedValues],
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
    final sanitizedValues = _normalizeValues(values);
    final result = await client.callKwRaw(
      model: modelName,
      method: 'write',
      args: [ids, sanitizedValues],
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

  Future<RpcResponse<R>> callRpc<R>({
    required String path,
    required R Function(Object? json) fromJsonT,
    Map<String, dynamic>? params,
  }) async {
    return client.callRpc<R>(path: path, fromJsonT: fromJsonT, params: params);
  }

  /// Normaliza mapas de valores convirtiendo instancias de [OdooCommand] a listas JSON tupla.
  Map<String, dynamic> _normalizeValues(Map<String, dynamic> values) {
    final normalized = <String, dynamic>{};
    values.forEach((key, val) {
      if (val is List) {
        normalized[key] = val.map((item) {
          if (item is OdooCommand) return item.toList();
          return item;
        }).toList();
      } else if (val is OdooCommand) {
        normalized[key] = [val.toList()];
      } else {
        normalized[key] = val;
      }
    });
    return normalized;
  }
}

/// Comandos ORM estándar de Odoo para manipulación de relaciones x2many (`One2many` y `Many2many`).
///
/// Equivalente estricto a `odoo.fields.Command` en Odoo 16, 17, 18 y 19+:
/// - [create]: `(0, 0, values)` crea un nuevo registro relacionado y lo vincula.
/// - [update]: `(1, id, values)` actualiza un registro relacionado existente.
/// - [delete]: `(2, id, 0)` borra permanentemente el registro de la base de datos.
/// - [unlink]: `(3, id, 0)` desvincula el registro sin borrarlo de la base de datos.
/// - [link]: `(4, id, 0)` vincula un registro existente.
/// - [clear]: `(5, 0, 0)` desvincula todos los registros relacionados.
/// - [set]: `(6, 0, [ids])` reemplaza la lista completa de registros vinculados.
class OdooCommand {
  const OdooCommand(this.code, [this.id = 0, this.value = 0]);

  /// Código numérico de comando Odoo (0 a 6).
  final int code;

  /// ID del registro objetivo (o 0 si aplica a nuevo/global).
  final int id;

  /// Carga de datos asociada (Map con valores, lista de IDs o 0).
  final dynamic value;

  // ── Códigos estándar de odoo.fields.Command ────────────────────────────
  static const int createCode = 0;
  static const int updateCode = 1;
  static const int deleteCode = 2;
  static const int unlinkCode = 3;
  static const int linkCode = 4;
  static const int clearCode = 5;
  static const int setCode = 6;

  // ── Métodos estáticos de conveniencia (retornan List<dynamic> directa) ──
  /// (0, 0, values) — Crea un nuevo registro relacionado y lo vincula.
  static List<dynamic> create(Map<String, dynamic> values) =>
      [createCode, 0, values];

  /// (1, id, values) — Actualiza un registro relacionado existente.
  static List<dynamic> update(int id, Map<String, dynamic> values) =>
      [updateCode, id, values];

  /// (2, id, 0) — Elimina el registro de la base de datos y lo desvincula.
  static List<dynamic> delete(int id) => [deleteCode, id, 0];

  /// (3, id, 0) — Desvincula el registro sin eliminarlo de la base de datos.
  static List<dynamic> unlink(int id) => [unlinkCode, id, 0];

  /// (4, id, 0) — Vincula un registro ya existente.
  static List<dynamic> link(int id) => [linkCode, id, 0];

  /// (5, 0, 0) — Desvincula todos los registros de la relación.
  static List<dynamic> clear() => [clearCode, 0, 0];

  /// (6, 0, ids) — Reemplaza todos los registros vinculados por la lista de IDs especificada.
  static List<dynamic> set(List<int> ids) => [setCode, 0, ids];

  // ── Factory constructors para uso tipado como objeto OdooCommand ───────
  factory OdooCommand.createRecord(Map<String, dynamic> values) =>
      OdooCommand(createCode, 0, values);

  factory OdooCommand.updateRecord(int id, Map<String, dynamic> values) =>
      OdooCommand(updateCode, id, values);

  factory OdooCommand.deleteRecord(int id) =>
      OdooCommand(deleteCode, id, 0);

  factory OdooCommand.unlinkRecord(int id) =>
      OdooCommand(unlinkCode, id, 0);

  factory OdooCommand.linkRecord(int id) =>
      OdooCommand(linkCode, id, 0);

  factory OdooCommand.clearRecords() =>
      const OdooCommand(clearCode, 0, 0);

  factory OdooCommand.setRecords(List<int> ids) =>
      OdooCommand(setCode, 0, ids);

  /// Convierte el comando a la tupla `[code, id, value]` esperada por el backend Odoo.
  List<dynamic> toList() => [code, id, value];

  /// Permite la serialización automática a JSON.
  List<dynamic> toJson() => toList();

  @override
  String toString() => 'OdooCommand($code, $id, $value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OdooCommand &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          id == other.id &&
          value == other.value;

  @override
  int get hashCode => Object.hash(code, id, value);
}
