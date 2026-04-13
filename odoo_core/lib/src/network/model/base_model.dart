// ─── Clase base abstracta ────────────────────────────────────

/// Clase base de la que deben extender todos los modelos Odoo.
/// Ahora incluye soporte nativo y automático para Timestamps Odoo.
abstract class OdooBaseModel {
  final int id;
  final String name;
  final String? displayName;

  // Timestamps de auditoría
  final DateTime? createDate;
  final DateTime? writeDate;
  final int? createUid;
  final int? writeUid;

  const OdooBaseModel({
    required this.id,
    required this.name,
    this.displayName,
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
    DateTime? createDate,
    DateTime? writeDate,
    int? createUid,
    int? writeUid,
  }) baseFromJson(Map<String, dynamic> json) {
    DateTime? parseOdooDate(dynamic raw) {
      if (raw == false || raw == null) return null;
      return DateTime.parse('${(raw as String).replaceFirst(' ', 'T')}Z')
          .toLocal();
    }

    int? parseUid(dynamic raw) {
      if (raw == false || raw == null) return null;
      if (raw is List && raw.isNotEmpty) return (raw[0] as num).toInt();
      if (raw is num) return raw.toInt();
      return null;
    }

    return (
      id: json['id'] == false || json['id'] == null
          ? 0
          : (json['id'] as num).toInt(),
      name: json['name'] == false || json['name'] == null
          ? ''
          : (json['name'] as String),
      displayName: json['display_name'] == false || json['display_name'] == null
          ? null
          : (json['display_name'] as String),
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
      if (createDate != null)
        'create_date': toOdoo
            ? createDate!
                .toUtc()
                .toIso8601String()
                .substring(0, 19)
                .replaceFirst('T', ' ')
            : createDate!.toIso8601String(),
      if (writeDate != null)
        'write_date': toOdoo
            ? writeDate!
                .toUtc()
                .toIso8601String()
                .substring(0, 19)
                .replaceFirst('T', ' ')
            : writeDate!.toIso8601String(),
      if (createUid != null) 'create_uid': createUid, // Enviar int
      if (writeUid != null) 'write_uid': writeUid,
    };
  }

  static const Map<String, dynamic> baseSpecification = {
    'id': {},
    'name': {},
    'display_name': {},
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
  String toString() => '$runtimeType(id: $id, name: $name)';
}
