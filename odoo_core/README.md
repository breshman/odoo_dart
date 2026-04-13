# Odoo Core & Architecture

Este es el núcleo maestro de arquitectura (`odoo_core`) para interactuar rápida y tipadamente con Odoo en Dart/Flutter. Está construido bajo principios **SOLID** y **Clean Architecture**, asegurando que puedes utilizarlo sin importar qué gestor de estado (Riverpod, Bloc, GetX, Provider) o framework elijas. ¡Funciona en Dart puro!

## 🚀 Características Principales

1. **Agnóstico al UI/State**: No depende de Flutter ni de ningún gestor de estados específico.
2. **Sistema de Anotaciones Integrado**: Define modelos de Odoo usando `@OdooModel` y tipos de relaciones (`OdooFieldType`). Elimina la necesidad del empaquetado separado `odoo_annotation`.
3. **`OdooBaseModel`**: Una clase maestra que provee todos los campos universales de Odoo (`id`, `name`, `create_date`, `write_date`, `create_uid`, `write_uid`) e incluye el parseo manual por defecto.
4. **`OdooRepository<T>`**: Repositorios genéricos integrados que te dan acceso estructurado a los métodos ORM base de Odoo: `searchIds`, `searchFetch`, `read`, `create`, `write`, `unlink` y `webSave`.
5. **Tipado Estricto de Parámetros**: Todas las llamadas están fuertemente tipadas en la red con objetos encapsulados (`OdooWriteParams`, `OdooSearchParams`, etc.).
6. **Selección Dinámica (Specification)**: Permite elegir exactamente qué campos pedir a Odoo (incluyendo relaciones anidadas) usando Enums generados automáticamente para evitar errores de escritura.
7. **Soporte TR in-box (Realtime Socket)**: Incluye un cliente interno (`OdooRealtimeClient`) para WebSockets directo con el canal de tu usuario.


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
dart run build_runner build --delete-conflicting-outputs

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

## 📊 4. Caso de Uso: Selección Dinámica de Datos (Specification)

En Odoo 18+, las consultas de lectura utilizan una **especificación** para determinar qué campos devolver. Por defecto el generador incluye todo lo decorado, pero puedes optimizarlo dinámicamente.

### A. Selección Tipada con Enums
Para evitar errores de escritura, el generador crea un Enum `${ClassName}Fields` que puedes usar con el helper `buildSpecification`.

```dart
final repo = OrderRepository(client: odooClient);

// Creamos una especificación que solo pida ID y Total
final partialSpec = _$OrderMeta.buildSpecification(
  only: [
    OrderFields.id,
    OrderFields.total,
  ],
);

final result = await repo.searchFetch(specification: partialSpec);
```

### B. Consultas Anidadas (Relaciones)
Puedes pedir campos específicos de modelos relacionados de forma muy sencilla combinando los helpers de ambas clases:

```dart
final nestedSpec = _$OrderMeta.buildSpecification(
  only: [OrderFields.name, OrderFields.orderDate],
  nested: {
    // Pedimos campos específicos del modelo de Líneas de Orden
    OrderFields.lineIds: _$OrderLineMeta.buildSpecification(
      only: [OrderLineFields.id, OrderLineFields.productName, OrderLineFields.priceUnit],
    ),
  },
);

final result = await repo.searchFetch(specification: nestedSpec);
```

---

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

Al estar en un ecosistema que usa el nuevo módulo realtime, `odoo_core` te exporta una utilidad directa (`OdooRealtimeClient`) para escuchar canales de Odoo sin dependencias extrañas y transmitir los eventos a tu UI limpiamente mediante un **Stream** de Dart:

### Ejemplo Básico: Autenticación y Conexión
Debes inicializar el socket extrayendo primero la versión estricta del Worker que solicita Odoo en la respuesta de Login (`websocket_worker_version`) y tu cookie de sesión.

```dart
import 'package:odoo_core/odoo_core.dart';
import 'package:odoo_core/src/network/client/odoo_realtime_client.dart';

// Supongamos que acabas de invocar el Auth de Odoo
final workerVersion = authResponse['websocket_worker_version']?.toString() ?? '18.0-7';
final sessionCookie = 'session_id=123f...'; // Recogida del interceptor de Headers

final wsClient = OdooRealtimeClient(
  baseUrl: 'https://mi-odoo-produccion.com',
  sessionId: sessionCookie,
  websocketWorkerVersion: workerVersion // Fundamental para pasar el Handshake HTTP 400
);

// Nos conectamos y le instruimos a Odoo a qué canales nos queremos suscribir al instante.
// Ej. El canal 1 suele referirse al canal "General" del módulo de Chat. 
wsClient.connect(channels: ['discuss.channel_1']);
```

### Ejemplo Avanzado: Escuchar el Stream en vivo (Bloc, Provider, UI)
Debido a que `OdooRealtimeClient` exporta internamente su receptor como un `Stream.broadcast()` en la variable `.messages`, múltiples bloques de tu app pueden "oír" los milisegundos cuando llega algo.

```dart
// Abres un vigilante continuo
wsClient.messages.listen((event) {
  final message = event['message'];
  if (message == null) return;

  // Odoo arroja muchos eventos (type). Filtraremos si alguien envió un nuevo Mensaje.
  if (message['type'] == 'mail.message/new') {
     final payload = message['payload'];
     final nameAuthor = payload['author_id']?[1] ?? 'Desconocido';
     final htmlBody = payload['body'] ?? '';
     
     print('🔥 ¡Nuevo Chat Entrante! $nameAuthor acaba de escribir un mensaje.');
     
     // Aquí inyectarías a tu gestor favorito tu nuevo Widget o Estado.
     // Ejemplo:
     // ref.read(chatProvider.notifier).addNewBubble(htmlBody); 
  } 
  // O captura otros eventos custom...
  else if (message['type'] == 'website.visitor/new') {
     print('🔔 Alguien entró a tu página web.');
  } else {
     print('ℹ️ Evento desconocido del bus Odoo: ${message['type']}');
  }
});
```

### Tips de Uso
Si el usuario de tu app se desloguea, siempre asegúrate de apagar el canal en memoria:
```dart
wsClient.disconnect();
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
