enum OdooFieldType {
  /// Campo de texto (char, text, selection). Odoo retorna `false` cuando no hay valor, el cual se mapea a `null`.
  string,

  /// Campo numérico entero. Mapas de `num` a `int`.
  integer,

  /// Campo numérico decimal (float, monetary).
  double_,

  /// Campo booleano (bool).
  boolean,

  /// Campo de fecha y hora. Formato: `"yyyy-MM-dd HH:mm:ss"`.
  datetime,

  /// Campo de fecha. Formato: `"yyyy-MM-dd"`.
  date,

  /// Relación de muchos a uno.
  /// En Dart se puede usar como [int] (solo ID) o [List<dynamic>] (par [id, name]).
  /// Ejemplo: `category_id` en un Producto. Odoo retorna `[1, "Electronics"]`.
  many2one,

  /// Relación de muchos a muchos.
  /// En Dart se mapea a una lista de IDs [List<int>].
  /// Ejemplo: `tag_ids` en un Producto. Odoo retorna `[1, 2, 3]`.
  many2many,

  /// Relación de uno a muchos.
  /// En Dart se mapea a una lista de IDs [List<int>].
  /// Ejemplo: `line_ids` en una Orden (Order). Odoo retorna `[500, 501]`.
  one2many,
  
  /// Campo de selección (selection). Se mapea a un [String] o un [Enum] en Dart.
  selection,
  
  /// Campo dinámico que puede ser de cualquier tipo.
  dynamic_,
}

class OdooModel {
  const OdooModel({
    required this.modelName,
  });
  final String modelName;
}

class OdooField {
  const OdooField({
    required this.type,
    this.name,
    this.includeInSpec = true,
    this.specFields = const [],
  });

  /// Nombre del campo en Odoo (snake_case). Si es null se usa el nombre del field.
  final String? name;

  /// Tipo de campo en Odoo. Define el comportamiento del parser.
  ///
  /// Ejemplo para una relación Many2one:
  /// ```dart
  /// @OdooField(type: OdooFieldType.many2one, name: 'partner_id')
  /// final int? partnerId;
  /// ```
  ///
  /// Ejemplo para una relación Many2many:
  /// ```dart
  /// @OdooField(type: OdooFieldType.many2many, name: 'tag_ids')
  /// final List<int>? tagIds;
  /// ```
  final OdooFieldType type;
  // final bool required;

  final bool includeInSpec;

  final List<String> specFields;
}
