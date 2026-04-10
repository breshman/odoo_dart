// ============================================================
//  PARCHE para odoo_model_generator.dart
//
//  Cambios necesarios en OdooModelGenerator para soportar
//  OdooBaseModel: omitir campos base (id, name, display_name,
//  active) del código generado cuando la clase extiende
//  OdooBaseModel.
// ============================================================
//
//  1. Agrega el checker de OdooBaseModel en las importaciones:
//
//     final _odooBaseModelChecker = TypeChecker.typeNamed('OdooBaseModel');
//
//  2. Dentro de generateForAnnotatedElement, después de obtener
//     los campos, filtra los base si la clase extiende OdooBaseModel.
//
//  3. Ajusta _generateMeta para fusionar baseSpecification.
//
// ─────────────────────────────────────────────────────────────
//  Copia este fragmento DENTRO de odoo_model_generator.dart
//  sustituyendo los puntos indicados con "← REEMPLAZA".
// ============================================================

// ── 1. NUEVO checker (pon esto junto a _odooFieldChecker) ─────

// final _odooFieldChecker = TypeChecker.typeNamed(OdooField);   // ya existe
// ↓ AGREGA esto debajo:
// final _odooBaseModelChecker = TypeChecker.typeNamed('OdooBaseModel');

// ── 2. REEMPLAZA el bloque de obtención de campos en
//       generateForAnnotatedElement  ────────────────────────────
//
//  ANTES:
//    final fields = element.fields2.where((f) => !f.isStatic).toList();
//    if (fields.isEmpty) {
//      throw InvalidGenerationSourceError(...);
//    }
//
//  DESPUÉS (pega esto en su lugar):

/*
  // Detecta si la clase extiende OdooBaseModel
  final extendsBase = _extendsOdooBaseModel(element);

  // Nombres de campos que OdooBaseModel ya maneja
  const _baseFieldNames = {'id', 'name', 'displayName', 'active'};

  var fields = element.fields2.where((f) => !f.isStatic).toList();

  // Si extiende OdooBaseModel, excluimos los campos base del código generado
  if (extendsBase) {
    fields = fields
        .where((f) => !_baseFieldNames.contains(f.displayName))
        .toList();
  }

  // Permite modelos que sólo tienen campos base (sólo extends, sin extras)
  if (fields.isEmpty && !extendsBase) {
    throw InvalidGenerationSourceError(
      '$className no tiene campos con @OdooField.',
      element: element,
    );
  }
*/

// ── 3. NUEVO método helper (agrégalo al final de la clase) ─────

/*
  /// Devuelve true si la clase extiende directa o indirectamente
  /// OdooBaseModel.
  bool _extendsOdooBaseModel(ClassElement2 element) {
    InterfaceType? supertype = element.supertype;
    while (supertype != null) {
      if (supertype.element3.displayName == 'OdooBaseModel') return true;
      supertype = supertype.element3.supertype;
    }
    return false;
  }
*/

// ── 4. AJUSTE en _generateMeta ────────────────────────────────
//
//  En _generateMeta, cuando extendsBase == true, emite una nota
//  de que baseSpecification ya cubre id/name/display_name/active.
//
//  ANTES (al inicio de _generateMeta):
//    buf.writeln('mixin _\$${className}Meta {');
//    buf.writeln("  static const String modelName = '$modelName';");
//    buf.writeln();
//    buf.writeln('  static const Map<String, dynamic> specification = {');
//
//  DESPUÉS:

/*
  void _generateMeta(
    StringBuffer buf,
    String className,
    String modelName,
    List<FieldElement2> fields,
    bool extendsBase,   // ← nuevo parámetro
  ) {
    buf.writeln('mixin _\$${className}Meta {');
    buf.writeln("  static const String modelName = '$modelName';");
    buf.writeln();
    buf.writeln('  static const Map<String, dynamic> specification = {');

    // Si extiende OdooBaseModel, los campos base vienen de ahí
    if (extendsBase) {
      buf.writeln('    // Campos base (id, name, display_name, active)');
      buf.writeln('    ...OdooBaseModel.baseSpecification,');
    }

    for (final field in fields) {
      // ... (resto igual que antes) ...
    }

    buf.writeln('  };');
    buf.writeln('}\n');
  }
*/

// ── 5. AJUSTE en _generateFromJson ───────────────────────────
//
//  Cuando extendsBase == true, el fromJson generado NO debe incluir
//  id/name/display_name/active (ya los parsea OdooBaseModel.baseFromJson).
//  Sólo emite los campos filtrados.
//  Los campos base en el constructor del modelo concreto se pasan
//  vía: id: base.id, name: base.name, etc.
//
//  Si quieres que el generador emita el fromJson completo
//  automáticamente (incluido el bloque baseFromJson), modifica
//  _generateFromJson así:

/*
  void _generateFromJson(
    StringBuffer buf,
    String className,
    List<FieldElement2> fields,
    bool extendsBase,
  ) {
    buf.writeln(
      '$className _\$${className}FromJson(Map<String, dynamic> json) {');

    if (extendsBase) {
      buf.writeln('  final base = OdooBaseModel.baseFromJson(json);');
    }

    buf.writeln('  return $className(');

    // Campos base: los toma de `base`
    if (extendsBase) {
      buf.writeln('    id:          base.id,');
      buf.writeln('    name:        base.name,');
      buf.writeln('    displayName: base.displayName,');
      buf.writeln('    active:      base.active,');
    }

    // Campos propios del modelo
    for (final field in fields) {
      final annotation = _readOdooField(field);
      final jsonKey = annotation?.peek('name')?.stringValue ?? field.displayName;
      final fieldType = _resolveType(field, annotation);
      final expression = _buildFromJsonExpression(
        jsonKey: jsonKey,
        fieldType: fieldType,
        dartType: field.type,
      );
      buf.writeln('    ${field.displayName}: $expression,');
    }

    buf
      ..writeln('  );')
      ..writeln('}\n');
  }
*/

// ─────────────────────────────────────────────────────────────
//  RESUMEN de cambios en generateForAnnotatedElement:
//
//  final extendsBase = _extendsOdooBaseModel(element);
//
//  // filtrar campos base
//  var fields = element.fields2.where(...).toList();
//  if (extendsBase) fields = fields.where(f => !_baseFieldNames.contains(f.displayName)).toList();
//
//  _generateFromJson(buffer, className, fields, extendsBase);
//  _generateToJson(buffer, className, fields);          // sin cambios
//  _generateCopyWith(buffer, className, fields);        // sin cambios
//  _generateToString(buffer, className, fields);        // sin cambios
//  _generateMeta(buffer, className, modelName, fields, extendsBase);
// ─────────────────────────────────────────────────────────────

void main() {
  // Este archivo es sólo documentación del parche.
  // No es ejecutable directamente.
}
