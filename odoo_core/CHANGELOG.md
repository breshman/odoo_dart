# Changelog

All notable changes to the `odoo_core` project will be documented in this file.

## [2.4.1] - 2026-10-26
### Changed
* **`OdooRepository.searchFetch`:** uses the repository's default specification when no override is provided.

## [2.4.0] - 2026-10-22
### Added
* **`OdooCommand`:** Clase con comandos ORM de Odoo para relaciones `One2many` y `Many2many` (`create`, `update`, `delete`, `unlink`, `link`, `clear`, `set`). Compatible con `odoo.fields.Command` en Odoo 16, 17, 18 y 19+. Soporta tanto llamadas estáticas directas que retornan `List<dynamic>` como instancias tipadas (`OdooCommand.linkRecord`, `setRecords`, etc.) serializables a JSON tupla.
* **`OdooRepository.webCreate()`:** Método de creación estándar para Odoo 16/17/18+ usando `web_save` con lista de IDs vacía (`[]`), retornando la entidad tipada completa con los campos de la `specification` en una sola petición.
* **Normalización automática de valores:** `OdooRepository` (`create`, `write`, `webSave`, `webCreate`) normaliza automáticamente cualquier instancia de `OdooCommand` dentro de los diccionarios de valores.
* **`OdooSession.serverVersionInt` & `isAtLeastV18`:** Getters con parser regex robusto que extraen la versión mayor tanto de cadenas estándar (`18.0+e`) como saas (`saas~19.3+e`).
* **`OdooSessionStore` & `InMemorySessionStore`:** Abstracción limpia desacoplada de la UI/framework para persistencia y lectura de sesiones activas (`save`, `read`, `clear`).
* **`OdooRpcService.standalone()`:** Constructor factoría que permite crear instancias independientes aisladas (no singleton) para escenarios multi-tenant o testing con inyección de dependencias.
* **`OdooRpcService.restoreSession()`:** Método para restaurar una sesión activa previamente guardada en el `OdooSessionStore`.

### Changed
* **`OdooRpcService.inRequestStream`:** Mejorado con un contador de peticiones en vuelo (`_activeRequestsCount`) para evitar que peticiones concurrentes apaguen prematuramente el indicador de carga global.
* **`OdooRepository.callRpc`:** Renombrado el parámetro de tipo genérico a `R` para evitar shadowing de `T` de la clase contenedora.
* **Pruebas de Integración RunBot:** Aisladas mediante la bandera `_runbotEnabled` (`ODOO_RUNBOT_TEST`) y actualizadas a la instancia de prueba activa Odoo 19 (`saas~19.3+e`), validando exitosamente operaciones CRUD, `OdooCommand` y `webCreate`.

### Fixed
* **`OdooSession.fromSessionInfo`:** Se corrigió el valor por defecto de `websocket_worker_version` a `'1'` cuando no viene en el payload del servidor.

## [2.3.0] - 2026-08-02
### Added
* **`SpecificationBuilder`:** Clase abstracta base implementada por todos los builders generados (`${ClassName}SpecificationBuilder`).
* **`OdooSpec` & `resolveOdooSpec`:** `typedef OdooSpec = Object;` permite que `OdooRepository` (`searchFetch`, `read`, `webSave`) acepte directamente una instancia de `SpecificationBuilder` o un `Map<String, dynamic>`, ejecutando `.build()` internamente de forma automática.

## [2.2.0] - 2026-04-15
### Added
* **`OdooSession`:** Nueva clase inmutable y serializable que representa la sesión autenticada de Odoo. Incluye `userId`, `companyId`, `allowedCompanies`, `userName`, `serverVersionInt` y soporte multi-versión (Odoo 12–18+). Métodos `fromSessionInfo`, `fromJson`, `toJson` y `updateSessionId`.
* **`OdooCompany`:** Clase auxiliar de empresa para `OdooSession.allowedCompanies`.
* **`OdooSessionExpiredException`:** Subclase de `OdooException` lanzada automáticamente cuando el servidor Odoo retorna código de error 100 (sesión expirada). Úsala para redirigir al login sin tener que inspeccionar códigos manualmente.
* **`OdooException` — Factory constructors semánticos:** Agregados `OdooException.accessDenied()`, `OdooException.notFound()` y `OdooException.serverError()` para errores comunes.
* **`OdooException.isAuthError`:** Getter booleano que retorna `true` para códigos 100 y 403.
* **`OdooRpcService.authenticate()`:** Método tipado para autenticar contra Odoo, retorna `OdooSession` directamente.
* **`OdooRpcService.destroySession()`:** Cierra la sesión en el servidor. Limpia `currentSession` localmente aunque el servidor falle.
* **`OdooRpcService.checkSession()`:** Verifica si la sesión activa sigue siendo válida. Lanza `OdooSessionExpiredException` si expiró.
* **`OdooRpcService.inRequestStream`:** `Stream<bool>` que emite `true` al inicio de cada petición HTTP y `false` al terminar. Implementado como interceptor Dio global para cubrir todos los métodos.
* **`OdooRpcService.currentSession`:** Getter que retorna la `OdooSession` activa (null si no autenticado).
* **`OdooRpcService.reset()`:** Destruye el singleton para reiniciar el cliente (cambio de servidor, logout completo).
* **`OdooRpcService.setBaseUrl()`:** Cambia la URL base del cliente Dio en tiempo de ejecución.
* **`OdooRepository.searchCount()`:** Cuenta registros con dominio sin traer datos. Usa `search_count` de Odoo ORM.
* **`OdooRepository.callMethod()`:** Invoca cualquier método de negocio Odoo (e.g. `action_confirm`, `button_validate`) encapsulado dentro del repositorio tipado.

