---
trigger: always_on
description: Regla obligatoria para agentes - Actualizar CHANGELOG.md y utilizar graphify en todas las tareas del proyecto.
---

## Registro de Cambios y Uso de Graphify (Obligatorio)

Todo agente de IA que trabaje en este repositorio DEBE cumplir estrictamente las siguientes reglas sin excepción:

1. **Uso Obligatorio de Graphify en Consultas y Modificaciones**:
   - Ante cualquier duda de código o arquitectura, si existe `graphify-out/graph.json`, se DEBE usar `graphify query "<pregunta>"` primero.
   - Tras realizar cualquier modificación o creación de archivos en el proyecto, se DEBE ejecutar `graphify update .` para mantener el grafo de conocimiento actualizado.

2. **Registro Obligatorio en CHANGELOG**:
   - Cada vez que se realice un cambio, corrección, refactorización o nueva característica en el código de `odoo_core` o `odoo_generator`, se DEBE registrar inmediatamente el cambio en su correspondiente archivo de registro:
     - Cambios en `odoo_core/` -> [odoo_core/CHANGELOG.md](file:///Users/macbook/Documents/Proyectos/Flutter/odoo_dart/odoo_core/CHANGELOG.md)
     - Cambios en `odoo_generator/` -> [odoo_generator/CHANGELOG.md](file:///Users/macbook/Documents/Proyectos/Flutter/odoo_dart/odoo_generator/CHANGELOG.md)
   - Los registros deben seguir el formato SemVer e incluir las secciones correspondientes (`### Added`, `### Changed`, `### Fixed`, `### Removed`).
