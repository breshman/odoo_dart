# Graph Report - .  (2026-08-01)

## Corpus Check
- Corpus is ~21,285 words - fits in a single context window. You may not need a graph.

## Summary
- 350 nodes · 412 edges · 16 communities (14 shown, 2 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Generator Examples & Tests
- Odoo Models & Repositories
- Network RPC Service & Dio Client
- Core BaseModel & Annotations
- Source Generator Code Builder
- Session Management & Storage
- Realtime WebSocket Client
- Exception Handling & Errors
- Cookie & Header Interceptors
- Type Resolver & Analyzer Helpers
- Test Suite & Mocks
- HTTP Client Extensions
- Base RPC Service Helpers
- Core Utilities & Helpers
- Build Config & Options
- Generator Extension Helpers

## God Nodes (most connected - your core abstractions)
1. `OdooModel` - 10 edges
2. `OdooBaseModel` - 9 edges
3. `Partner` - 6 edges
4. `User` - 6 edges
5. `Employee` - 6 edges
6. `OdooException` - 5 edges
7. `Category` - 5 edges
8. `Tag` - 5 edges
9. `Product` - 5 edges
10. `ProductLine` - 5 edges

## Surprising Connections (you probably didn't know these)
- `OdooModelGenerator` --references--> `OdooModel`  [EXTRACTED]
  odoo_generator/lib/src/odoo_generator_base.dart → odoo_core/lib/src/network/model/odoo_annotation.dart
- `Category` --inherits--> `OdooBaseModel`  [EXTRACTED]
  odoo_generator/example/odoo_generator_example.dart → odoo_core/lib/src/network/model/base_model.dart
- `Order` --inherits--> `OdooBaseModel`  [EXTRACTED]
  odoo_generator/example/odoo_generator_example.dart → odoo_core/lib/src/network/model/base_model.dart
- `Product` --inherits--> `OdooBaseModel`  [EXTRACTED]
  odoo_generator/example/odoo_generator_example.dart → odoo_core/lib/src/network/model/base_model.dart
- `ProductLine` --inherits--> `OdooBaseModel`  [EXTRACTED]
  odoo_generator/example/odoo_generator_example.dart → odoo_core/lib/src/network/model/base_model.dart

## Import Cycles
- None detected.

## Communities (16 total, 2 thin omitted)

### Community 0 - "Generator Examples & Tests"
Cohesion: 0.05
Nodes (39): bool?, dart:convert, dart:io, double?, ../example/odoo_generator_example.dart, categoryId, categoryJson, color (+31 more)

### Community 1 - "Odoo Models & Repositories"
Cohesion: 0.08
Nodes (37): email, Employee, fromJson, isCustomer, isVendor, jobTitle, lang, login (+29 more)

### Community 2 - "Network RPC Service & Dio Client"
Cohesion: 0.06
Nodes (33): Dio, ../../odoo_base.dart, authenticate, callKwRaw, checkCurrentUser, checkSession, connectRealtime, _currentSession (+25 more)

### Community 3 - "Core BaseModel & Annotations"
Cohesion: 0.07
Nodes (29): bool get, dart:async, ../example/runbot_models.dart, Exception?, Map, accessDenied, code, data (+21 more)

### Community 4 - "Source Generator Code Builder"
Cohesion: 0.07
Nodes (27): ../exceptions/odoo_exception.dart, int?, List, generateRepository, includeBaseFieldsInSpec, includeInSpec, modelName, name (+19 more)

### Community 5 - "Session Management & Storage"
Cohesion: 0.07
Nodes (28): int get, allowedCompanies, companyId, csrfToken, dbName, fromJson, fromJsonList, fromSessionInfo (+20 more)

### Community 6 - "Realtime WebSocket Client"
Cohesion: 0.08
Nodes (24): GeneratorForAnnotation, _buildFromJsonExpression, _buildToJsonExpression, _camelToSnake, _extendsOdooBaseModel, _generateCopyWith, _generateFieldsEnum, generateForAnnotatedElement (+16 more)

### Community 7 - "Exception Handling & Errors"
Cohesion: 0.10
Nodes (20): ../model/odoo_session.dart, ../odoo_cookie.dart, baseUrl, _channel, connect, disconnect, fromSession, _handleIncomingMessage (+12 more)

### Community 8 - "Cookie & Header Interceptors"
Cohesion: 0.10
Nodes (20): network/model/base_model.dart, ../odoo_core.dart, OdooRpcService, callKwRaw, callMethod, client, create, modelName (+12 more)

### Community 9 - "Type Resolver & Analyzer Helpers"
Cohesion: 0.11
Nodes (18): _baseUrl, _db, dio, main, odoo, _pass, sessionCookie, _user (+10 more)

### Community 10 - "Test Suite & Mocks"
Cohesion: 0.12
Nodes (16): domain, expires, extractSessionId, httpOnly, maxAge, _name, OdooCookie, _parseSetCookieValue (+8 more)

### Community 11 - "HTTP Client Extensions"
Cohesion: 0.14
Nodes (13): DateTime?, baseFromJson, baseSpecification, baseToJson, createDate, createUid, displayName, id (+5 more)

### Community 12 - "Base RPC Service Helpers"
Cohesion: 0.15
Nodes (12): library, odoo_core, src/network/client/odoo_realtime_client.dart, src/network/client/odoo_rpc_service.dart, src/network/exceptions/odoo_exception.dart, src/network/model/base_model.dart, src/network/model/odoo_annotation.dart, src/network/model/odoo_session.dart (+4 more)

### Community 13 - "Core Utilities & Helpers"
Cohesion: 0.18
Nodes (10): EmptyBody, from, fromJson, id, jsonrpc, method, params, RpcPayload (+2 more)

## Knowledge Gaps
- **243 isolated node(s):** `_baseUrl`, `_db`, `_user`, `_pass`, `dio` (+238 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **2 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `OdooSession` connect `Session Management & Storage` to `Network RPC Service & Dio Client`?**
  _High betweenness centrality (0.029) - this node is a cross-community bridge._
- **Why does `OdooException` connect `Core BaseModel & Annotations` to `Source Generator Code Builder`?**
  _High betweenness centrality (0.025) - this node is a cross-community bridge._
- **What connects `_baseUrl`, `_db`, `_user` to the rest of the system?**
  _243 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Generator Examples & Tests` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._
- **Should `Odoo Models & Repositories` be split into smaller, more focused modules?**
  _Cohesion score 0.08392603129445235 - nodes in this community are weakly interconnected._
- **Should `Network RPC Service & Dio Client` be split into smaller, more focused modules?**
  _Cohesion score 0.05714285714285714 - nodes in this community are weakly interconnected._
- **Should `Core BaseModel & Annotations` be split into smaller, more focused modules?**
  _Cohesion score 0.07096774193548387 - nodes in this community are weakly interconnected._