### Changed
* **`OdooRpcService`:** Ahora lanza `OdooSessionExpiredException` automáticamente cuando el servidor retorna `error.code == 100`, en lugar de la genérica `OdooException`.

## [2.1.1] - 2026-04-13
### Changed
* **odoo_rpc_params.dart:** Se marco como comentado para ver si se puede usar luego.

## [2.1.0] - 2026-04-13
### Added
* **Dynamic Specification:** Added an optional `specification` parameter to `OdooRepository` methods (`searchFetch`, `read`, `webSave`) allowing runtime control over fields returned from Odoo.
* **@OdooModel:** Added `includeBaseFieldsInSpec` (defaults to `true`) to allow excluding standard auditoría fields (`create_date`, `write_uid`, etc.) from the default specification.
### Changed
* **OdooBaseModel:** Removed the `active` field from the base model for a cleaner, more robust structure across different Odoo versions.

## [2.0.4] - 2026-04-11
### Added
* **@OdooModel:** Added `generateRepository` flag (defaults to `true`) allowing developers to opt-out of automatic repository generation.
### Changed
* **Generator Stability:** String fields parsed by the generator now use `.toString()` natively instead of `as String`, preventing cast-related exceptions when Odoo returns numeric values in string fields. Downcasts for generic lists (`List<dynamic>`) were also enforced.


## [2.0.3] - 2026-04-11
### Added
* **Linter:** Implemented strict code rules utilizing `very_good_analysis` to ensure higher type safety across the repository.
### Fixed
* **odoo_realtime_client:** Eliminated `type 'dynamic' can't be assigned to 'List<dynamic>'` exceptions by providing explicit JSON decodings.
* **odoo_realtime_client:** Handled unparsed socket payload logging (`else` block) and resolved mutability lints (`prefer_final_in_for_each`).

## [2.0.2] - 2026-04-11
### Changed
* **Dependencies:** Bumped `odoo_generator` requirement to `2.0.2` due to fixes for explicit boolean casting (`as bool`) in `fromJson` logic.

## [2.0.1] - 2026-04-11
### Changed
* **Dependencies:** Bumped `odoo_generator` requirement to `2.0.1` because of hotfixes related to Dart analyzer subtypes and unexpected generation of getters/setters/transient properties.

## [2.0.0] - 2026-04-10
### Added
* **SOLID Architecture:** Complete rewrite separating logical layers, utilizing Clean Architecture principles.
* **OdooBaseModel:** Native automatic mapping for Odoo base fields such as `id`, `name`, `active`, `create_date`, `write_date`, `create_uid`, and `write_uid`.
* **OdooRepository<T>:** New typed generic repositories allowing completely strict typing via code generation. Added standard methods `searchIds`, `searchFetch`, `read`, `create`, `write`, `unlink`, and `webSave`.
* **Integrated Annotations:** Merged `odoo_annotation` into `odoo_core`, offering `@OdooModel` and `@OdooField` decorators in a single package. No need to install annotation packages independently anymore.
* **Realtime Sockets Client:** Added `OdooRealtimeClient` component within the `network/client` architecture to allow easy connections to WebSockets endpoint (`/websocket`) for real-time notifications in Odoo 18.0+.
* **OdooException:** Master exception handler (`OdooException`) that internally handles Odoo JSON-RPC nested errors and exposes intelligent string messages.

### Changed
* **Environment Bounds:** Expanded Dart SDK support constraint to `>=3.0.0 <4.0.0` inside `pubspec.yaml`, ensuring 100% compatibility with Dart 3's records and patterns.
* **Folder Structure:** Flattened the library structure! Deprecated the Java-like `api_factory/odoo/model` deeply nested folders in favor of a semantic `network/` distribution (`client/`, `params/`, `responses/`, `exceptions/`).
* **Clean DI & State Independence:** Fully decoupled Riverpod/GetX from the base logic. Frameworks can now safely consume the client and pass it down as standard dependencies (`Mocking` available).

### Removed
* Removed redundant proxy methods from the master network client (e.g. `odooCreate`, `odooWrite`) and moved native responsibilities back directly to `OdooRepository`.
* Removed internal duplications in parameter typing classes, providing a sole source of truth in `network/params/`.
* Removed duplicate `OdooRpcException` and `RpcError` in favor of the unified `OdooException` file.
