# Changelog

All notable changes to the `odoo_core` project will be documented in this file.

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
