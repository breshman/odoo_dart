// ============================================================
//  odoo_base_model.dart
//  Clase base para todos los modelos Odoo generados con el
//  generador de código Dart.
//
//  Uso:
//    @OdooModel(modelName: 'hr.employee')
//    class HrEmployee extends OdooBaseModel
//        with OdooSearchMixin<HrEmployee>, OdooWriteMixin<HrEmployee> {
//      ...
//    }
// ============================================================

import 'package:odoo_annotation/odoo_annotation.dart';

// ─── Tipos auxiliares ────────────────────────────────────────

/// Dominio de búsqueda Odoo.
/// Cada elemento es una lista de 3 valores: [campo, operador, valor].
/// Ejemplo: [['active', '=', true], ['name', 'ilike', 'Juan']]
typedef OdooDomain = List<List<dynamic>>;

/// Especificación de campos a traer (JSON-spec de web_read / search_read).
/// Ejemplo: {'name': {}, 'partner_id': {'fields': {'name': {}}}}
typedef OdooSpec = Map<String, dynamic>;

// ─── Clase base abstracta ────────────────────────────────────

/// Clase base de la que deben extender todos los modelos Odoo.
///
/// Incluye los campos que **siempre** devuelve Odoo 18:
///   - [id]          → identificador de BD
///   - [name]        → campo `name` del modelo (puede ser display_name)
///   - [displayName] → campo `display_name` calculado por Odoo
///   - [active]      → visibilidad del registro (por defecto true)
///
/// El generador de código detecta automáticamente que la clase
/// extiende [OdooBaseModel] y **omite** los campos base en el
/// `fromJson`, `toJson`, `copyWith` y `specification` generados,
/// ya que la base los maneja por su cuenta.
abstract class OdooBaseModel {
  /// Identificador único del registro en la base de datos.
  /// Odoo siempre lo devuelve como entero.
  final int id;

  /// Campo `name` del modelo. Puede estar vacío si el modelo
  /// no define `_rec_name` (Odoo rellena con el id en ese caso).
  final String name;

  /// Campo calculado `display_name`. Nullable porque no siempre
  /// se solicita en la especificación de campos.
  final String? displayName;

  /// Controla si el registro es visible en búsquedas normales.
  /// Cuando es `false` el registro está archivado.
  final bool active;

  const OdooBaseModel({
    required this.id,
    required this.name,
    this.displayName,
    this.active = true,
  });

  // ── Serialización base ──────────────────────────────────────

  /// Parsea los campos base desde el JSON de Odoo.
  /// Los modelos concretos llaman a este método en su propio
  /// `fromJson` para no repetir la lógica.
  ///
  /// ```dart
  /// factory HrEmployee.fromJson(Map<String, dynamic> json) {
  ///   final base = OdooBaseModel.baseFromJson(json);
  ///   return HrEmployee(
  ///     id:          base.id,
  ///     name:        base.name,
  ///     displayName: base.displayName,
  ///     active:      base.active,
  ///     // ... campos propios ...
  ///   );
  /// }
  /// ```
  static ({int id, String name, String? displayName, bool active}) baseFromJson(
      Map<String, dynamic> json) {
    return (
      id: json['id'] == false || json['id'] == null ? 0 : (json['id'] as num).toInt(),
      name: json['name'] == false || json['name'] == null ? '' : (json['name'] as String),
      displayName: json['display_name'] == false || json['display_name'] == null
          ? null
          : (json['display_name'] as String),
      active: json['active'] is bool ? json['active'] as bool : true,
    );
  }

  /// Serializa los campos base al formato Odoo (o JSON puro).
  ///
  /// Si [toOdoo] es true se excluye el [id] (Odoo no acepta
  /// el id en el cuerpo del write/create).
  Map<String, dynamic> baseToJson({bool toOdoo = false}) {
    return {
      if (!toOdoo) 'id': id,
      'name': name,
      if (displayName != null) 'display_name': displayName,
      'active': active,
    };
  }

  // ── Especificación de campos base ───────────────────────────

  /// Campos base que siempre se incluyen en la `specification`
  /// de web_read / search_read.
  ///
  /// Los modelos concretos fusionan esto con su propia spec:
  /// ```dart
  /// static const specification = {
  ///   ...OdooBaseModel.baseSpecification,
  ///   'job_id': {'fields': {'name': {}}},
  /// };
  /// ```
  static const Map<String, dynamic> baseSpecification = {
    'id': {},
    'name': {},
    'display_name': {},
    'active': {},
  };

  @override
  String toString() => '${runtimeType}(id: $id, name: $name, active: $active)';
}

