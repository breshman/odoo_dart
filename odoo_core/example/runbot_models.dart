import 'package:odoo_core/odoo_core.dart';

part 'runbot_models.odoo.g.dart';

@OdooModel(modelName: 'res.partner')
class Partner extends OdooBaseModel with _$Partner {
  @OdooField(type: OdooFieldType.string, name: 'email')
  final String? email;

  @OdooField(type: OdooFieldType.string, name: 'phone')
  final String? phone;

  @OdooField(type: OdooFieldType.boolean, name: 'is_customer')
  final bool? isOptimized;

  Partner({
    required super.id,
    required super.name,
    super.displayName,
    super.createDate,
    super.writeDate,
    // super.createUid,
    // super.writeUid,
    this.email,
    this.phone,
    this.isOptimized,
  });

  bool get isCustomer => true;

  bool get isVendor => true;

  set isCustomer(bool value) {
    isCustomer = value;
  }

  factory Partner.fromJson(Map<String, dynamic> json) =>
      _$PartnerFromJson(json);
}

@OdooModel(modelName: 'res.users')
class User extends OdooBaseModel with _$User {
  @OdooField(type: OdooFieldType.string, name: 'login')
  final String? login;

  User({
    required super.id,
    required super.name,
    super.displayName,
    super.createDate,
    super.writeDate,
    super.createUid,
    super.writeUid,
    this.login,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@OdooModel(modelName: 'hr.employee')
class Employee extends OdooBaseModel with _$Employee {
  @OdooField(type: OdooFieldType.string, name: 'job_title')
  final String? jobTitle;
  @OdooField(type: OdooFieldType.dynamic_, name: 'company_ids')
  final List<int>? companyIds;

  Employee({
    required super.id,
    required super.name,
    super.displayName,
    super.createDate,
    super.writeDate,
    super.createUid,
    super.writeUid,
    this.jobTitle,
    this.companyIds,
  });

  factory Employee.fromJson(Map<String, dynamic> json) =>
      _$EmployeeFromJson(json);
}
