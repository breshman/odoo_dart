/// Operadores de comparación y búsqueda admitidos por el ORM de Odoo.
enum OdooOp {
  /// Igualdad exacta (`'='`)
  equals('='),

  /// Desigualdad (`'!='`)
  notEquals('!='),

  /// Mayor que (`'>'`)
  greaterThan('>'),

  /// Mayor o igual que (`'>='`)
  greaterOrEqual('>='),

  /// Menor que (`'<'`)
  lessThan('<'),

  /// Menor o igual que (`'<='`)
  lessOrEqual('<='),

  /// Búsqueda con comodines sensible a mayúsculas/minúsculas (`'like'`)
  like('like'),

  /// Búsqueda insensible a mayúsculas/minúsculas (`'ilike'`)
  ilike('ilike'),

  /// Negación de like (`'not like'`)
  notLike('not like'),

  /// Negación de ilike (`'not ilike'`)
  notIlike('not ilike'),

  /// Pertenencia a lista o conjunto (`'in'`)
  inList('in'),

  /// No pertenencia a lista o conjunto (`'not in'`)
  notInList('not in'),

  /// Jerárquico: registro hijo de (`'child_of'`)
  childOf('child_of'),

  /// Jerárquico: registro padre de (`'parent_of'`)
  parentOf('parent_of');

  final String symbol;
  const OdooOp(this.symbol);
}

/// Clase base sellada para términos y árboles lógicos de dominio en Odoo.
///
/// Todas las expresiones de dominio se compilan a una lista de criterios y operadores
/// en notación polaca prefija esperada por JSON-RPC de Odoo.
///
/// Ejemplo:
/// ```dart
/// final term = Domain.or([
///   'name'.equals('Admin'),
///   'name'.ilike('demo'),
/// ]);
/// print(term.toOdoo()); // ['|', ['name', '=', 'Admin'], ['name', 'ilike', 'demo']]
/// ```
sealed class OdooDomainTerm {
  const OdooDomainTerm();

  /// Compila el término a la lista plana compatible con el RPC de Odoo.
  List<dynamic> toOdoo();
}

/// Representa una condición individual: `[campo, operador, valor]`.
///
/// ```dart
/// const cond = Condition('is_company', OdooOp.equals, true);
/// print(cond.toOdoo()); // ['is_company', '=', true]
/// ```
class Condition<T> extends OdooDomainTerm {
  final String field;
  final OdooOp op;
  final T value;

  const Condition(this.field, this.op, this.value);

  @override
  List<dynamic> toOdoo() => [field, op.symbol, value];

  @override
  String toString() => 'Condition($field ${op.symbol} $value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Condition &&
          runtimeType == other.runtimeType &&
          field == other.field &&
          op == other.op &&
          value == other.value;

  @override
  int get hashCode => field.hashCode ^ op.hashCode ^ value.hashCode;
}

/// Operador lógico OR (`'|'`) de Odoo en notación polaca inversa.
///
/// Odoo requiere $N-1$ operadores `'|'` para $N$ operandos.
class OrTerm extends OdooDomainTerm {
  final List<OdooDomainTerm> terms;

  const OrTerm(this.terms);

  @override
  List<dynamic> toOdoo() {
    if (terms.isEmpty) return const [];
    if (terms.length == 1) return _flattenChild(terms.first);

    final result = <dynamic>[];
    // Notación polaca: n - 1 barras verticales para n términos
    for (int i = 0; i < terms.length - 1; i++) {
      result.add('|');
    }
    for (final term in terms) {
      result.addAll(_flattenChild(term));
    }
    return result;
  }

  List<dynamic> _flattenChild(OdooDomainTerm term) {
    if (term is Condition) {
      return [term.toOdoo()];
    }
    return term.toOdoo();
  }

  @override
  String toString() => 'Or(${terms.join(', ')})';
}

/// Operador lógico AND explícito (`'&'`) o lista de condiciones conjuntas.
class AndTerm extends OdooDomainTerm {
  final List<OdooDomainTerm> terms;
  final bool explicit;

  const AndTerm(this.terms, {this.explicit = false});

  @override
  List<dynamic> toOdoo() {
    if (terms.isEmpty) return const [];
    if (terms.length == 1) return _flattenChild(terms.first);

    final result = <dynamic>[];
    if (explicit) {
      for (int i = 0; i < terms.length - 1; i++) {
        result.add('&');
      }
    }
    for (final term in terms) {
      result.addAll(_flattenChild(term));
    }
    return result;
  }

  List<dynamic> _flattenChild(OdooDomainTerm term) {
    if (term is Condition) {
      return [term.toOdoo()];
    }
    return term.toOdoo();
  }

  @override
  String toString() => 'And(${terms.join(', ')})';
}

/// Operador lógico NOT (`'!'`).
class NotTerm extends OdooDomainTerm {
  final OdooDomainTerm term;

  const NotTerm(this.term);

  @override
  List<dynamic> toOdoo() {
    final compiled = term is Condition ? [term.toOdoo()] : term.toOdoo();
    return ['!', ...compiled];
  }

