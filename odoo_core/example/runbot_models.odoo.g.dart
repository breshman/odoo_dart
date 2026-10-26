// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'runbot_models.dart';

// **************************************************************************
// OdooModelGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY BR

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

mixin _$Partner {
  Map<String, dynamic> toJson() => _$PartnerToJson(this as Partner);
  Map<String, dynamic> toOdoo() =>
      _$PartnerToJson(this as Partner, toOdoo: true);

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
    final instance = this as Partner;
    return Partner(
      id: id ?? instance.id,
      name: name ?? instance.name,
      displayName: displayName ?? instance.displayName,
      createDate: createDate ?? instance.createDate,
      writeDate: writeDate ?? instance.writeDate,
      email: email ?? instance.email,
      phone: phone ?? instance.phone,
      street: street ?? instance.street,
      lang: lang ?? instance.lang,
    );
  }

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

  static PartnerSpecificationBuilder buildSpecification(
      {Iterable<PartnerFields>? only, Map<PartnerFields, Object>? nested}) {
    final builder = PartnerSpecificationBuilder();
    if (only != null) builder.addOnly(only);
    if (nested != null) builder.addNestedMap(nested);
    return builder;
  }
}

class PartnerSpecificationBuilder implements SpecificationBuilder {
  final List<PartnerFields> _only = [];
  final Map<PartnerFields, Map<String, dynamic>> _nested = {};

  PartnerSpecificationBuilder addOnly(Iterable<PartnerFields> fields) {
    _only.addAll(fields);
    return this;
  }

  PartnerSpecificationBuilder addField(PartnerFields field) {
    _only.add(field);
    return this;
  }

  PartnerSpecificationBuilder addNested(PartnerFields field, Object spec) {
    final resolved = spec is SpecificationBuilder
        ? spec.build()
        : (spec is Map<String, dynamic>
            ? spec
            : Map<String, dynamic>.from(spec as Map));
    _nested[field] = resolved;
    return this;
  }

  PartnerSpecificationBuilder addNestedMap(Map<PartnerFields, Object> map) {
    map.forEach((field, spec) => addNested(field, spec));
    return this;
  }

  @override
  Map<String, dynamic> build() {
    if (_only.isEmpty && _nested.isEmpty) {
      return _$PartnerMeta.specification;
    }
    final spec = <String, dynamic>{};
    for (final f in _only) {
      final odooKey = _$PartnerMeta.fieldMapping[f.name] ?? f.name;
      spec[odooKey] = _$PartnerMeta.specification[odooKey] ?? {};
    }
    _nested.forEach((f, subSpec) {
      final odooKey = _$PartnerMeta.fieldMapping[f.name] ?? f.name;
      spec[odooKey] = {'fields': subSpec};
    });
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

  static PartnerSpecificationBuilder buildSpecification(
          {Iterable<PartnerFields>? only,
          Map<PartnerFields, Object>? nested}) =>
      _$PartnerMeta.buildSpecification(only: only, nested: nested);
}

// GENERATED CODE - DO NOT MODIFY BY BR

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

mixin _$User {
  Map<String, dynamic> toJson() => _$UserToJson(this as User);
  Map<String, dynamic> toOdoo() => _$UserToJson(this as User, toOdoo: true);

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
    final instance = this as User;
    return User(
      id: id ?? instance.id,
      name: name ?? instance.name,
      displayName: displayName ?? instance.displayName,
      createDate: createDate ?? instance.createDate,
      writeDate: writeDate ?? instance.writeDate,
      createUid: createUid ?? instance.createUid,
      writeUid: writeUid ?? instance.writeUid,
      login: login ?? instance.login,
    );
  }

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

  static UserSpecificationBuilder buildSpecification(
      {Iterable<UserFields>? only, Map<UserFields, Object>? nested}) {
    final builder = UserSpecificationBuilder();
    if (only != null) builder.addOnly(only);
    if (nested != null) builder.addNestedMap(nested);
    return builder;
  }
}

class UserSpecificationBuilder implements SpecificationBuilder {
  final List<UserFields> _only = [];
  final Map<UserFields, Map<String, dynamic>> _nested = {};

  UserSpecificationBuilder addOnly(Iterable<UserFields> fields) {
    _only.addAll(fields);
    return this;
  }

