// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'runbot_models.dart';

// **************************************************************************
// OdooModelGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint

Partner _$PartnerFromJson(Map<String, dynamic> json) {
  final base = OdooBaseModel.baseFromJson(json);
  return Partner(
    id: base.id,
    name: base.name,
    displayName: base.displayName,
    createDate: base.createDate,
    writeDate: base.writeDate,
    email: json['email'] == false || json['email'] == null
        ? null
        : (json['email'].toString()),
    phone: json['phone'] == false || json['phone'] == null
        ? null
        : (json['phone'].toString()),
    street: json['street'] == false || json['street'] == null
        ? null
        : (json['street'].toString()),
    lang: json['lang'] == false || json['lang'] == null
        ? null
        : (json['lang'].toString()),
  );
}

Map<String, dynamic> _$PartnerToJson(Partner instance, {bool toOdoo = false}) {
  return {
    ...instance.baseToJson(toOdoo: toOdoo),
    if (instance.email != null) 'email': instance.email!,
    if (instance.phone != null) 'phone': instance.phone!,
    if (instance.street != null) 'street': instance.street!,
    if (instance.lang != null) 'lang': instance.lang!,
  };
}

extension $PartnerExtension on Partner {
  Map<String, dynamic> toJson() => _$PartnerToJson(this);
  Map<String, dynamic> toOdoo() => _$PartnerToJson(this, toOdoo: true);

  Partner copyWith({
    int? id,
    String? name,
    String? displayName,
    DateTime? createDate,
    DateTime? writeDate,
    String? email,
    String? phone,
    String? street,
    String? lang,
  }) {
    return Partner(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      createDate: createDate ?? this.createDate,
      writeDate: writeDate ?? this.writeDate,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      street: street ?? this.street,
      lang: lang ?? this.lang,
    );
  }
}

mixin _$Partner {
  Map<String, dynamic> toJson() => _$PartnerToJson(this as Partner);
  Map<String, dynamic> toOdoo() =>
      _$PartnerToJson(this as Partner, toOdoo: true);

  @override
  String toString() {
    final instance = this as Partner;
    return 'Partner('
        'id: ${instance.id}, '
        'name: ${instance.name}, '
        'email: ${instance.email}, '
        'phone: ${instance.phone}, '
        'street: ${instance.street}, '
        'lang: ${instance.lang}'
        ')';
  }
}

enum PartnerFields {
  id,
  name,
  displayName,
  createDate,
  writeDate,
  createUid,
  writeUid,
  email,
  phone,
  street,
  lang,
}

mixin _$PartnerMeta {
  static const String modelName = 'res.partner';

  static const Map<String, dynamic> specification = {
    ...OdooBaseModel.baseSpecification,
    'email': {},
    'phone': {},
    'street': {},
    'lang': {},
  };

  static const Map<String, String> fieldMapping = {
    'id': 'id',
    'name': 'name',
    'displayName': 'display_name',
    'createDate': 'create_date',
    'writeDate': 'write_date',
    'createUid': 'create_uid',
    'writeUid': 'write_uid',
    'email': 'email',
    'phone': 'phone',
    'street': 'street',
    'lang': 'lang',
  };

  static Map<String, dynamic> buildSpecification(
      {List<PartnerFields>? only,
      Map<PartnerFields, Map<String, dynamic>>? nested}) {
    final spec = <String, dynamic>{};
    if (only != null) {
      for (final f in only) {
        final odooKey = fieldMapping[f.name] ?? f.name;
        spec[odooKey] = specification[odooKey] ?? {};
      }
    }
    if (nested != null) {
      nested.forEach((f, subSpec) {
        final odooKey = fieldMapping[f.name] ?? f.name;
        spec[odooKey] = {'fields': subSpec};
      });
    }
    if (only == null && nested == null) return specification;
    return spec;
  }
}

class PartnerRepository extends OdooRepository<Partner> {
  PartnerRepository({required super.client})
      : super(
          modelName: _$PartnerMeta.modelName,
          specification: _$PartnerMeta.specification,
          fromJson: _$PartnerFromJson,
        );
}

// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint

User _$UserFromJson(Map<String, dynamic> json) {
  final base = OdooBaseModel.baseFromJson(json);
  return User(
    id: base.id,
    name: base.name,
    displayName: base.displayName,
    createDate: base.createDate,
    writeDate: base.writeDate,
    createUid: base.createUid,
    writeUid: base.writeUid,
    login: json['login'] == false || json['login'] == null
        ? null
        : (json['login'].toString()),
  );
}

Map<String, dynamic> _$UserToJson(User instance, {bool toOdoo = false}) {
  return {
    ...instance.baseToJson(toOdoo: toOdoo),
    if (instance.login != null) 'login': instance.login!,
  };
}

extension $UserExtension on User {
  Map<String, dynamic> toJson() => _$UserToJson(this);
  Map<String, dynamic> toOdoo() => _$UserToJson(this, toOdoo: true);

  User copyWith({
    int? id,
    String? name,
    String? displayName,
    DateTime? createDate,
    DateTime? writeDate,
    int? createUid,
    int? writeUid,
    String? login,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      createDate: createDate ?? this.createDate,
      writeDate: writeDate ?? this.writeDate,
      createUid: createUid ?? this.createUid,
      writeUid: writeUid ?? this.writeUid,
      login: login ?? this.login,
    );
  }
}