// ─── Mixin de lectura / búsqueda ─────────────────────────────

/// Agrega a un modelo los métodos de consulta más usados de Odoo:
///   - [search]      → ids que cumplen el dominio
///   - [searchFetch] → registros completos (web_search_read)
///   - [read]        → registros por ids (web_read)
///
/// **Requiere** que la clase concreta implemente [fromJson]
/// y exponga la constante `specification`.
///
/// ```dart
/// class HrEmployee extends OdooBaseModel
///     with OdooSearchMixin<HrEmployee> { ... }
/// ```
mixin OdooSearchMixin<T extends OdooBaseModel> on OdooBaseModel {
  // La clase concreta debe exponer estos dos miembros.
  // Como Dart no permite `abstract static`, se delega al llamador.
  // Ver [OdooRepository] para un patrón más ergonómico.

  /// Construye la URL base del endpoint JSON-RPC de Odoo.
  String get odooBaseUrl;

  /// Session id / headers necesarios para autenticar la petición.
  Map<String, String> get odooHeaders;

  // ── Helpers de bajo nivel ───────────────────────────────────

  /// Llama a `env[model].search(domain)` y devuelve los ids.
  ///
  /// [modelName]  → nombre técnico del modelo (ej. 'hr.employee')
  /// [domain]     → lista de triples Odoo
  /// [limit]      → límite de resultados (0 = sin límite)
  /// [offset]     → desplazamiento para paginación
  /// [order]      → campo de ordenación (ej. 'name asc')
  static Future<List<int>> searchIds({
    required String baseUrl,
    required Map<String, String> headers,
    required String modelName,
    OdooDomain domain = const [],
    int limit = 80,
    int offset = 0,
    String? order,
  }) async {
    final body = {
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'model': modelName,
        'method': 'search',
        'args': [domain],
        'kwargs': {
          'limit': limit,
          'offset': offset,
          if (order != null) 'order': order,
          'context': {},
        },
      },
    };
    final result = await _rpc(baseUrl, headers, body);
    return List<int>.from(result as List);
  }

  /// Llama a `web_search_read` → registros completos con paginación.
  ///
  /// Equivalente al botón "buscar" en la vista lista de Odoo.
  static Future<({List<Map<String, dynamic>> records, int length})> searchFetch({
    required String baseUrl,
    required Map<String, String> headers,
    required String modelName,
    required OdooSpec specification,
    OdooDomain domain = const [],
    int limit = 80,
    int offset = 0,
    String? order,
    String? countLimit,
  }) async {
    final body = {
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'model': modelName,
        'method': 'web_search_read',
        'args': [],
        'kwargs': {
          'domain': domain,
          'specification': specification,
          'limit': limit,
          'offset': offset,
          if (order != null) 'order': order,
          'count_limit': countLimit ?? (limit + offset + 1),
          'context': {},
        },
      },
    };
    final result = await _rpc(baseUrl, headers, body) as Map<String, dynamic>;
    final records = List<Map<String, dynamic>>.from(result['records'] as List);
    final length = (result['length'] as num).toInt();
    return (records: records, length: length);
  }

  /// Llama a `web_read` → registros por ids.
  ///
  /// Equivalente a abrir una lista de registros por su id.
  static Future<List<Map<String, dynamic>>> read({
    required String baseUrl,
    required Map<String, String> headers,
    required String modelName,
    required List<int> ids,
    required OdooSpec specification,
  }) async {
    final body = {
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'model': modelName,
        'method': 'web_read',
        'args': [ids],
        'kwargs': {
          'specification': specification,
          'context': {},
        },
      },
    };
    final result = await _rpc(baseUrl, headers, body);
    return List<Map<String, dynamic>>.from(result as List);
  }

  // ── RPC helper ──────────────────────────────────────────────

  static Future<dynamic> _rpc(
    String baseUrl,
    Map<String, String> headers,
    Map<String, dynamic> body,
  ) async {
    // Importar dart:convert y http en el proyecto consumidor.
    // Esta implementación es un placeholder que el equipo puede
    // sustituir por su cliente HTTP preferido (dio, http, etc.).
    throw UnimplementedError(
      'Implementa _rpc usando el cliente HTTP de tu proyecto. '
      'Ejemplo con el paquete `http`:\n'
      '  final res = await http.post(\n'
      '    Uri.parse("\$baseUrl/web/dataset/call_kw"),\n'
      '    headers: {...headers, "Content-Type": "application/json"},\n'
      '    body: jsonEncode(body),\n'
      '  );\n'
      '  final data = jsonDecode(res.body);\n'
      '  if (data["error"] != null) throw OdooRpcException(data["error"]);\n'
      '  return data["result"];\n',
    );
  }
}