  @override
  String toString() => 'Not($term)';
}

/// Envoltorio para permitir inyectar expresiones crudas existentes
/// dentro de árboles de dominios tipados.
class RawDomainTerm extends OdooDomainTerm {
  final List<dynamic> raw;

  const RawDomainTerm(this.raw);

  @override
  List<dynamic> toOdoo() => raw;

  @override
  String toString() => 'RawDomain($raw)';
}

/// Constructor estático fluido (*DSL*) para dominios Odoo.
///
/// Permite redactar dominios sin cadenas mágicas y con validación de tipo en tiempo de compilación.
///
/// Ejemplo:
/// ```dart
/// final domain = Domain.or([
///   Domain.equals('state', 'draft'),
///   Domain.and([
///     Domain.equals('state', 'confirmed'),
///     Domain.greaterThan('qty_done', 0),
///   ]),
/// ]);
/// ```
abstract final class Domain {
  /// Condición de igualdad: `[field, '=', value]`
  static Condition<T> equals<T>(String field, T value) =>
      Condition<T>(field, OdooOp.equals, value);

  /// Alias de [equals]
  static Condition<T> eq<T>(String field, T value) => equals<T>(field, value);

  /// Condición de desigualdad: `[field, '!=', value]`
  static Condition<T> notEquals<T>(String field, T value) =>
      Condition<T>(field, OdooOp.notEquals, value);

  /// Alias de [notEquals]
  static Condition<T> ne<T>(String field, T value) => notEquals<T>(field, value);

  /// Condición mayor que: `[field, '>', value]`
  static Condition<T> greaterThan<T>(String field, T value) =>
      Condition<T>(field, OdooOp.greaterThan, value);

  /// Alias de [greaterThan]
  static Condition<T> gt<T>(String field, T value) => greaterThan<T>(field, value);

  /// Condición mayor o igual que: `[field, '>=', value]`
  static Condition<T> greaterOrEqual<T>(String field, T value) =>
      Condition<T>(field, OdooOp.greaterOrEqual, value);

  /// Alias de [greaterOrEqual]
  static Condition<T> gte<T>(String field, T value) => greaterOrEqual<T>(field, value);

  /// Condición menor que: `[field, '<', value]`
  static Condition<T> lessThan<T>(String field, T value) =>
      Condition<T>(field, OdooOp.lessThan, value);

  /// Alias de [lessThan]
  static Condition<T> lt<T>(String field, T value) => lessThan<T>(field, value);

  /// Condición menor o igual que: `[field, '<=', value]`
  static Condition<T> lessOrEqual<T>(String field, T value) =>
      Condition<T>(field, OdooOp.lessOrEqual, value);

  /// Alias de [lessOrEqual]
  static Condition<T> lte<T>(String field, T value) => lessOrEqual<T>(field, value);

  /// Búsqueda case-insensitive: `[field, 'ilike', value]`
  static Condition<String> ilike(String field, String value) =>
      Condition<String>(field, OdooOp.ilike, value);

  /// Búsqueda case-sensitive: `[field, 'like', value]`
  static Condition<String> like(String field, String value) =>
      Condition<String>(field, OdooOp.like, value);

  /// Negación de búsqueda ilike: `[field, 'not ilike', value]`
  static Condition<String> notIlike(String field, String value) =>
      Condition<String>(field, OdooOp.notIlike, value);

  /// Pertenencia a lista: `[field, 'in', values]`
  static Condition<List<T>> inList<T>(String field, List<T> values) =>
      Condition<List<T>>(field, OdooOp.inList, values);

  /// No pertenencia a lista: `[field, 'not in', values]`
  static Condition<List<T>> notInList<T>(String field, List<T> values) =>
      Condition<List<T>>(field, OdooOp.notInList, values);

  /// Jerárquico hijo de: `[field, 'child_of', value]`
  static Condition<T> childOf<T>(String field, T value) =>
      Condition<T>(field, OdooOp.childOf, value);

  /// Agrupación lógica OR (`'|'`)
  static OrTerm or(List<OdooDomainTerm> terms) => OrTerm(terms);

  /// Agrupación lógica AND (lista secuencial de criterios o explícita)
  static AndTerm and(List<OdooDomainTerm> terms, {bool explicit = false}) =>
      AndTerm(terms, explicit: explicit);

  /// Negación lógica NOT (`'!'`)
  static NotTerm not(OdooDomainTerm term) => NotTerm(term);

  /// Envuelve una lista de dominio crudo preexistente
  static RawDomainTerm fromRaw(List<dynamic> raw) => RawDomainTerm(raw);
}

/// Extensiones sintácticas sobre [String] para construir condiciones fluidas
/// directamente a partir de nombres de campo (como los generados por `odoo_generator`).
///
/// Ejemplo:
/// ```dart
/// final domain = Domain.or([
///   StockPackageFields.name.equals('PALLET-001'),
///   StockPackageFields.name.ilike('BOX%'),
/// ]);
/// ```
extension OdooFieldDomainExtension on String {
  /// Genera una condición de igualdad: `[this, '=', value]`
  Condition<T> equals<T>(T value) => Condition<T>(this, OdooOp.equals, value);