mixin _$User {
  Map<String, dynamic> toJson() => _$UserToJson(this as User);
  Map<String, dynamic> toOdoo() => _$UserToJson(this as User, toOdoo: true);

  @override
  String toString() {
    final instance = this as User;
    return 'User('
        'id: ${instance.id}, '
        'name: ${instance.name}, '
        'login: ${instance.login}'
        ')';
  }
}

enum UserFields {
  id,
  name,
  displayName,
  createDate,
  writeDate,
  createUid,
  writeUid,
  login,
}

mixin _$UserMeta {
  static const String modelName = 'res.users';

  static const Map<String, dynamic> specification = {
    ...OdooBaseModel.baseSpecification,
    'login': {},
  };

  static const Map<String, String> fieldMapping = {
    'id': 'id',
    'name': 'name',
    'displayName': 'display_name',
    'createDate': 'create_date',
    'writeDate': 'write_date',
    'createUid': 'create_uid',
    'writeUid': 'write_uid',
    'login': 'login',
  };

  static Map<String, dynamic> buildSpecification(
      {List<UserFields>? only, Map<UserFields, Map<String, dynamic>>? nested}) {
    final spec = <String, dynamic>{};
    if (only != null) {
      for (final f in only) {
        final odooKey = fieldMapping[f.name] ?? f.name;
        spec[odooKey] = specification[odooKey] ?? {};
      }
    }
    if (nested != null) {
      nested.forEach((f, subSpec) {
        final odooKey = fieldMapping[f.name] ?? f.name;
        spec[odooKey] = {'fields': subSpec};
      });
    }
    if (only == null && nested == null) return specification;
    return spec;
  }
}

class UserRepository extends OdooRepository<User> {
  UserRepository({required super.client})
      : super(
          modelName: _$UserMeta.modelName,
          specification: _$UserMeta.specification,
          fromJson: _$UserFromJson,
        );
}

// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint

Employee _$EmployeeFromJson(Map<String, dynamic> json) {
  final base = OdooBaseModel.baseFromJson(json);
  return Employee(
    id: base.id,
    name: base.name,
    displayName: base.displayName,
    createDate: base.createDate,
    writeDate: base.writeDate,
    createUid: base.createUid,
    writeUid: base.writeUid,
    jobTitle: json['job_title'] == false || json['job_title'] == null
        ? null
        : (json['job_title'].toString()),
  );
}

Map<String, dynamic> _$EmployeeToJson(Employee instance,
    {bool toOdoo = false}) {
  return {
    ...instance.baseToJson(toOdoo: toOdoo),
    if (instance.jobTitle != null) 'job_title': instance.jobTitle!,
  };
}

extension $EmployeeExtension on Employee {
  Map<String, dynamic> toJson() => _$EmployeeToJson(this);
  Map<String, dynamic> toOdoo() => _$EmployeeToJson(this, toOdoo: true);

  Employee copyWith({
    int? id,
    String? name,
    String? displayName,
    DateTime? createDate,
    DateTime? writeDate,
    int? createUid,
    int? writeUid,
    String? jobTitle,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      createDate: createDate ?? this.createDate,
      writeDate: writeDate ?? this.writeDate,
      createUid: createUid ?? this.createUid,
      writeUid: writeUid ?? this.writeUid,
      jobTitle: jobTitle ?? this.jobTitle,
    );
  }
}

mixin _$Employee {
  Map<String, dynamic> toJson() => _$EmployeeToJson(this as Employee);
  Map<String, dynamic> toOdoo() =>
      _$EmployeeToJson(this as Employee, toOdoo: true);

  @override
  String toString() {
    final instance = this as Employee;
    return 'Employee('
        'id: ${instance.id}, '
        'name: ${instance.name}, '
        'jobTitle: ${instance.jobTitle}'
        ')';
  }
}

enum EmployeeFields {
  id,
  name,
  displayName,
  createDate,
  writeDate,
  createUid,
  writeUid,
  jobTitle,
}

mixin _$EmployeeMeta {
  static const String modelName = 'hr.employee';

  static const Map<String, dynamic> specification = {
    ...OdooBaseModel.baseSpecification,
    'job_title': {},
  };

  static const Map<String, String> fieldMapping = {
    'id': 'id',
    'name': 'name',
    'displayName': 'display_name',
    'createDate': 'create_date',
    'writeDate': 'write_date',
    'createUid': 'create_uid',
    'writeUid': 'write_uid',
    'jobTitle': 'job_title',
  };

  static Map<String, dynamic> buildSpecification(
      {List<EmployeeFields>? only,
      Map<EmployeeFields, Map<String, dynamic>>? nested}) {
    final spec = <String, dynamic>{};
    if (only != null) {
      for (final f in only) {
        final odooKey = fieldMapping[f.name] ?? f.name;
        spec[odooKey] = specification[odooKey] ?? {};
      }
    }
    if (nested != null) {
      nested.forEach((f, subSpec) {
        final odooKey = fieldMapping[f.name] ?? f.name;
        spec[odooKey] = {'fields': subSpec};
      });
    }
    if (only == null && nested == null) return specification;
    return spec;
  }
}

class EmployeeRepository extends OdooRepository<Employee> {
  EmployeeRepository({required super.client})
      : super(
          modelName: _$EmployeeMeta.modelName,
          specification: _$EmployeeMeta.specification,
          fromJson: _$EmployeeFromJson,
        );
}
