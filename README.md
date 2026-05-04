# Odoo Dart

Odoo Dart es un ecosistema modular diseñado para facilitar la conexión, autenticación y comunicación entre aplicaciones Dart/Flutter y servidores Odoo, siguiendo principios SOLID y Clean Architecture de manera completamente agnóstica a la UI.

## Paquetes

Este repositorio se compone de los siguientes módulos principales:

- [**odoo_core**](./odoo_core/README.md): El núcleo de la arquitectura. Proporciona la lógica de autenticación, gestión de sesiones, cliente RPC, parseo de cookies (RFC 6265), soporte en tiempo real por WebSockets y repositorios base para interactuar con la base de datos de Odoo.
- [**odoo_generator**](./odoo_generator/README.md): Un generador de código fuente complementario. Convierte clases Dart anotadas (`@OdooModel` / `@OdooField`) en repositorios tipados, métodos de serialización JSON y enum de campos para consultas fuertemente tipadas.