  UserSpecificationBuilder addField(UserFields field) {
    _only.add(field);
    return this;
  }

  UserSpecificationBuilder addNested(UserFields field, Object spec) {
    final resolved = spec is SpecificationBuilder
        ? spec.build()
        : (spec is Map<String, dynamic>
            ? spec
            : Map<String, dynamic>.from(spec as Map));
    _nested[field] = resolved;
    return this;
  }

  UserSpecificationBuilder addNestedMap(Map<UserFields, Object> map) {
    map.forEach((field, spec) => addNested(field, spec));
    return this;
  }

  @override
  Map<String, dynamic> build() {
    if (_only.isEmpty && _nested.isEmpty) {
      return _$UserMeta.specification;
    }
    final spec = <String, dynamic>{};
    for (final f in _only) {
      final odooKey = _$UserMeta.fieldMapping[f.name] ?? f.name;
      spec[odooKey] = _$UserMeta.specification[odooKey] ?? {};
    }
    _nested.forEach((f, subSpec) {
      final odooKey = _$UserMeta.fieldMapping[f.name] ?? f.name;
      spec[odooKey] = {'fields': subSpec};
    });
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

  static UserSpecificationBuilder buildSpecification(
          {Iterable<UserFields>? only, Map<UserFields, Object>? nested}) =>
      _$UserMeta.buildSpecification(only: only, nested: nested);
}

// GENERATED CODE - DO NOT MODIFY BY BR

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

mixin _$Employee {
  Map<String, dynamic> toJson() => _$EmployeeToJson(this as Employee);
  Map<String, dynamic> toOdoo() =>
      _$EmployeeToJson(this as Employee, toOdoo: true);

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
    final instance = this as Employee;
    return Employee(
      id: id ?? instance.id,
      name: name ?? instance.name,
      displayName: displayName ?? instance.displayName,
      createDate: createDate ?? instance.createDate,
      writeDate: writeDate ?? instance.writeDate,
      createUid: createUid ?? instance.createUid,
      writeUid: writeUid ?? instance.writeUid,
      jobTitle: jobTitle ?? instance.jobTitle,
    );
  }

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

  static EmployeeSpecificationBuilder buildSpecification(
      {Iterable<EmployeeFields>? only, Map<EmployeeFields, Object>? nested}) {
    final builder = EmployeeSpecificationBuilder();
    if (only != null) builder.addOnly(only);
    if (nested != null) builder.addNestedMap(nested);
    return builder;
  }
}

class EmployeeSpecificationBuilder implements SpecificationBuilder {
  final List<EmployeeFields> _only = [];
  final Map<EmployeeFields, Map<String, dynamic>> _nested = {};

  EmployeeSpecificationBuilder addOnly(Iterable<EmployeeFields> fields) {
    _only.addAll(fields);
    return this;
  }

  EmployeeSpecificationBuilder addField(EmployeeFields field) {
    _only.add(field);
    return this;
  }

  EmployeeSpecificationBuilder addNested(EmployeeFields field, Object spec) {
    final resolved = spec is SpecificationBuilder
        ? spec.build()
        : (spec is Map<String, dynamic>
            ? spec
            : Map<String, dynamic>.from(spec as Map));
    _nested[field] = resolved;
    return this;
  }

  EmployeeSpecificationBuilder addNestedMap(Map<EmployeeFields, Object> map) {
    map.forEach((field, spec) => addNested(field, spec));
    return this;
  }

  @override
  Map<String, dynamic> build() {
    if (_only.isEmpty && _nested.isEmpty) {
      return _$EmployeeMeta.specification;
    }
    final spec = <String, dynamic>{};
    for (final f in _only) {
      final odooKey = _$EmployeeMeta.fieldMapping[f.name] ?? f.name;
      spec[odooKey] = _$EmployeeMeta.specification[odooKey] ?? {};
    }
    _nested.forEach((f, subSpec) {
      final odooKey = _$EmployeeMeta.fieldMapping[f.name] ?? f.name;
      spec[odooKey] = {'fields': subSpec};
    });
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

  static EmployeeSpecificationBuilder buildSpecification(
          {Iterable<EmployeeFields>? only,
          Map<EmployeeFields, Object>? nested}) =>
      _$EmployeeMeta.buildSpecification(only: only, nested: nested);
}
