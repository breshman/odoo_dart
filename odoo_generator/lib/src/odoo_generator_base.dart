import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:odoo_core/odoo_core.dart';

import 'package:source_gen/source_gen.dart';

// const _odooModelChecker = TypeChecker.fromRuntime(OdooModel);
final _odooFieldChecker = TypeChecker.typeNamed(OdooField);

Builder odooModelBuilder(BuilderOptions options) =>
    PartBuilder([OdooModelGenerator()], '.odoo.g.dart');

class OdooModelGenerator extends GeneratorForAnnotation<OdooModel> {
  @override
  String generateForAnnotatedElement(
    Element element, // <-- Element2, la nueva API
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@OdooModel solo puede aplicarse a clases.',
        element: element,
      );
    }

    final className = element.displayName;
    final modelName = annotation.peek('modelName')?.stringValue;
    final generateRepository =
        annotation.peek('generateRepository')?.boolValue ?? true;
    final includeBaseFieldsInSpec =
        annotation.peek('includeBaseFieldsInSpec')?.boolValue ?? true;

    if (modelName == null || modelName.isEmpty) {
      throw InvalidGenerationSourceError(
        '@OdooModel requiere modelName. Ejemplo: @OdooModel(modelName: "hr.employee")',
        element: element,
      );
    }

    final extendsBase = _extendsOdooBaseModel(element);
    const baseFieldNames = {
      'id',
      'name',
      'displayName',
      'createDate',
      'writeDate',
      'createUid',
      'writeUid'
    };

    var fields = element.fields
        .where((f) => !f.isStatic && _readOdooField(f) != null)
        .toList();

    if (extendsBase) {
      fields =
          fields.where((f) => !baseFieldNames.contains(f.displayName)).toList();
    }

    if (fields.isEmpty && !extendsBase) {
      throw InvalidGenerationSourceError(
        '$className no tiene campos con @OdooField.',
        element: element,
      );
    }

    final buffer = StringBuffer()
      ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND\n')
      ..writeln('// ignore_for_file: type=lint\n');

    _generateFromJson(buffer, element, fields, extendsBase);
    _generateToJson(buffer, className, fields, extendsBase);
    _generateCopyWith(buffer, element, fields, extendsBase);
    _generateToString(buffer, className, fields, extendsBase);
    _generateFieldsEnum(buffer, className, fields, extendsBase);
    _generateMeta(buffer, className, modelName, fields, extendsBase,
        includeBaseFieldsInSpec);
    if (generateRepository) {
      _generateRepository(buffer, className);
    }

    return buffer.toString();
  }

  void _generateFieldsEnum(StringBuffer buf, String className,
      List<FieldElement> fields, bool extendsBase) {
    buf.writeln('enum ${className}Fields {');
    if (extendsBase) {
      buf.writeln(
          '  id, name, displayName, createDate, writeDate, createUid, writeUid,');
    }
    for (final field in fields) {
      buf.writeln('  ${field.displayName},');
    }
    buf.writeln('}\n');
  }

  void _generateRepository(StringBuffer buf, String className) {
    buf.writeln(
        'class ${className}Repository extends OdooRepository<$className> {');
    buf.writeln('  ${className}Repository({required super.client})');
    buf.writeln('      : super(');
    buf.writeln('          modelName: _\$${className}Meta.modelName,');
    buf.writeln('          specification: _\$${className}Meta.specification,');
    buf.writeln('          fromJson: _\$${className}FromJson,');
    buf.writeln('        );');
    buf.writeln('}\n');
  }

  void _generateFromJson(
    StringBuffer buf,
    ClassElement element,
    List<FieldElement> fields,
    bool extendsBase,
  ) {
    final className = element.displayName;
    buf.writeln(
        '$className _\$${className}FromJson(Map<String, dynamic> json) {');

    if (extendsBase) {
      buf.writeln('  final base = OdooBaseModel.baseFromJson(json);');
    }

    buf.writeln('  return $className(');

    if (extendsBase) {
      final constructors =
          element.constructors.where((c) => c.name == null || c.name == '');
      final constructor = constructors.isNotEmpty
          ? constructors.first
          : element.constructors.first;
      final paramNames =
          constructor.formalParameters.map((p) => p.name).toSet();

      if (paramNames.contains('id')) buf.writeln('    id: base.id,');
      if (paramNames.contains('name')) buf.writeln('    name: base.name,');
      if (paramNames.contains('displayName'))
        buf.writeln('    displayName: base.displayName,');
      if (paramNames.contains('createDate'))
        buf.writeln('    createDate: base.createDate,');
      if (paramNames.contains('writeDate'))
        buf.writeln('    writeDate: base.writeDate,');
      if (paramNames.contains('createUid'))
        buf.writeln('    createUid: base.createUid,');
      if (paramNames.contains('writeUid'))
        buf.writeln('    writeUid: base.writeUid,');
    }

    for (final field in fields) {
      final annotation = _readOdooField(field);
      final jsonKey =
          annotation?.peek('name')?.stringValue ?? field.displayName;
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

  void _generateToJson(
    StringBuffer buf,
    String className,
    List<FieldElement> fields,
    bool extendsBase,
  ) {
    buf.writeln(
      'Map<String, dynamic> _\$${className}ToJson($className instance, {bool toOdoo = false}) {',
    );
    buf.writeln('  return {');

    if (extendsBase) {
      buf.writeln('    ...instance.baseToJson(toOdoo: toOdoo),');
    }

    for (final field in fields) {
      final annotation = _readOdooField(field);
      final jsonKey =
          annotation?.peek('name')?.stringValue ?? field.displayName;
      final fieldType = _resolveType(field, annotation);
      final fieldName = field.displayName;
      final isNullable =
          field.type.nullabilitySuffix == NullabilitySuffix.question;

      final expression = _buildToJsonExpression(
        fieldType: fieldType,
        accessor: isNullable ? 'instance.$fieldName!' : 'instance.$fieldName',
        dartType: field.type,
      );

      if (isNullable) {
        buf.writeln(
          "    if(instance.$fieldName !=null) '$jsonKey': $expression,",
        );
        // buf.writeln(
        //   "    '$jsonKey': instance.$fieldName == null ? false : $expression,",
        // );
      } else {
        buf.writeln("    '$jsonKey': $expression,");
      }
    }

    buf
      ..writeln('  };')
      ..writeln('}\n');
  }

  void _generateCopyWith(
    StringBuffer buf,
    ClassElement element,
    List<FieldElement> fields,
    bool extendsBase,
  ) {
    final className = element.displayName;
    buf.writeln('extension \$${className}Extension on $className {');
    buf.writeln(
        '  Map<String, dynamic> toJson() => _\$${className}ToJson(this);');
    buf.writeln(
        '  Map<String, dynamic> toOdoo() => _\$${className}ToJson(this, toOdoo: true);');
    buf.writeln();
    buf.writeln('  $className copyWith({');

    Set<String?> paramNames = {};
    if (extendsBase) {
      final constructors =
          element.constructors.where((c) => c.name == null || c.name == '');
      final constructor = constructors.isNotEmpty
          ? constructors.first
          : element.constructors.first;
      paramNames = constructor.formalParameters.map((p) => p.name).toSet();

      if (paramNames.contains('id')) buf.writeln('    int? id,');
      if (paramNames.contains('name')) buf.writeln('    String? name,');
      if (paramNames.contains('displayName')) {
        buf.writeln('    String? displayName,');
      }
      if (paramNames.contains('createDate')) {
        buf.writeln('    DateTime? createDate,');
      }
      if (paramNames.contains('writeDate')) {
        buf.writeln('    DateTime? writeDate,');
      }
      if (paramNames.contains('createUid')) buf.writeln('    int? createUid,');
      if (paramNames.contains('writeUid')) buf.writeln('    int? writeUid,');
    }

    for (final field in fields) {
      final type = field.type.getDisplayString();
      // Aseguramos que el parámetro sea nullable para copyWith
      final paramType = type.endsWith('?') ? type : '$type?';
      buf.writeln('    $paramType ${field.displayName},');
    }

    buf.writeln('  }) {');
    buf.writeln('    return $className(');

    if (extendsBase) {
      if (paramNames.contains('id')) buf.writeln('      id: id ?? this.id,');
      if (paramNames.contains('name')) {
        buf.writeln('      name: name ?? this.name,');
      }
      if (paramNames.contains('displayName')) {
        buf.writeln('      displayName: displayName ?? this.displayName,');
      }
      if (paramNames.contains('createDate')) {
        buf.writeln('      createDate: createDate ?? this.createDate,');
      }
      if (paramNames.contains('writeDate')) {
        buf.writeln('      writeDate: writeDate ?? this.writeDate,');
      }
      if (paramNames.contains('createUid')) {
        buf.writeln('      createUid: createUid ?? this.createUid,');
      }
      if (paramNames.contains('writeUid')) {
        buf.writeln('      writeUid: writeUid ?? this.writeUid,');
      }
    }

    for (final field in fields) {
      final name = field.displayName;
      buf.writeln('      $name: $name ?? this.$name,');
    }

    buf.writeln('    );');
    buf.writeln('  }');

    buf.writeln('}\n');
  }

  void _generateToString(
    StringBuffer buf,
    String className,
    List<FieldElement> fields,
    bool extendsBase,
  ) {
    buf.writeln('mixin _\$$className {');
    buf.writeln(
        '  Map<String, dynamic> toJson() => _\$${className}ToJson(this as $className);');
    buf.writeln(
        '  Map<String, dynamic> toOdoo() => _\$${className}ToJson(this as $className, toOdoo: true);');
    buf.writeln();
    buf.writeln('  @override');
    buf.writeln('  String toString() {');
    buf.writeln("    final instance = this as $className;");
    buf.writeln("    return '$className('");

    if (extendsBase) {
      buf.writeln("        'id: \${instance.id}, '");
      buf.writeln("        'name: \${instance.name}, '");
    }

    for (int i = 0; i < fields.length; i++) {
      final field = fields[i];
      final isLast = i == fields.length - 1;
      buf.writeln(
        "        '${field.displayName}: \${instance.${field.displayName}}${isLast ? "" : ", "}'",
      );
    }

    buf.writeln("        ')';");
    buf.writeln('  }');
    buf.writeln('}\n');
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  bool _extendsOdooBaseModel(ClassElement element) {
    InterfaceType? supertype = element.supertype;
    while (supertype != null) {
      if (supertype.element.displayName == 'OdooBaseModel') return true;
      supertype = supertype.element.supertype;
    }
    return false;
  }

  ConstantReader? _readOdooField(FieldElement field) {
    // Se accede via el getter correcto de Element2
    final annotations = field.metadata.annotations; // List<ElementAnnotation2>

    for (final meta in annotations) {
      final value = meta.computeConstantValue();
      if (value == null) continue;

      final reader = ConstantReader(value);
      if (reader.instanceOf(_odooFieldChecker)) {
        return reader;
      }
    }
    return null;
  }

  OdooFieldType _resolveType(FieldElement field, ConstantReader? annotation) {
    if (annotation != null) {
      final typeValue = annotation.peek('type')?.objectValue;
      if (typeValue != null) {
        final index = typeValue.getField('index')?.toIntValue() ?? 0;
        return OdooFieldType.values[index];
      }
    }
    // Inferencia automática desde el tipo Dart
    if (field.type.element is EnumElement) {
      return OdooFieldType.selection;
    }

    final typeName = field.type.getDisplayString(withNullability: false);
    return switch (typeName) {
      'String' => OdooFieldType.string,
      'int' => OdooFieldType.integer,
      'double' => OdooFieldType.double_,
      'bool' => OdooFieldType.boolean,
      'DateTime' => OdooFieldType.datetime,
      'dynamic' => OdooFieldType.dynamic_,
      _ => OdooFieldType.string,
    };
  }

  String _buildFromJsonExpression({
    required String jsonKey,
    required OdooFieldType fieldType,
    required DartType dartType,
  }) {
    final raw = "json['$jsonKey']";
    final isNullable = dartType.nullabilitySuffix == NullabilitySuffix.question;
    final typeName = dartType.getDisplayString(withNullability: false);

    return switch (fieldType) {
      OdooFieldType.string => isNullable
          ? "$raw == false || $raw == null ? null : ($raw.toString())"
          : "$raw == false || $raw == null ? '' : ($raw.toString())",
      OdooFieldType.integer => isNullable
          ? "$raw == false || $raw == null ? null : ($raw as num).toInt()"
          : "$raw == false || $raw == null ? 0 : ($raw as num).toInt()",
      OdooFieldType.double_ => isNullable
          ? "$raw == false || $raw == null ? null : ($raw as num).toDouble()"
          : "$raw == false || $raw == null ? 0.0 : ($raw as num).toDouble()",
      OdooFieldType.boolean => isNullable
          ? "$raw is bool ? $raw as bool : null"
          : "$raw is bool ? $raw as bool : false",
      OdooFieldType.datetime => isNullable
          ? "$raw == false || $raw == null ? null : DateTime.parse(($raw as String).replaceFirst(' ', 'T') + 'Z').toLocal()"
          : "DateTime.parse(($raw as String).replaceFirst(' ', 'T') + 'Z').toLocal()",
      OdooFieldType.date => isNullable
          ? "$raw == false || $raw == null ? null : DateTime.parse($raw as String)"
          : "DateTime.parse($raw as String)",
      OdooFieldType.many2one => () {
          final typeName = dartType.getDisplayString(withNullability: false);
          final isListType = typeName.startsWith('List');

          // Tipos primitivos conocidos
          const primitives = {'int', 'double', 'String', 'bool', 'dynamic'};

          if (isListType) {
            final innerType = _getListInnerType(dartType);
            if (innerType == 'dynamic') {
              // List<dynamic>? → retorna la lista cruda [id, name]
              return isNullable
                  ? "$raw == false || $raw == null ? null : ($raw as List<dynamic>)"
                  : "$raw == false || $raw == null ? [] : ($raw as List<dynamic>)";
            }
            // List<Category>? → mapea usando fromJson
            return isNullable
                ? "$raw == false || $raw == null ? null : ($raw as List<dynamic>).map((e) => $innerType.fromJson(e as Map<String, dynamic>)).toList()"
                : "$raw == false || $raw == null ? [] : ($raw as List<dynamic>).map((e) => $innerType.fromJson(e as Map<String, dynamic>)).toList()";
          }

          if (typeName == 'int') {
            // int? partnerId → solo el ID
            return isNullable
                ? "$raw == false || $raw == null ? null : ($raw is List && ($raw as List).isNotEmpty ? ($raw as List)[0] as int : ($raw is int ? $raw as int : null))"
                : "$raw == false || $raw == null ? 0 : ($raw is List && ($raw as List).isNotEmpty ? ($raw as List)[0] as int : ($raw is int ? $raw as int : 0))";
          }

          if (primitives.contains(typeName)) {
            return isNullable
                ? "$raw == false || $raw == null ? null : $raw as $typeName"
                : "$raw ?? ''";
          }

          // Objeto personalizado (PickingPacking, Employee, etc.)
          // Odoo retorna [id, name], construimos un Map mínimo para fromJson
          // El objeto debe tener fromJson
          return isNullable
              ? """$raw == false || $raw == null ? null : $typeName.fromJson(
          $raw is List
            ? {'id': ($raw as List).isNotEmpty ? ($raw as List)[0] : null, 'name': ($raw as List).length > 1 ? ($raw as List)[1] : null}
            : $raw as Map<String, dynamic>
        )"""
              : """$typeName.fromJson(
          $raw is List
            ? {'id': ($raw as List).isNotEmpty ? ($raw as List)[0] : null, 'name': ($raw as List).length > 1 ? ($raw as List)[1] : null}
            : $raw as Map<String, dynamic>
        )""";
        }(),
      OdooFieldType.many2many ||
      OdooFieldType.one2many =>
        "$raw == false || $raw == null ? [] : ($raw as List).map((e) => e as int).toList()",
      OdooFieldType.selection => () {
          final element = dartType.element;
          if (element is EnumElement) {
            return isNullable
                ? "$raw == false || $raw == null ? null : $typeName.values.byName($raw as String)"
                : "$typeName.values.byName($raw as String)";
          }
          return isNullable
              ? "$raw == false || $raw == null ? null : ($raw as String)"
              : "$raw == false || $raw == null ? '' : ($raw as String)";
        }(),
      OdooFieldType.dynamic_ => "$raw == false ? null : $raw as $typeName",
    };
  }

  String _getListInnerType(DartType dartType) {
    final typeName = dartType.getDisplayString(withNullability: false);
    // typeName es algo como "List<Category>" o "List<dynamic>"
    final match = RegExp(r'List<(.+)>').firstMatch(typeName);
    return match?.group(1) ?? 'dynamic';
  }

  String _buildToJsonExpression({
    required OdooFieldType fieldType,
    required String accessor,
    required DartType dartType,
  }) {
    final typeName = dartType.getDisplayString(withNullability: false);
    final isListType = typeName.startsWith('List');

    return switch (fieldType) {
      OdooFieldType.datetime =>
        "toOdoo ? $accessor.toUtc().toIso8601String().substring(0, 19).replaceFirst('T', ' ') : $accessor.toIso8601String()",
      OdooFieldType.date => "$accessor.toIso8601String().substring(0, 10)",
      OdooFieldType.many2many || OdooFieldType.one2many => accessor,
      OdooFieldType.many2one => () {
          if (!isListType) {
            const primitives = {'int', 'double', 'String', 'bool', 'dynamic'};
            if (primitives.contains(typeName)) {
              return accessor;
            }
            return 'toOdoo ? $accessor.id : $accessor.toJson()';
          }

          final innerType = _getListInnerType(dartType);

          if (innerType == 'dynamic') {
            // List<dynamic> → [id, name], enviar solo el id
            return "($accessor.isNotEmpty ? $accessor[0] : null)";
          }

          const primitives = {'int', 'double', 'String', 'bool', 'dynamic'};
          if (primitives.contains(innerType)) {
            return "($accessor.isNotEmpty ? $accessor[0] : null)";
          }

          // List<Category> → enviar el .id del primer objeto
          return "($accessor.isNotEmpty ? $accessor[0].id : null)";
        }(),
      OdooFieldType.selection => () {
          final element = dartType.element;
          if (element is EnumElement) {
            return "$accessor.name";
          }
          return accessor;
        }(),
      OdooFieldType.dynamic_ => accessor,
      _ => accessor,
    };
  }

  void _generateMeta(
    StringBuffer buf,
    String className,
    String modelName,
    List<FieldElement> fields,
    bool extendsBase,
    bool includeBaseFieldsInSpec,
  ) {
    buf.writeln('mixin _\$${className}Meta {');
    buf.writeln("  static const String modelName = '$modelName';");
    buf.writeln();
    buf.writeln('  static const Map<String, dynamic> specification = {');

    if (extendsBase && includeBaseFieldsInSpec) {
      buf.writeln('    ...OdooBaseModel.baseSpecification,');
    }

    for (final field in fields) {
      final annotation = _readOdooField(field);

      final includeInSpec =
          annotation?.peek('includeInSpec')?.boolValue ?? true;
      if (!includeInSpec) continue;

      final jsonKey =
          annotation?.peek('name')?.stringValue ?? field.displayName;
      final specFieldsList = annotation
              ?.peek('specFields')
              ?.listValue
              .map((e) => e.toStringValue() ?? '')
              .where((e) => e.isNotEmpty)
              .toList() ??
          [];

      if (specFieldsList.isEmpty) {
        buf.writeln("    '$jsonKey': {},");
      } else {
        buf.writeln("    '$jsonKey': {");
        buf.writeln("      'fields': {");
        for (final subField in specFieldsList) {
          buf.writeln("        '$subField': {},");
        }
        buf.writeln("      },");
        buf.writeln("    },");
      }
    }

    buf.writeln('  };');
    buf.writeln();
    buf.writeln('  static const Map<String, String> fieldMapping = {');
    if (extendsBase) {
      buf.writeln("    'id': 'id',");
      buf.writeln("    'name': 'name',");
      buf.writeln("    'displayName': 'display_name',");
      buf.writeln("    'createDate': 'create_date',");
      buf.writeln("    'writeDate': 'write_date',");
      buf.writeln("    'createUid': 'create_uid',");
      buf.writeln("    'writeUid': 'write_uid',");
    }
    for (final field in fields) {
      final annotation = _readOdooField(field);
      final jsonKey =
          annotation?.peek('name')?.stringValue ?? field.displayName;
      buf.writeln("    '${field.displayName}': '$jsonKey',");
    }
    buf.writeln('  };');
    buf.writeln();
    buf.writeln(
        '  static Map<String, dynamic> buildSpecification({List<${className}Fields>? only, Map<${className}Fields, Map<String, dynamic>>? nested}) {');
    buf.writeln('    final spec = <String, dynamic>{};');
    buf.writeln('    if (only != null) {');
    buf.writeln('      for (final f in only) {');
    buf.writeln('        final odooKey = fieldMapping[f.name] ?? f.name;');
    buf.writeln('        spec[odooKey] = specification[odooKey] ?? {};');
    buf.writeln('      }');
    buf.writeln('    }');
    buf.writeln('    if (nested != null) {');
    buf.writeln('      nested.forEach((f, subSpec) {');
    buf.writeln('        final odooKey = fieldMapping[f.name] ?? f.name;');
    buf.writeln("        spec[odooKey] = {'fields': subSpec};");
    buf.writeln('      });');
    buf.writeln('    }');
    buf.writeln(
        '    if (only == null && nested == null) return specification;');
    buf.writeln('    return spec;');
    buf.writeln('  }');
    buf.writeln('}\n');
  }
}
