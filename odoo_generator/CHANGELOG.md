## 2.1.1

- Feat: correcion de casteo de tipos dinamicos.

## 2.1.0

- Feat: Added automatic generation of `[ClassName]Fields` enums for all models to enable type-safe field selection.
- Feat: Implemented `fieldMapping` and a powerful `buildSpecification` method (with `only` and `nested` support) in generated Meta classes.
- Feat: Added support for `includeBaseFieldsInSpec` from `@OdooModel` to control the presence of base fields in the default specification map.

## 2.0.4

- Feat: Added support for `generateRepository` in `@OdooModel` annotation to optionally disable the generation of Repositories for specific models.
- Fix: String parser generation now outputs `.toString()` instead of `as String` to gracefully handle unexpected types coming from Odoo JSON-RPC. Lists are explicitly cast as `List<dynamic>` to satisfy the linter.

## 2.0.3

- Chore: Version bump to maintain parity with `odoo_core` after strict `very_good_analysis` linter patches.

## 2.0.2

- Fix: Enforced explicit `as bool` typecasting for boolean fields in `fromJson` generation to avoid "type 'dynamic' can't be assigned to the parameter type 'bool?'" compile errors.

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
