import 'package:odoo_core/odoo_core.dart';

part 'runbot_models.odoo.g.dart';

@OdooModel(modelName: 'res.partner')
class Partner extends OdooBaseModel with _$Partner {
  @OdooField(type: OdooFieldType.string)
  final String? email;

  @OdooField(type: OdooFieldType.string)
  final String? phone;

  @OdooField(type: OdooFieldType.string, name: 'street')
  final String? street;
  @OdooField(type: OdooFieldType.string)
  final String? lang;

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
    this.street,
    this.lang,
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

  Employee({
    required super.id,
    required super.name,
    super.displayName,
    super.createDate,
    super.writeDate,
    super.createUid,
    super.writeUid,
    this.jobTitle,
  });

  factory Employee.fromJson(Map<String, dynamic> json) =>
      _$EmployeeFromJson(json);
}
