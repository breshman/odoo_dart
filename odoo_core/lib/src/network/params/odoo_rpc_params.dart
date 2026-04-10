class UserContext {
  final String lang;
  final String tz;
  final int uid;
  const UserContext({this.lang = 'es_PE', this.tz = 'America/Lima', this.uid = 0});

  Map<String, dynamic> toJson() => {'lang': lang, 'tz': tz, 'uid': uid};
}

///
/// 🔍 OdooSearchParams
/// =
class OdooSearchParams<T> {
  /// Nombre del modelo Odoo (por ejemplo: `res.partner`).
  final String model;

  /// Filtro de búsqueda (por ejemplo: `[["is_company", "=", true]]`).
  final List<dynamic> domain;

  /// Especificación de campos para `web_search_read`.
  final Map<String, dynamic> specification;

  /// Función que transforma la respuesta JSON en el tipo de dato T.
  final T Function(Object? json) fromJsonT;

  /// Contexto del usuario (idioma, zona horaria, permisos, etc).
  final UserContext? ctx;

  /// Número de registros a saltar (para paginación).
  final int offset;

  /// Límite de registros a devolver.
  final int limit;

  /// Orden de los resultados (por ejemplo: `name asc`).
  final String order;

  const OdooSearchParams({
    required this.model,
    required this.domain,
    required this.specification,
    required this.fromJsonT,
    this.ctx,
    this.offset = 0,
    this.limit = 0,
    this.order = '',
  });

  /// Convierte los parámetros a un mapa de kwargs estándar para Odoo RPC.
  Map<String, dynamic> toKwargs(UserContext defaultCtx) => {
    'specification': specification,
    'context': ctx?.toJson() ?? defaultCtx.toJson(),
    'domain': domain,
    'offset': offset,
    'limit': limit,
    'order': order,
  };

  OdooSearchParams<T> copyWith({
    String? model,
    List<dynamic>? domain,
    Map<String, dynamic>? specification,
    T Function(Object? json)? fromJsonT,
    UserContext? ctx,
    int? offset,
    int? limit,
    String? order,
  }) => OdooSearchParams(
    model: model ?? this.model,
    domain: domain ?? this.domain,
    specification: specification ?? this.specification,
    fromJsonT: fromJsonT ?? this.fromJsonT,
    ctx: ctx ?? this.ctx,
    offset: offset ?? this.offset,
    limit: limit ?? this.limit,
    order: order ?? this.order,
  );
}

/// ===============================================
/// 🆕 OdooCreateParams
/// ===============================================
class OdooCreateParams<T> {
  /// Nombre del modelo Odoo.
  final String model;

  /// Valores del registro a crear.
  final Map<String, dynamic> values;

  /// Función que transforma la respuesta JSON en el tipo de dato T.
  final T Function(Object? json) fromJsonT;

  const OdooCreateParams({required this.model, required this.values, required this.fromJsonT});
}

///
/// Tipado para Actualizar
///
/// R => Retorno (tipo)
///
/// V => Valor que envia por body
class OdooWriteParams<R, V> {
  /// Nombre del modelo Odoo.
  final String model;

  /// IDs de los registros a actualizar.
  final List<int> ids;

  /// Campos y valores a actualizar.
  final V values;

  /// Función que transforma la respuesta JSON en el tipo de dato T.
  final R Function(dynamic json) fromJsonT;

  final Map<String, dynamic>? Function(V value) toJson;

  ///
  /// Tipado para Actualizar
  ///
  /// R => Retorno (tipo)
  ///
  /// V => Valor que envia por body
  const OdooWriteParams({
    required this.model,
    required this.ids,
    required this.values,
    required this.fromJsonT,
    required this.toJson,
  });
}

// /// ===============================================
// /// 🗑️ OdooUnlinkParams
// /// ===============================================
class OdooUnlinkParams<T> {
  /// Nombre del modelo Odoo.
  final String model;

  /// IDs de los registros a eliminar.
  final List<int> ids;

  /// Función que transforma la respuesta JSON en el tipo de dato T.
  final T Function(Object? json) fromJsonT;

  /// Contexto del usuario (opcional).
  final UserContext? ctx;

  const OdooUnlinkParams({
    required this.model,
    required this.ids,
    required this.fromJsonT,
    this.ctx,
  });
}
