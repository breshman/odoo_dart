import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:odoo_annotation/odoo_annotation.dart';

import 'package:source_gen/source_gen.dart';

// const _odooModelChecker = TypeChecker.fromRuntime(OdooModel);
final _odooFieldChecker = TypeChecker.typeNamed(OdooField);

Builder odooModelBuilder(BuilderOptions options) =>
    PartBuilder([OdooModelGenerator()], '.odoo.g.dart');

class OdooModelGenerator extends GeneratorForAnnotation<OdooModel> {
  @override
  String generateForAnnotatedElement(
    Element2 element, // <-- Element2, la nueva API
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement2) {
      throw InvalidGenerationSourceError(
        '@OdooModel solo puede aplicarse a clases.',
        element: element,
      );
    }

    final className = element.displayName;
    final modelName = annotation.peek('modelName')?.stringValue;

    if (modelName == null || modelName.isEmpty) {
      throw InvalidGenerationSourceError(
        '@OdooModel requiere modelName. Ejemplo: @OdooModel(modelName: "hr.employee")',
        element: element,
      );
    }

    // En Element2 los campos están en element.fields2
    final fields = element.fields2.where((f) => !f.isStatic).toList();

    if (fields.isEmpty) {
      throw InvalidGenerationSourceError(
        '$className no tiene campos con @OdooField.',
        element: element,
      );
    }

    final buffer = StringBuffer()
      ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND\n')
      ..writeln('// ignore_for_file: type=lint\n');

    _generateFromJson(buffer, className, fields);
    _generateToJson(buffer, className, fields);
    _generateCopyWith(buffer, className, fields);
    _generateToString(buffer, className, fields);
    _generateMeta(buffer, className, modelName, fields);

    return buffer.toString();
  }

  void _generateFromJson(
    StringBuffer buf,
    String className,
    List<FieldElement2> fields, // <-- FieldElement
  ) {
    buf.writeln('$className _\$${className}FromJson(Map<String, dynamic> json) {');
    buf.writeln('  return $className(');

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

  void _generateToJson(
    StringBuffer buf,
    String className,
    List<FieldElement2> fields,
  ) {
    buf.writeln(
      'Map<String, dynamic> _\$${className}ToJson($className instance, {bool toOdoo = false}) {',
    );
    buf.writeln('  return {');

    for (final field in fields) {
      final annotation = _readOdooField(field);
      final jsonKey = annotation?.peek('name')?.stringValue ?? field.displayName;
      final fieldType = _resolveType(field, annotation);
      final fieldName = field.displayName;
      final isNullable = field.type.nullabilitySuffix == NullabilitySuffix.question;

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
    String className,
    List<FieldElement2> fields,
  ) {
    buf.writeln('extension \$${className}Extension on $className {');
    buf.writeln('  Map<String, dynamic> toJson() => _\$${className}ToJson(this);');
    buf.writeln('  Map<String, dynamic> toOdoo() => _\$${className}ToJson(this, toOdoo: true);');
    buf.writeln();
    buf.writeln('  $className copyWith({');

    for (final field in fields) {
      final type = field.type.getDisplayString();
      // Aseguramos que el parámetro sea nullable para copyWith
      final paramType = type.endsWith('?') ? type : '$type?';
      buf.writeln('    $paramType ${field.displayName},');
    }

    buf.writeln('  }) {');
    buf.writeln('    return $className(');

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
    List<FieldElement2> fields,
  ) {
    buf.writeln('mixin _\$$className {');
    buf.writeln('  Map<String, dynamic> toJson() => _\$${className}ToJson(this as $className);');
    buf.writeln('  Map<String, dynamic> toOdoo() => _\$${className}ToJson(this as $className, toOdoo: true);');
    buf.writeln();
    buf.writeln('  @override');
    buf.writeln('  String toString() {');
    buf.writeln("    final instance = this as $className;");
    buf.writeln("    return '$className('");

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

  ConstantReader? _readOdooField(FieldElement2 field) {
    // Se accede via el getter correcto de Element2
    final annotations = field.metadata2.annotations; // List<ElementAnnotation2>

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

  OdooFieldType _resolveType(FieldElement2 field, ConstantReader? annotation) {
    if (annotation != null) {
      final typeValue = annotation.peek('type')?.objectValue;
      if (typeValue != null) {
        final index = typeValue.getField('index')?.toIntValue() ?? 0;
        return OdooFieldType.values[index];
      }
    }
    // Inferencia automática desde el tipo Dart
    if (field.type.element3 is EnumElement2) {
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
    final isListType = typeName.startsWith('List');

    return switch (fieldType) {
      OdooFieldType.string => isNullable
          ? "$raw == false || $raw == null ? null : ($raw as String)"
          : "$raw == false || $raw == null ? '' : ($raw as String)",
      OdooFieldType.integer => isNullable
          ? "$raw == false || $raw == null ? null : ($raw as num).toInt()"
          : "$raw == false || $raw == null ? 0 : ($raw as num).toInt()",
      OdooFieldType.double_ => isNullable
          ? "$raw == false || $raw == null ? null : ($raw as num).toDouble()"
          : "$raw == false || $raw == null ? 0.0 : ($raw as num).toDouble()",
      OdooFieldType.boolean =>
        isNullable ? "$raw is bool ? $raw : null" : "$raw is bool ? $raw : false",
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
                  ? "$raw == false || $raw == null ? null : ($raw as List)"
                  : "$raw == false || $raw == null ? [] : ($raw as List)";
            }
            // List<Category>? → mapea usando fromJson
            return isNullable
                ? "$raw == false || $raw == null ? null : ($raw as List).map((e) => $innerType.fromJson(e as Map<String, dynamic>)).toList()"
                : "$raw == false || $raw == null ? [] : ($raw as List).map((e) => $innerType.fromJson(e as Map<String, dynamic>)).toList()";
          }

          if (typeName == 'int') {
            // int? partnerId → solo el ID
            return isNullable
                ? "$raw == false || $raw == null ? null : ($raw is List && ($raw as List).isNotEmpty ? ($raw as List)[0] as int : ($raw is int ? $raw as int : null))"
                : "$raw == false || $raw == null ? 0 : ($raw is List && ($raw as List).isNotEmpty ? ($raw as List)[0] as int : ($raw is int ? $raw as int : 0))";
          }

          if (primitives.contains(typeName)) {
            return isNullable ? "$raw == false || $raw == null ? null : $raw" : "$raw ?? ''";
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
          final element = dartType.element3;
          if (element is EnumElement2) {
            return isNullable
                ? "$raw == false || $raw == null ? null : $typeName.values.byName($raw as String)"
                : "$typeName.values.byName($raw as String)";
          }
          return isNullable
              ? "$raw == false || $raw == null ? null : ($raw as String)"
              : "$raw == false || $raw == null ? '' : ($raw as String)";
        }(),
      OdooFieldType.dynamic_ => "$raw == false ? null : $raw",
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
          final element = dartType.element3;
          if (element is EnumElement2) {
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
    List<FieldElement2> fields,
  ) {
    buf.writeln('mixin _\$${className}Meta {');
    buf.writeln("  static const String modelName = '$modelName';");
    buf.writeln();
    buf.writeln('  static const Map<String, dynamic> specification = {');

    for (final field in fields) {
      final annotation = _readOdooField(field);

      final includeInSpec = annotation?.peek('includeInSpec')?.boolValue ?? true;
      if (!includeInSpec) continue;

      final jsonKey = annotation?.peek('name')?.stringValue ?? field.displayName;
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
    buf.writeln('}\n');
  }
}
