# odoo_generator

[![pub.dev](https://img.shields.io/badge/pub.dev-odoo__generator-blue)](https://pub.dev)
[![Dart 3](https://img.shields.io/badge/Dart-3.x-0175C2)](https://dart.dev)

Generador de código fuente para `odoo_core`. Convierte clases Dart anotadas con `@OdooModel` / `@OdooField` en repositorios tipados, métodos `fromJson`/`toJson`, especificaciones de campos, enums para selección dinámica y el método `copyWith`.

---

## 📦 Instalación

```yaml
# pubspec.yaml
dependencies:
  odoo_core:
    path: ../odoo_core

dev_dependencies:
  odoo_generator:
    path: ../odoo_generator
  build_runner: ^2.4.0
```

---

## 🏗️ 1. Definir un Modelo

Anota tu clase con `@OdooModel` y sus campos con `@OdooField`:

```dart
import 'package:odoo_core/odoo_core.dart';

part 'partner.odoo.g.dart';

@OdooModel(modelName: 'res.partner')
class Partner extends OdooBaseModel with _$Partner {

  @OdooField(type: OdooFieldType.string)
  final String? email;

  @OdooField(type: OdooFieldType.string)
  final String? phone;

  // ✅ camelCase → snake_case automático (v2.2+)
  // isCompany → is_company  (sin necesidad de name: 'is_company')
  @OdooField(type: OdooFieldType.boolean)
  final bool? isCompany;

  // categoryId → category_id automático
  @OdooField(type: OdooFieldType.many2one)
  final int? categoryId;

  // Nombre explícito cuando la convención no aplica
  @OdooField(type: OdooFieldType.string, name: 'vat')
  final String? taxId;

  Partner({
    required super.id,
    required super.name,
    super.displayName,
    super.writeDate,
    this.email,
    this.phone,
    this.isCompany,
    this.categoryId,
    this.taxId,
  });

  factory Partner.fromJson(Map<String, dynamic> json) =>
      _$PartnerFromJson(json);
}
```

---

## ⚙️ 2. Tipos de Campo (`OdooFieldType`)

| Tipo | Uso en Dart | Campo Odoo |
|---|---|---|
| `string` | `String?` | Char, Text, Html |
| `integer` | `int?` | Integer |
| `double_` | `double?` | Float, Monetary |
| `boolean` | `bool?` | Boolean |
| `date` | `String?` | Date (ISO) |
| `datetime` | `String?` | Datetime (ISO) |
| `selection` | `String?` / `enum?` | Selection |
| `many2one` | `int?` | Many2one (ID) |
| `one2many` | `List<int>?` | One2many (IDs) |
| `many2many` | `List<int>?` | Many2many (IDs) |
| `binary` | `String?` | Binary (base64) |
| `dynamic_` | `dynamic` | Campos de tipo variable |

---

## 🔄 3. Conversión Automática camelCase → snake_case

A partir de la versión `2.2.0`, si no especificas `name:` en `@OdooField`, el generador convierte automáticamente el nombre Dart al formato snake_case de Odoo:

```dart
// Antes de v2.2 — name obligatorio
@OdooField(type: OdooFieldType.many2one, name: 'partner_id')
final int? partnerId;

// Desde v2.2 — conversión automática ✅
@OdooField(type: OdooFieldType.many2one)
final int? partnerId;  // → partner_id

@OdooField(type: OdooFieldType.boolean)
final bool? isCompany; // → is_company

@OdooField(type: OdooFieldType.string)
final String? jobTitle; // → job_title
```

**Regla de conversión:** cada letra mayúscula se convierte en `_letra_minúscula`.

`amountTotal` → `amount_total` | `writeDate` → `write_date` | `userId` → `user_id`

---

## 🏭 4. Generar el Código

```bash
# Desde la raíz del proyecto que consume el generador:
dart run build_runner build --delete-conflicting-outputs

# En modo watch (regenera al guardar):
dart run build_runner watch --delete-conflicting-outputs
```

El generador produce un archivo `*.odoo.g.dart` por cada clase anotada, que contiene:

- **`_$PartnerFromJson`** — factory `fromJson` con parsing de many2one y tipos complejos
- **`_$PartnerToJson`** — serialización a mapa para `create` / `write`
- **`_$PartnerMeta`** — metadata del modelo (modelName, fields)
- **`_$PartnerSpecification`** — mapa para `web_search_read` specification
- **`PartnerFields`** — enum de todos los campos para selección tipada
- **`_$Partner`** — mixin con `copyWith`, `toJson`, `toOdoo` y `toString`
- **`PartnerRepository`** — repositorio concreto ya listo para usar

---

## 📋 5. Usar el Repositorio Generado

```dart
final partnerRepo = PartnerRepository(client: odooClient);

// Buscar con filtros
final result = await partnerRepo.searchFetch(
  domain: [['is_company', '=', true]],
  limit: 20,
  order: 'name asc',
);

// El builder estático pertenece al repositorio generado:
final productLineRepo = ProductLineRepository(client: odooClient);
final lineSpec = ProductLineRepository.buildSpecification(
  only: [ProductLineFields.id, ProductLineFields.name],
).build();
final lines = await productLineRepo.searchFetch(specification: lineSpec);

// Contar sin traer datos
final total = await partnerRepo.searchCount(
  domain: [['is_company', '=', true]],
);

// CRUD completo
final id = await partnerRepo.create({'name': 'ACME', 'is_company': true});
await partnerRepo.write([id], {'phone': '555-0000'});
final saved = await partnerRepo.webSave(ids: [id], values: {'name': 'ACME S.A.'});
await partnerRepo.unlink([id]);

// Llamar métodos de negocio
await saleOrderRepo.callMethod(
  method: 'action_confirm',
  ids: [orderId],
);
```

`buildSpecification()` se invoca en el repositorio (`ProductLineRepository`), no
en el modelo (`ProductLine`): Dart no hereda miembros estáticos de mixins.

### Prueba de integración RunBot

La prueba contra `https://130072570-19-0-all.runbot157.odoo.com` está desactivada
por defecto. Para ejecutarla desde PowerShell, configura credenciales válidas para
la base `130072570-19-0-all` y activa la bandera:

```powershell
$env:ODOO_RUNBOT_TEST = 'true'
$env:ODOO_RUNBOT_USER = 'admin'
$env:ODOO_RUNBOT_PASS = '<password>'
dart test test/odoo_generator_runbot_test.dart
```

El servidor debe tener disponible el modelo `product.line`.

---

## 📊 6. Selección Dinámica de Campos (Specification)

El enum `PartnerFields` generado y la clase `SpecificationBuilder` permiten seleccionar campos e incrustar relaciones de forma totalmente tipada y fluida, eliminando strings sueltos.

### 🔹 Uso 1: Estilo Builder Fluido (`.addField()`, `.addOnly()`, `.addNested()`, `.build()`)

```dart
// ✅ Construcción encadenada paso a paso
final lightSpec = PartnerRepository.buildSpecification()
    .addField(PartnerFields.id)
    .addField(PartnerFields.name)
    .addOnly([PartnerFields.email, PartnerFields.phone])
    .build();

final result = await partnerRepo.searchFetch(specification: lightSpec);
```

### 🔹 Uso 2: Parámetros posicionales directos con `.build()`

```dart
// ✅ Estilo directo compacto con .build() al final
final lightSpec = PartnerRepository.buildSpecification(
  only: [
    PartnerFields.id,
    PartnerFields.name,
    PartnerFields.email,
    PartnerFields.phone,
  ],
).build();

final result = await partnerRepo.searchFetch(specification: lightSpec);
```

### 🔹 Uso 3: Especificación anidada (Relaciones many2one / one2many)

```dart
// ✅ Traer campos específicos de líneas de pedido dentro de una venta
final nestedSpec = SaleOrderRepository.buildSpecification()
    .addOnly([
      SaleOrderFields.name,
      SaleOrderFields.amountTotal,
      SaleOrderFields.state,
      SaleOrderFields.orderLineIds,
    ])
    .addNested(
      SaleOrderFields.orderLineIds,
      OrderLineRepository.buildSpecification()
          .addOnly([
            OrderLineFields.id,
            OrderLineFields.productId,
            OrderLineFields.priceUnit,
            OrderLineFields.productUomQty,
          ])
          .build(),
    )
    .build();

final orders = await saleOrderRepo.searchFetch(specification: nestedSpec);
for (final order in orders.records) {
  print('Orden: ${order.name} — Total: ${order.amountTotal}');
}
```

`searchFetch()` utiliza automáticamente la especificación completa del modelo. Para
consultas personalizadas, usa `PartnerRepository.buildSpecification(...)` y pasa
el resultado a `searchFetch(specification: ...)`.

---

## 🧩 7. Modelo Complejo con Varios Tipos

```dart
part 'sale_order.odoo.g.dart';

@OdooModel(modelName: 'sale.order')
class SaleOrder extends OdooBaseModel with _$SaleOrder {

  // Selection → usa el string de Odoo directamente
  @OdooField(type: OdooFieldType.selection)
  final String? state; // 'draft', 'sale', 'done', 'cancel'

  // Float/Monetary
  @OdooField(type: OdooFieldType.double_)
  final double? amountTotal;

  // Many2one — nombre explícito (no sigue la convención)
  @OdooField(type: OdooFieldType.many2one, name: 'partner_id')
  final int? customerId;

  // One2many — orderLineIds → order_line_ids automático
  @OdooField(type: OdooFieldType.one2many)
  final List<int>? orderLineIds;

  // Date
  @OdooField(type: OdooFieldType.date)
  final String? dateOrder;

  SaleOrder({
    required super.id,
    required super.name,
    super.writeDate,
    this.state,
    this.amountTotal,
    this.customerId,
    this.orderLineIds,
    this.dateOrder,
  });

  factory SaleOrder.fromJson(Map<String, dynamic> json) =>
      _$SaleOrderFromJson(json);
}
```

---

## 🧪 8. Testing de Repositorios Generados

El patrón `OdooClient` permite mockear sin red real:

```dart
class MockOdooClient implements OdooClient {
  final dynamic mockResponse;
  MockOdooClient({this.mockResponse});

  @override
  Future<dynamic> callKwRaw({
    required String model,
    required String method,
    List args = const [],
    Map<String, dynamic> kwargs = const {},
  }) async => mockResponse;
}

void main() {
  test('PartnerRepository.searchCount retorna entero', () async {
    final repo = PartnerRepository(
      client: MockOdooClient(mockResponse: 42),
    );
    expect(await repo.searchCount(), equals(42));
  });

  test('PartnerRepository.create retorna ID', () async {
    final repo = PartnerRepository(
      client: MockOdooClient(mockResponse: 99),
    );
    expect(await repo.create({'name': 'Test'}), equals(99));
  });

  test('callMethod retorna respuesta del servidor', () async {
    final repo = PartnerRepository(
      client: MockOdooClient(mockResponse: true),
    );
    final ok = await repo.callMethod(
      method: 'action_confirm',
      ids: [1],
    );
    expect(ok, isTrue);
  });
}
```

---

## 🔧 9. Comandos Útiles

```bash
# Generar código una vez
dart run build_runner build --delete-conflicting-outputs

# Modo watch — regenera al guardar
dart run build_runner watch --delete-conflicting-outputs

# Ejecutar tests
dart test --reporter=expanded

# Analizar código
dart analyze
```

---

## 📁 Estructura

```
odoo_generator/
├── lib/
│   ├── odoo_generator.dart          # Barrel de exports
│   └── src/
│       ├── odoo_generator_base.dart # Builder principal
│       └── odoo_annotation_reader.dart
└── build.yaml                       # Configuración del builder
```

## 🔖 Versiones

| Versión | Cambios |
|---|---|
| **2.2.0** | Conversión automática camelCase → snake_case en todos los campos sin `name:` |
| 2.1.2 | Soporte para `specification` anidado y enums de campos |
| 2.1.1 | Corrección de casteo de tipos dinámicos |
| 2.0.1 | Filtrado estricto de `@OdooField` y análisis robusto del constructor |
