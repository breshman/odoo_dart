# Odoo Core & Architecture

Este es el núcleo maestro de arquitectura (`odoo_core`) para interactuar rápida y tipadamente con Odoo en Dart/Flutter. Está construido bajo principios **SOLID** y **Clean Architecture**, asegurando que puedes utilizarlo sin importar qué gestor de estado (Riverpod, Bloc, GetX, Provider) o framework elijas. ¡Funciona en Dart puro!

## 🚀 Características Principales

1. **Agnóstico al UI/State**: No depende de Flutter ni de ningún gestor de estados específico.
2. **Sistema de Anotaciones Integrado**: Define modelos de Odoo usando `@OdooModel` y tipos de relaciones (`OdooFieldType`). Elimina la necesidad del empaquetado separado `odoo_annotation`.
3. **`OdooBaseModel`**: Una clase maestra que provee todos los campos universales de Odoo (`id`, `name`, `active`, `create_date`, `write_date`, `create_uid`, `write_uid`) e incluye el parseo manual por defecto.
4. **`OdooRepository<T>`**: Repositorios genéricos integrados que te dan acceso estructurado a los métodos ORM base de Odoo: `searchIds`, `searchFetch`, `read`, `create`, `write`, `unlink` y `webSave`.
5. **Tipado Estricto de Parámetros**: Todas las llamadas están fuertemente tipadas en la red con objetos encapsulados (`OdooWriteParams`, `OdooSearchParams`, etc.).
6. **Soporte TR in-box (Realtime Socket)**: Incluye un cliente interno (`OdooRealtimeClient`) para WebSockets directo con el canal de tu usuario.


---

## 🛠️ 1. Configuración y Cliente Base

Toda comunicación necesita un `OdooClient`. Por defecto usamos el `OdooRpcService` que viene optimizado dentro de la red (carpeta network):

```dart
import 'package:odoo_core/odoo_core.dart';

void main() async {
  // Inicializamos nuestra conexión master Odoo (En Flutter típicamente en un Provider o Singleton)
  final odooClient = OdooRpcService();
  
  // Opcional: Proveerle un contexto específico de región/usuario (muy útil p/ Odoo)
  odooClient.setContext(const UserContext(lang: 'es_PE', tz: 'America/Lima', uid: 1));
}
```

---

## 🏗️ 2. Caso de Uso: Declaración de tus Modelos

Tus modelos ya no son simples JSONs. Al extender `OdooBaseModel` y decorarlos, nuestro generador (`odoo_generator`) hará el trabajo de crear parseadores, genéricos, listas, specification y los repositorios enteros automáticamente.

```dart
import 'package:odoo_core/odoo_core.dart'; // Contiene las anotaciones

// part 'order.odoo.g.dart'; 

@OdooModel(modelName: 'sale.order')
class Order extends OdooBaseModel {
  @OdooField(type: OdooFieldType.date, name: 'order_date')
  final DateTime? orderDate;

  @OdooField(type: OdooFieldType.double_, name: 'total')
  final double? total;

  @OdooField(type: OdooFieldType.selection, name: 'status')
  final String? status; // draft, confirmed, shipped, delivered

  // ¡Define relaciones one2many y many2many con tipado genérico de id int!
  @OdooField(type: OdooFieldType.one2many, name: 'line_ids')
  final List<int>? lineIds;

  // IMPORTANTÍSIMO: Invoca el super constructor para que OdooBaseModel exponga sus campos
  Order({
    required super.id,
    required super.name,
    super.displayName,
    super.active = true,
    super.createDate,
    super.writeDate,
    super.createUid,
    super.writeUid,
    this.orderDate,
    this.total,
    this.status,
    this.lineIds,
  });

  // factorías que se rellenan solas gracias tu odoo_generator
  // factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  // Map<String, dynamic> toJson() => _$OrderToJson(this);
}
```

---

## 🔍 3. Caso de Uso: Consultas, Filtrados y Lecturas Múltiples

Tras haber generado tu modelo, el compilador construirá para ti un `{Modelo}Repository`.