// ─── Mixin de escritura ──────────────────────────────────────

/// Agrega a un modelo los métodos de escritura básicos:
///   - [odooCreate] → crea un nuevo registro
///   - [odooWrite]  → actualiza campos de un registro existente
///   - [odooUnlink] → elimina registros por ids
mixin OdooWriteMixin<T extends OdooBaseModel> on OdooBaseModel {
  String get odooBaseUrl;
  Map<String, String> get odooHeaders;

  /// Crea un registro en Odoo y devuelve el nuevo id.
  static Future<int> odooCreate({
    required String baseUrl,
    required Map<String, String> headers,
    required String modelName,
    required Map<String, dynamic> values,
  }) async {
    final body = {
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'model': modelName,
        'method': 'create',
        'args': [values],
        'kwargs': {'context': {}},
      },
    };
    final result = await OdooSearchMixin._rpc(baseUrl, headers, body);
    return (result as num).toInt();
  }

  /// Actualiza [ids] con los [values] dados. Devuelve `true` si tuvo éxito.
  static Future<bool> odooWrite({
    required String baseUrl,
    required Map<String, String> headers,
    required String modelName,
    required List<int> ids,
    required Map<String, dynamic> values,
  }) async {
    final body = {
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'model': modelName,
        'method': 'write',
        'args': [ids, values],
        'kwargs': {'context': {}},
      },
    };
    final result = await OdooSearchMixin._rpc(baseUrl, headers, body);
    return result as bool;
  }

  /// Elimina los registros con los [ids] dados.
  static Future<bool> odooUnlink({
    required String baseUrl,
    required Map<String, String> headers,
    required String modelName,
    required List<int> ids,
  }) async {
    final body = {
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'model': modelName,
        'method': 'unlink',
        'args': [ids],
        'kwargs': {'context': {}},
      },
    };
    final result = await OdooSearchMixin._rpc(baseUrl, headers, body);
    return result as bool;
  }
}

// ─── Mixin de timestamps ─────────────────────────────────────

/// Agrega los campos de auditoría que Odoo pone en cada modelo
/// que hereda de `mail.thread` o simplemente tiene `_log_access = True`:
///   - [createDate] → fecha de creación (UTC, convertida a local)
///   - [writeDate]  → fecha de última modificación
///   - [createUid]  → id del usuario que creó el registro
///   - [writeUid]   → id del usuario que lo modificó por última vez
///
/// Es opcional: úsalo sólo en modelos que realmente tengan estos campos.
mixin OdooTimestampMixin on OdooBaseModel {
  DateTime? get createDate;
  DateTime? get writeDate;
  int? get createUid;
  int? get writeUid;

  /// Parsea los campos de timestamp desde JSON Odoo.
  static ({
    DateTime? createDate,
    DateTime? writeDate,
    int? createUid,
    int? writeUid,
  }) timestampsFromJson(Map<String, dynamic> json) {
    DateTime? parseOdooDate(dynamic raw) {
      if (raw == false || raw == null) return null;
      return DateTime.parse(
        (raw as String).replaceFirst(' ', 'T') + 'Z',
      ).toLocal();
    }

    int? parseUid(dynamic raw) {
      if (raw == false || raw == null) return null;
      if (raw is List && raw.isNotEmpty) return (raw[0] as num).toInt();
      if (raw is num) return raw.toInt();
      return null;
    }

    return (
      createDate: parseOdooDate(json['create_date']),
      writeDate: parseOdooDate(json['write_date']),
      createUid: parseUid(json['create_uid']),
      writeUid: parseUid(json['write_uid']),
    );
  }

  /// Spec de campos de timestamp para incluir en [OdooBaseModel.baseSpecification].
  static const Map<String, dynamic> timestampSpecification = {
    'create_date': {},
    'write_date': {},
    'create_uid': {
      'fields': {'id': {}, 'name': {}}
    },
    'write_uid': {
      'fields': {'id': {}, 'name': {}}
    },
  };
}

// ─── Excepción RPC ───────────────────────────────────────────

class OdooRpcException implements Exception {
  final Map<String, dynamic> error;

  const OdooRpcException(this.error);

  String get message =>
      (error['data']?['message'] as String?) ??
      (error['message'] as String?) ??
      'Error desconocido de Odoo';

  String get code => error['code']?.toString() ?? '';

  @override
  String toString() => 'OdooRpcException($code): $message';
}