  /// Genera una condición de desigualdad: `[this, '!=', value]`
  Condition<T> notEquals<T>(T value) => Condition<T>(this, OdooOp.notEquals, value);

  /// Genera una condición mayor que: `[this, '>', value]`
  Condition<T> greaterThan<T>(T value) => Condition<T>(this, OdooOp.greaterThan, value);

  /// Genera una condición mayor o igual que: `[this, '>=', value]`
  Condition<T> greaterOrEqual<T>(T value) => Condition<T>(this, OdooOp.greaterOrEqual, value);

  /// Genera una condición menor que: `[this, '<', value]`
  Condition<T> lessThan<T>(T value) => Condition<T>(this, OdooOp.lessThan, value);

  /// Genera una condición menor o igual que: `[this, '<=', value]`
  Condition<T> lessOrEqual<T>(T value) => Condition<T>(this, OdooOp.lessOrEqual, value);

  /// Genera una condición ilike: `[this, 'ilike', value]`
  Condition<String> ilike(String value) => Condition<String>(this, OdooOp.ilike, value);

  /// Genera una condición like: `[this, 'like', value]`
  Condition<String> like(String value) => Condition<String>(this, OdooOp.like, value);

  /// Genera una condición not ilike: `[this, 'not ilike', value]`
  Condition<String> notIlike(String value) => Condition<String>(this, OdooOp.notIlike, value);

  /// Genera una condición in: `[this, 'in', values]`
  Condition<List<T>> inList<T>(List<T> values) => Condition<List<T>>(this, OdooOp.inList, values);

  /// Genera una condición not in: `[this, 'not in', values]`
  Condition<List<T>> notInList<T>(List<T> values) => Condition<List<T>>(this, OdooOp.notInList, values);

  /// Genera una condición child_of: `[this, 'child_of', value]`
  Condition<T> childOf<T>(T value) => Condition<T>(this, OdooOp.childOf, value);
}

/// Extensiones sintácticas sobre [Enum] (como los enums `*Fields` generados
/// por `odoo_generator`) para construir condiciones fuertemente tipadas sin cadenas mágicas.
///
/// Ejemplo:
/// ```dart
/// final domain = Domain.or([
///   StockPackageFields.name.equals('PALLET-001'),
///   StockPackageFields.packageTypeId.ilike('BOX%'),
/// ]);
/// ```
extension OdooEnumDomainExtension on Enum {
  /// Convierte el nombre camelCase del enum al formato snake_case esperado por Odoo.
  String get odooFieldName {
    return name.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
  }

  /// Genera una condición de igualdad: `[odooFieldName, '=', value]`
  Condition<T> equals<T>(T value) => Condition<T>(odooFieldName, OdooOp.equals, value);

  /// Genera una condición de desigualdad: `[odooFieldName, '!=', value]`
  Condition<T> notEquals<T>(T value) => Condition<T>(odooFieldName, OdooOp.notEquals, value);

  /// Genera una condición mayor que: `[odooFieldName, '>', value]`
  Condition<T> greaterThan<T>(T value) => Condition<T>(odooFieldName, OdooOp.greaterThan, value);

  /// Genera una condición mayor o igual que: `[odooFieldName, '>=', value]`
  Condition<T> greaterOrEqual<T>(T value) => Condition<T>(odooFieldName, OdooOp.greaterOrEqual, value);

  /// Genera una condición menor que: `[odooFieldName, '<', value]`
  Condition<T> lessThan<T>(T value) => Condition<T>(odooFieldName, OdooOp.lessThan, value);

  /// Genera una condición menor o igual que: `[odooFieldName, '<=', value]`
  Condition<T> lessOrEqual<T>(T value) => Condition<T>(odooFieldName, OdooOp.lessOrEqual, value);

  /// Genera una condición ilike: `[odooFieldName, 'ilike', value]`
  Condition<String> ilike(String value) => Condition<String>(odooFieldName, OdooOp.ilike, value);

  /// Genera una condición like: `[odooFieldName, 'like', value]`
  Condition<String> like(String value) => Condition<String>(odooFieldName, OdooOp.like, value);

  /// Genera una condición not ilike: `[odooFieldName, 'not ilike', value]`
  Condition<String> notIlike(String value) => Condition<String>(odooFieldName, OdooOp.notIlike, value);

  /// Genera una condición in: `[odooFieldName, 'in', values]`
  Condition<List<T>> inList<T>(List<T> values) => Condition<List<T>>(odooFieldName, OdooOp.inList, values);

  /// Genera una condición not in: `[odooFieldName, 'not in', values]`
  Condition<List<T>> notInList<T>(List<T> values) => Condition<List<T>>(odooFieldName, OdooOp.notInList, values);

  /// Genera una condición child_of: `[odooFieldName, 'child_of', value]`
  Condition<T> childOf<T>(T value) => Condition<T>(odooFieldName, OdooOp.childOf, value);
}