```dart
// 1. Instanciamos el repositorio inyectándole nuestro OdooClient configurado
final orderRepo = OrderRepository(client: odooClient);

// === BUSQUEDA DE MÚLTIPLES REGISTROS (equivalente a web_search_read) ===
final records = await orderRepo.searchFetch(
  domain: [
    ['status', '=', 'confirmed'],
    ['total', '>', 500]
  ],
  limit: 20,       // Paginación
  offset: 0,
  order: 'order_date desc'
);

print("Se encontraron ${records.length} elementos en total en base de datos.");
for(var order in records.records) {
  print('Orden: ${order.name} - Fecha: ${order.orderDate} - Total: ${order.total}');
}

// === LECTURA POR IDS (equivalente a web_read) ===
// ¿Solo tienes los IDs de tu ORM? Obten la data llena (con el spec autogenerado)
final specificallyRequestedOrders = await orderRepo.read([14, 15]);

// === SÓLO OBTENER IDS (Búsqueda liviana - usa solo 'search') ===
final orderIds = await orderRepo.searchIds(
  domain: [['status', '=', 'draft']]
);
print("Hay ${orderIds.length} órdenes en borrador, pero sólo traje sus IDs.");
```

---

## ✍🏻 4. Caso de Uso: Lógica CRUD Directa (Crear, Actualizar, Eliminar)

Usa la simplicidad del mapeo JSON en operaciones atómicas:

```dart
// === CREAR REGISTRO ===
// Los repositorios usan mapas nativos o la función toJson de tu modelo
final newOrderId = await orderRepo.create({
  'total': 1500.0,
  'status': 'draft',
});
print("Orden creada con ID oficial Odoo: $newOrderId");

// === ACTUALIZAR REGISTROS MASIVOS (write puro) ===
final bool success = await orderRepo.write(
  [newOrderId], 
  {'status': 'confirmed'}
);

// === WEBSAVE ESTRICTAMENTE TIPADO ===
// Guarda un registro Y trae la data actualizada de vuelta al mismo tiempo. Súper útil.
final updatedOrders = await orderRepo.webSave(
  OdooWriteParams(
     model: OrderRepository.modelName,
     ids: [newOrderId],
     values: {'status': 'shipped'},
     fromJsonT: Order.fromJson,
     toJson: (v) => v // Helper temporal para convertir en diccionarios
  )
);
print("Nuevo estado traido de Odoo al guardar: ${updatedOrders.first.status}");

// === BORRAR REGISTROS (unlink) ===
final isDeleted = await orderRepo.unlink([newOrderId]);
```

---

## 📡 5. Caso de Uso: Conexión Realtime (Sockets)

Al estar en un ecosistema que usa el nuevo módulo realtime, `odoo_core` te exporta una utilidad directa (`OdooRealtimeClient`) para escuchar canales de Odoo sin dependencias extrañas:

```dart
final realtimeClient = OdooRealtimeClient(
  baseUrl: 'https://mi-odoo-produccion.com',
  sessionId: 'session_id=123f...',
);

realtimeClient.connect(); 
// Se conecta usando WebSockets a Odoo 18, setea las cookies,
// e intercepta el _bus_send automáticamente.
```

---

## 🧩 6. Llamadas a RPC Crudas y Personalizadas

¿Necesitas enviar contraseñas o llamar a endpoints a medida que tu python developer expuso?

```dart
// Acceso a OdooClient genérico
final miResultado = await odooClient.callRpc(
  path: '/web/session/authenticate',
  params: {
    'db': 'odoo_db',
    'login': 'admin',
    'password': '123'
  },
  fromJsonT: MiClaseAuth.fromJson,
);

// Petición Directa (Call Keyword) evadiendo tu Repositorio 
final resultList = await odooClient.callKwRaw(
  model: 'res.partner',
  method: 'name_search',
  args: [],
  kwargs: {'name': 'Mitchell', 'operator': 'ilike'}
);
```

---

## 🎯 Buenas Prácticas al Usar esta Arquitectura
1. **Separación de Responsabilidades**: Evita llamar `odooClient.callKwRaw` desde tu capa de Interface Visual o Controller de UI. Todo intento de comunicación ORM debería pasar por tu Objeto Repositorio correspondiente y encapsulado.
2. **Usa dependencias simuladas (Mocks)**: Gracias a que `OrderRepository` puede recibir `client: OdooClient`, en tus test en Flutter puedes inyectarle una clase falsa tipo `class MockOdooClient implements OdooClient` ¡y probar tus lógicas sin peticione de red reales!
3. **Control Centralizado de `OdooFieldType`**: Ya no envuelvas las fechas pasándolas por la mano. Usa el enumerado provisto al decorar, así el generador gestiona y estandariza los cast a `DateTime`, `num`, booleanos perdidos que retornen `false` de Odoo, y relaciones `id,name`!
