## 2.0.1

- Fix: Prevented code generation for getters, setters, and unannotated properties to avoid "named parameter isn't defined" compiling errors.
- Fix: Eliminated analyzer subtype inheritance bugs triggered by `orElse` when verifying optional fields on class constructors.

## 2.0.0

- Refactor: Migrate from `odoo_annotation` to `odoo_core`.
- Add `OdooRealtimeClient` for real-time updates.
- Implement `RpcResponse<T>` for typed RPC responses.
- Add `OdooException` for proper error handling.
- Add `OdooBaseModel` with `copyWith`, `toString`, `equals`, and `hashCode`.
- Add `OdooModel`, `OdooField`, and `OdooRelation` annotations.
- Add `OdooModelBuilder` and `OdooRepositoryBuilder` for code generation.
- Add `OdooSpecExtension` and `OdooModelExtension` for introspection.
- Add `OdooRpcService` for generic RPC calls.
- Add `OdooSearchParams`, `OdooCreateParams`, `OdooWriteParams`, `OdooUnlinkParams` for typed parameters.
- Add `OdooBaseRepository` for repository pattern.
