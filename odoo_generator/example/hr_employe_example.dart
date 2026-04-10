// ============================================================
//  hr_employee.dart  — EJEMPLO de modelo usando OdooBaseModel
// ============================================================
//
//  Antes (repetías id, name, etc. en cada modelo):
//
//    @OdooField(name: 'id',   type: OdooFieldType.integer)
//    final int id;
//    @OdooField(name: 'name', type: OdooFieldType.string)
//    final String name;
//    // ... y así en cada clase
//
//  Ahora (extends OdooBaseModel, eso es todo):
//
//    class HrEmployee extends OdooBaseModel { ... }
//
// ============================================================

import 'package:odoo_annotation/odoo_annotation.dart';
import 'package:odoo_generator/src/d.dart';
import 'odoo_base_model.dart';

part 'hr_employee.odoo.g.dart'; // generado por build_runner

@OdooModel(modelName: 'hr.employee')
class HrEmployee extends OdooBaseModel with _$HrEmployee, _$HrEmployeeMeta {
  // ── Campos propios del modelo (el generador los procesa) ───

  @OdooField(name: 'job_id', type: OdooFieldType.many2one, specFields: ['id', 'name'])
  final JobPosition? jobId;

  @OdooField(name: 'department_id', type: OdooFieldType.many2one, specFields: ['id', 'name'])
  final Department? departmentId;

  @OdooField(name: 'work_email', type: OdooFieldType.string)
  final String workEmail;

  @OdooField(name: 'mobile_phone', type: OdooFieldType.string)
  final String? mobilePhone;

  @OdooField(name: 'gender', type: OdooFieldType.selection)
  final EmployeeGender? gender;

  @OdooField(name: 'birthday', type: OdooFieldType.date)
  final DateTime? birthday;

  @OdooField(name: 'contract_ids', type: OdooFieldType.one2many, includeInSpec: false)
  final List<int> contractIds;

  // ── Constructor ─────────────────────────────────────────────

  const HrEmployee({
    // Campos base (obligatorio pasarlos al super)
    required super.id,
    required super.name,
    super.displayName,
    super.active,
    // Campos propios
    this.jobId,
    this.departmentId,
    required this.workEmail,
    this.mobilePhone,
    this.gender,
    this.birthday,
    this.contractIds = const [],
  });

  // ── fromJson (llama baseFromJson para los campos comunes) ───

  factory HrEmployee.fromJson(Map<String, dynamic> json) {
    final base = OdooBaseModel.baseFromJson(json);
    return HrEmployee(
      id: base.id,
      name: base.name,
      displayName: base.displayName,
      active: base.active,
      // El generador produce el resto:
      jobId: _$HrEmployeeFromJsonJobId(json),
      departmentId: _$HrEmployeeFromJsonDepartmentId(json),
      workEmail: json['work_email'] == false || json['work_email'] == null
          ? ''
          : (json['work_email'] as String),
      mobilePhone: json['mobile_phone'] == false || json['mobile_phone'] == null
          ? null
          : (json['mobile_phone'] as String),
      gender: json['gender'] == false || json['gender'] == null
          ? null
          : EmployeeGender.values.byName(json['gender'] as String),
      birthday: json['birthday'] == false || json['birthday'] == null
          ? null
          : DateTime.parse(json['birthday'] as String),
      contractIds: json['contract_ids'] == false || json['contract_ids'] == null
          ? []
          : (json['contract_ids'] as List).cast<int>(),
    );
  }

  // ── specification ───────────────────────────────────────────
  // Fusiona los campos base con los del modelo concreto.

  static const Map<String, dynamic> specification = {
    ...OdooBaseModel.baseSpecification, // id, name, display_name, active
    ...HrEmployeeMeta.specification, // campos propios generados
  };

  // ── Helpers de búsqueda (wrappers ergonómicos) ───────────────

  /// Devuelve una lista de empleados que cumplen el [domain].
  static Future<List<HrEmployee>> searchFetchEmployees({
    required String baseUrl,
    required Map<String, String> headers,
    OdooDomain domain = const [],
    int limit = 80,
    int offset = 0,
    String order = 'name asc',
  }) async {
    final result = await OdooSearchMixin.searchFetch(
      baseUrl: baseUrl,
      headers: headers,
      modelName: _$HrEmployeeMeta.modelName,
      specification: specification,
      domain: domain,
      limit: limit,
      offset: offset,
      order: order,
    );
    return result.records.map(HrEmployee.fromJson).toList();
  }

  /// Lee empleados por una lista de [ids].
  static Future<List<HrEmployee>> readEmployees({
    required String baseUrl,
    required Map<String, String> headers,
    required List<int> ids,
  }) async {
    final records = await OdooSearchMixin.read(
      baseUrl: baseUrl,
      headers: headers,
      modelName: _$HrEmployeeMeta.modelName,
      ids: ids,
      specification: specification,
    );
    return records.map(HrEmployee.fromJson).toList();
  }
}

// ── Enums y sub-modelos usados arriba ──────────────────────────

enum EmployeeGender { male, female, other }

@OdooModel(modelName: 'hr.job')
class JobPosition extends OdooBaseModel {
  const JobPosition({required super.id, required super.name});

  factory JobPosition.fromJson(Map<String, dynamic> json) {
    final base = OdooBaseModel.baseFromJson(json);
    return JobPosition(id: base.id, name: base.name);
  }
}

@OdooModel(modelName: 'hr.department')
class Department extends OdooBaseModel {
  const Department({required super.id, required super.name});

  factory Department.fromJson(Map<String, dynamic> json) {
    final base = OdooBaseModel.baseFromJson(json);
    return Department(id: base.id, name: base.name);
  }
}

// Placeholders para que compile el ejemplo sin el generador activo
// (en el proyecto real estos vienen del .odoo.g.dart generado):
JobPosition? _$HrEmployeeFromJsonJobId(Map<String, dynamic> json) {
  final raw = json['job_id'];
  if (raw == false || raw == null) return null;
  return JobPosition.fromJson(
    raw is List
        ? {'id': raw.isNotEmpty ? raw[0] : null, 'name': raw.length > 1 ? raw[1] : null}
        : raw as Map<String, dynamic>,
  );
}

Department? _$HrEmployeeFromJsonDepartmentId(Map<String, dynamic> json) {
  final raw = json['department_id'];
  if (raw == false || raw == null) return null;
  return Department.fromJson(
    raw is List
        ? {'id': raw.isNotEmpty ? raw[0] : null, 'name': raw.length > 1 ? raw[1] : null}
        : raw as Map<String, dynamic>,
  );
}

// Placeholder de la clase meta (la produce el generador):
class HrEmployeeMeta {
  static const String modelName = 'hr.employee';
  static const Map<String, dynamic> specification = {
    'job_id': {
      'fields': {'id': {}, 'name': {}}
    },
    'department_id': {
      'fields': {'id': {}, 'name': {}}
    },
    'work_email': {},
    'mobile_phone': {},
    'gender': {},
    'birthday': {},
  };
}
