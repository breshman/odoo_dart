# odoo_core

[![pub.dev](https://img.shields.io/badge/pub.dev-odoo__core-blue)](https://pub.dev)
[![Dart 3](https://img.shields.io/badge/Dart-3.x-0175C2)](https://dart.dev)

El núcleo maestro de arquitectura para interactuar con Odoo desde Dart/Flutter. Construido sobre principios **SOLID** y **Clean Architecture** — funciona en Dart puro, sin atarse a Flutter, Riverpod, Bloc ni ningún otro framework.

---

## 🚀 Características Principales

| Característica | Descripción |
|---|---|
| **`OdooSession`** | Sesión tipada e inmutable con `websocketWorkerVersion`, `serverVersionInt`, persistencia JSON y soporte Odoo 12–18+ |
| **`OdooCookie`** | Parser RFC 6265 cross-platform (web + native) para cookies HTTP — sin dependencias de `dart:io` |
| **`OdooException` semántica** | Subclases `OdooSessionExpiredException`, factories `accessDenied` / `notFound` / `serverError`, getter `isAuthError` |
| **`OdooRpcService`** | Autenticación tipada, gestión de sesión, `inRequestStream` para loading global, `connectRealtime()` integrado |
| **`OdooRealtimeClient`** | WebSocket nativo con `fromSession()` — conéctate en una línea después de autenticar |
| **`OdooRepository<T>`** | CRUD completo + `searchCount()` + `callMethod()` sin romper encapsulación |
| **Anotaciones + Generador** | `@OdooModel` / `@OdooField` con conversión automática camelCase → snake_case |
| **Selección dinámica** | Enums tipados + `buildSpecification(only:, nested:)` para controlar exactamente qué campos trae Odoo |
| **Agnóstico al UI** | Compatible con cualquier gestor de estado (Riverpod, Bloc, GetX, Provider) |

---

## 📦 Instalación

```yaml
# pubspec.yaml
dependencies:
  odoo_core:
    path: ../odoo_core   # o via pub.dev cuando esté publicado
  dio: ^5.7.0
```

---

## 🛠️ 1. Inicialización del Cliente

```dart
import 'package:odoo_core/odoo_core.dart';
import 'package:dio/dio.dart';

void main() async {
  final dio = Dio(BaseOptions(baseUrl: 'https://mi-odoo.com'));

  // Interceptor de sesión usando OdooCookie (RFC 6265, cross-platform)
  String? sessionCookie;
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      if (sessionCookie != null) options.headers['Cookie'] = sessionCookie!;
      handler.next(options);
    },
    onResponse: (response, handler) {
      final rawCookies = response.headers['set-cookie'] ?? [];
      final sessionId = OdooCookie.extractSessionId(rawCookies);
      if (sessionId != null) {
        sessionCookie = OdooCookie('session_id', sessionId).toString();
      }
      handler.next(response);
    },
  ));

  final odoo = OdooRpcService(dio: dio);
}
```

---

## 🍪 2. OdooCookie — Parser RFC 6265

`OdooCookie` es un parser completo del header `Set-Cookie` que funciona tanto en **Flutter/Dart nativo** como en **Flutter Web**, sin necesidad de importar `dart:io`.

### ¿Por qué no usar `dart:io Cookie`?

`dart:io` no está disponible en Flutter Web. `OdooCookie` implementa el mismo parseado siguiendo la especificación [RFC 6265](https://www.rfc-editor.org/rfc/rfc6265) y es seguro en todas las plataformas.

### Casos de uso

#### Extraer `session_id` automáticamente de una respuesta Dio

```dart
// En un interceptor Dio onResponse:
final rawCookies = response.headers['set-cookie'] ?? [];
final sessionId = OdooCookie.extractSessionId(rawCookies);

if (sessionId != null) {
  print('session_id: $sessionId'); // "abc123xyz..."
  // Guardar la cookie formateada para enviarla en las siguientes peticiones
  final cookieHeader = OdooCookie('session_id', sessionId).toString();
  // cookieHeader == "session_id=abc123xyz; HttpOnly"
}
```

#### Parsear un header `Set-Cookie` completo

```dart
final raw = 'session_id=abc123xyz; Path=/; HttpOnly; SameSite=Lax';
final cookie = OdooCookie.fromSetCookieValue(raw);

print(cookie.name);     // session_id
print(cookie.value);    // abc123xyz
print(cookie.path);     // /
print(cookie.httpOnly); // true
print(cookie.secure);   // false
```

#### Crear una cookie para enviarla en la cabecera `Cookie`

```dart
final cookie = OdooCookie('session_id', 'abc123xyz');
print(cookie.toString()); // "session_id=abc123xyz; HttpOnly"

// Úsalo en el header de la petición:
dio.options.headers['Cookie'] = cookie.toString();
```

#### Parsear múltiples `Set-Cookie` headers

```dart
final headers = [
  'session_id=abc123; Path=/; HttpOnly',
  'lang=es_MX; Path=/; Max-Age=31536000',
  'cids=1; Path=/; SameSite=Lax',
];

// Extraer solo el session_id:
final sessionId = OdooCookie.extractSessionId(headers);
print(sessionId); // "abc123"

// O parsear todas:
for (final raw in headers) {
  final c = OdooCookie.fromSetCookieValue(raw);
  print('${c.name} = ${c.value}');
}
// session_id = abc123
// lang = es_MX
// cids = 1
```

#### Uso junto a `OdooRealtimeClient`

```dart
// fromSession() usa OdooCookie internamente para formatear
// correctamente la cookie de sesión:
final ws = OdooRealtimeClient.fromSession(
  session: odooClient.currentSession!,
  baseUrl: 'https://mi-odoo.com',
);
// Equivalente a:
// sessionId = OdooCookie('session_id', session.id).toString()
//           = "session_id=<valor>; HttpOnly"
```

#### Manejo de cookies malformadas

`OdooCookie.extractSessionId` es tolerante a cookies con formato incorrecto — si una cookie falla el parse, continúa con la siguiente sin lanzar excepción:

```dart
final messy = [
  'malformed_cookie_no_equals_sign',  // ← se ignora
  'other=value; Path=/',              // ← se ignora (no es session_id)
  'session_id=abc123; HttpOnly',      // ← retorna "abc123"
];
final id = OdooCookie.extractSessionId(messy);
print(id); // "abc123"
```

### API completa

| Miembro | Tipo | Descripción |
|---|---|---|
| `OdooCookie(name, value)` | Constructor | Crea una cookie con nombre y valor |
| `OdooCookie.fromSetCookieValue(raw)` | Factory | Parsea un header `Set-Cookie` completo (RFC 6265) |
| `OdooCookie.extractSessionId(rawCookies)` | `static String?` | Extrae el valor de `session_id` de una lista de headers |
| `.name` | `String` | Nombre de la cookie |
| `.value` | `String` | Valor de la cookie |
| `.path` | `String?` | Atributo `Path` |
| `.domain` | `String?` | Atributo `Domain` |
| `.expires` | `String?` | Atributo `Expires` |
| `.maxAge` | `int?` | Atributo `Max-Age` en segundos |
| `.httpOnly` | `bool` | `true` si tiene el flag `HttpOnly` |
| `.secure` | `bool` | `true` si tiene el flag `Secure` |
| `.toString()` | `String` | Serializa la cookie lista para el header `Cookie` |

---

## 🔐 3. Autenticación con `OdooSession`

### Autenticación básica

```dart
try {
  final OdooSession session = await odoo.authenticate(
    'mi-base-de-datos',
    'admin',
    'admin',
  );

  print('Bienvenido: ${session.userName}');
  print('Empresa activa: ${session.companyId}');
  print('Versión Odoo: ${session.serverVersionInt}');          // 18
  print('WS Worker version: ${session.websocketWorkerVersion}'); // "18.0-7"
  print('Autenticado: ${session.isAuthenticated}');            // true

} on OdooSessionExpiredException {
  print('Login fallido: credenciales inválidas.');
} on OdooException catch (e) {
  print('Error ${e.code}: ${e.message}');
}
```

> **Nota:** `authenticate()` extrae automáticamente el `session_id` del header `Set-Cookie` usando `OdooCookie` cuando el servidor no lo incluye en el body JSON (comportamiento común en RunBot).

### Persistir y restaurar sesión

```dart
// Guardar en SharedPreferences, Hive, etc.
final json = session.toJson();
prefs.setString('session', jsonEncode(json));

// Restaurar al arrancar la app
final raw = jsonDecode(prefs.getString('session') ?? '{}');
final restoredSession = OdooSession.fromJson(raw as Map<String, dynamic>);

if (restoredSession.isAuthenticated) {
  // ... continuar sin re-autenticar
}
```

### Verificar sesión activa al arrancar

```dart
try {
  await odoo.checkSession();
  // La sesión sigue válida → ir al home
} on OdooSessionExpiredException {
  // Sesión expirada → ir al login
}
```

### Cerrar sesión

```dart
await odoo.destroySession();
OdooRpcService.reset();

// Reconectar con otro servidor
odoo.setBaseUrl('https://otro-servidor.odoo.com');
```

---

## ⏳ 4. Indicador de Carga Global (`inRequestStream`)

```dart
// En Riverpod
odoo.inRequestStream.listen((isLoading) {
  ref.read(loadingProvider.notifier).state = isLoading;
});

// En StatefulWidget
odoo.inRequestStream.listen((loading) {
  setState(() => _isLoading = loading);
});
```

---

## 🏗️ 5. Definición de Modelos con Anotaciones

```dart
@OdooModel(modelName: 'res.partner')
class Partner extends OdooBaseModel with _$Partner {

  @OdooField(type: OdooFieldType.string)
  final String? email;

  // camelCase → snake_case automático: isCompany → is_company
  @OdooField(type: OdooFieldType.boolean)
  final bool? isCompany;

  // many2one: categoryId → category_id automático
  @OdooField(type: OdooFieldType.many2one)
  final int? categoryId;

  Partner({
    required super.id,
    required super.name,
    this.email,
    this.isCompany,
    this.categoryId,
  });

  factory Partner.fromJson(Map<String, dynamic> json) => _$PartnerFromJson(json);
}
```

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 🔍 6. Consultas y CRUD

```dart
final partnerRepo = PartnerRepository(client: odoo);

// searchFetch — web_search_read con paginación
final result = await partnerRepo.searchFetch(
  domain: [['is_company', '=', true]],
  limit: 20,
  order: 'name asc',
);

// searchCount — total sin traer datos
final total = await partnerRepo.searchCount(
  domain: [['is_company', '=', true]],
);

// searchIds — solo IDs
final ids = await partnerRepo.searchIds(domain: [['active', '=', true]]);

// read
final partners = await partnerRepo.read([1, 2, 3]);

// create
final newId = await partnerRepo.create({'name': 'Acme', 'is_company': true});

// write
await partnerRepo.write([newId], {'phone': '555-9999'});

// webSave — guarda y devuelve el registro actualizado
final saved = await partnerRepo.webSave(
  ids: [newId],
  values: {'name': 'Acme S.A.'},
);

// unlink
await partnerRepo.unlink([newId]);
```

---

## ⚙️ 7. Llamar Métodos de Negocio (`callMethod`)

```dart
// Confirmar una orden de venta
await saleOrderRepo.callMethod(
  method: 'action_confirm',
  ids: [orderId],
);

// Método con contexto adicional
await invoiceRepo.callMethod(
  method: 'action_post',
  ids: [invoiceId],
  context: {'move_type': 'out_invoice'},
);

// Método de clase (sin IDs) — retorna un wizard action
final wizard = await partnerRepo.callMethod(
  method: 'name_search',
  kwargs: {'name': 'Mitchell', 'limit': 5},
);
```

---

## 📊 8. Selección Dinámica de Campos (Specification)

```dart
// El generador crea PartnerFields enum automáticamente
final lightSpec = Partner.buildSpecification(
  only: [PartnerFields.id, PartnerFields.name, PartnerFields.email],
);

// Con relaciones anidadas
final nestedSpec = SaleOrder.buildSpecification(
  only: [SaleOrderFields.name, SaleOrderFields.amountTotal],
  nested: {
    SaleOrderFields.orderLineIds: OrderLine.buildSpecification(
      only: [OrderLineFields.productId, OrderLineFields.priceUnit],
    ),
  },
);

final orders = await saleOrderRepo.searchFetch(specification: nestedSpec);
```

---

## 📡 9. Realtime con WebSockets

```dart
// Un solo método configura todo desde la sesión activa
final session = await odoo.authenticate('mydb', 'admin', 'admin');
final ws = odoo.connectRealtime();

ws.connect(channels: ['discuss.channel_1', 'res.partner_10']);

ws.messages.listen((event) {
  switch (event['message']?['type']) {
    case 'mail.message/new':
      final body = event['message']['payload']['body'];
      print('Nuevo mensaje: $body');
    case 'discuss.channel/new_message':
      print('Mensaje en canal');
  }
});

// Suscribirse a canales adicionales en caliente
ws.subscribe(['discuss.channel_2']);

// Enviar un mensaje al canal vía RPC (el WS es solo lectura)
await odoo.callKwRaw(
  model: 'discuss.channel',
  method: 'message_post',
  args: [channelId],
  kwargs: {
    'body': 'Hello World! Testing with Flutter 🐦',
    'message_type': 'comment',
    'subtype_xmlid': 'mail.mt_comment',
  },
);

// La respuesta llegará al stream ws.messages como un evento
ws.disconnect();
await odoo.destroySession();
OdooRpcService.reset();
```

### Conexión manual (sin `OdooRpcService`)

```dart
final session = OdooSession.fromJson(storedJson);

// fromSession() usa OdooCookie internamente para formatear la cookie
final ws = OdooRealtimeClient.fromSession(
  session: session,
  baseUrl: 'https://mi-odoo.com',
);
ws.connect(channels: ['discuss.channel_1']);
```

---

## 🚨 10. Manejo de Excepciones

```dart
try {
  await partnerRepo.searchFetch();
} on OdooSessionExpiredException {
  Navigator.pushReplacementNamed(context, '/login');
} on OdooException catch (e) {
  if (e.isAuthError) {
    print('Error de auth (${e.code}): ${e.message}');
  } else {
    print('Error Odoo ${e.code}: ${e.message}');
  }
}

// Factories semánticos
throw OdooException.accessDenied('No tienes permiso');
throw OdooException.notFound('Empleado no encontrado');
throw OdooException.serverError('Fallo al procesar nómina');
```

---

## 🧪 11. Testing con Mocks

```dart
class MockOdooClient implements OdooClient {
  final dynamic mockResponse;
  final Exception? error;

  MockOdooClient({this.mockResponse, this.error});

  @override
  Future<dynamic> callKwRaw({
    required String model,
    required String method,
    List args = const [],
    Map<String, dynamic> kwargs = const {},
  }) async {
    if (error != null) throw error!;
    return mockResponse;
  }
}

// Tests unitarios sin red real
test('searchCount retorna entero', () async {
  final repo = PartnerRepository(client: MockOdooClient(mockResponse: 42));
  expect(await repo.searchCount(), equals(42));
});

// Test de OdooCookie
test('OdooCookie parsea Set-Cookie correctamente', () {
  final c = OdooCookie.fromSetCookieValue(
    'session_id=abc123; Path=/; HttpOnly; SameSite=Lax',
  );
  expect(c.name, 'session_id');
  expect(c.value, 'abc123');
  expect(c.httpOnly, isTrue);
  expect(c.path, '/');
});

test('extractSessionId retorna null si no hay session_id', () {
  final id = OdooCookie.extractSessionId(['lang=es_MX; Path=/']);
  expect(id, isNull);
});
```

---

## 🎯 Buenas Prácticas

1. **Usa `OdooCookie` en lugar de `dart:io Cookie`** — funciona en web y nativo.
2. **Un singleton por servidor** — llama `reset()` solo al cambiar de servidor.
3. **Maneja `OdooSessionExpiredException` globalmente** — intercepta en tu router raíz.
4. **Usa `searchCount` antes de paginar** — evita traer datos innecesarios.
5. **`callMethod` en lugar de `callKwRaw`** — mantén la lógica en el repositorio tipado.
6. **Persiste `OdooSession`** con `toJson()` para evitar re-autenticar al reabrir la app.
7. **`inRequestStream` para UX** — conecta al indicador de carga global en `main.dart`.

---

## 📁 Estructura del Paquete

```
odoo_core/
└── lib/src/
    ├── network/
    │   ├── client/
    │   │   ├── odoo_rpc_service.dart      # Cliente HTTP + autenticación + realtime
    │   │   └── odoo_realtime_client.dart  # WebSocket client
    │   ├── exceptions/
    │   │   └── odoo_exception.dart        # OdooException + OdooSessionExpiredException
    │   ├── model/
    │   │   └── base_model.dart            # OdooBaseModel (id, name, timestamps)
    │   ├── params/
    │   │   └── odoo_rpc_params.dart       # UserContext
    │   ├── responses/
    │   │   └── rpc_response.dart          # RpcResponse<T>
    │   ├── odoo_cookie.dart               # Parser RFC 6265 cross-platform ← NUEVO
    │   └── odoo_session.dart              # OdooSession + OdooCompany
    ├── odoo_annotation.dart               # @OdooModel, @OdooField, OdooFieldType
    └── odoo_base.dart                     # OdooClient, OdooRepository<T>
```
