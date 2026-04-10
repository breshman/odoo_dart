# Plan de Arquitectura: Librería Odoo Dart (Completa y Escalable)

Para crear una **librería completa que otros proyectos o aplicaciones Flutter puedan importar** fácilmente, necesitas organizar el código respetando los principios de Responsabilidad Única (SOLID) y Desacoplamiento. 

Actualmente, tienes mezclado código de generación (`odoo_generator`), código de modelos base (`d.dart`) y código de servicios HTTP / Riverpod (`api_factory/...`). Esto es peligroso porque un paquete de generadores de código (`build_runner`) **nunca debería depender de Flutter, Dio o Riverpod**.

A continuación el plan ideal para organizar este ecosistema:

## 1. Estructura de Paquetes Recomendada

La forma más profesional de publicar esto (incluso si es un repositorio privado monorepo) es separar en 3 módulos:

1. **`odoo_annotation`**: 
   - Contiene puramente las anotaciones (`@OdooModel`, `@OdooField`).
   - Sin dependencias (cero Dio, cero Flutter).

2. **`odoo_core` (tu framework real)**:
   - Aquí va la clase `OdooBaseModel` y `OdooRepository` que configuramos en `d.dart`.
   - Aquí van los servicios en `api_factory/` (`OdooRpcService`, `dio_factory.dart`, etc.).
   - Dependencias admitidas: `dio`, `json_annotation`, pero **no Flutter**. Así sirve para apps de consola, backend en Dart, etc.
   - Opcionalmente aquí puedes agregar Riverpod, pero lee la sección 2.

3. **`odoo_generator`**:
   - Aquí van las herramientas del `build_runner` (como el actual `odoo_generator_base.dart`).
   - Solo se ejecuta en "tiempo de desarrollo" (`dev_dependencies`). 
   - No contiene código de red ni modelos base, solo emite el `.g.dart` que usará las clases de `odoo_core`.

---

## 2. El Dilema de Riverpod: ¿Usarlo o no en una librería?

Preguntaste si sería bueno usar Riverpod. La respuesta rápida es: **No dentro de la capa Core, pero SÍ como extensión.**

**Por qué no directo en el Core:**
Si obligas a que tu paquete obligue a invocar un `ref.read(...)`, limitas a la gente a usar Riverpod. Cierras las puertas a usuarios que puedan preferir GetX, Bloc o Provider. Una librería buena debe ser **Agnóstica del Estado**.

**Cómo hacerlo correctamente (La Solución):**

1. Tu núcleo debe devolver clases puras, por ejemplo `OdooRpcService()`.
2. Como sabes que tu empresa / tú usan Riverpod, puedes crear archivos opcionales de extensión.
   
Por ejemplo, provees la librería normal, pero si alguien usa Riverpod dejas disponibles Providers estandarizados:

```dart
// En lib/riverpod.dart (Exportable opcional)
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:odoo_core/odoo_core.dart';

part 'odoo_providers.g.dart';

@Riverpod(keepAlive: true)
OdooRpcService odooRpcService(Ref ref) {
  // Ahora el provider solo provee el servicio que es puro
  return OdooRpcService();
}

/// Incluso puedes tener Providers para los repositorios generados
@riverpod
HrEmployeeRepository employeeRepository(Ref ref) {
  final client = ref.watch(odooRpcServiceProvider);
  return HrEmployeeRepository(client);
}
```

De esta forma, mantienes `OdooRpcService` 100% puro y testeable, y usas Riverpod solo como el esqueleto inyector.

---

## 3. Integración de `OdooRpcService` con `OdooRepository`

En nuestro nuevo diseño de `d.dart`, el Repositorio espera usar un `OdooClient`. Ya tienes un método similar en `api_factory`. El plan es unificarlo.

**Tu `OdooRpcService` actual hace esto:**
```dart
  Future<RpcResponse<T>> callKw<T>({
    required String model,
    required String method,
    // ...
```

**Lo que necesitas modificar:**
Solo necesitas ajustar tu `OdooRpcService` para que cumpla con la interfaz del repositorio, o modificar `d.dart` para que el Repositorio utilize tus tipos genéricos `RpcResponse<T>`.

### Plan de Acción:
1. Mover todo lo que está bajo `api_factory` y tu `d.dart` a un nuevo paquete (o si no quieres paquetes múltiples, moverlos fuera de la carpeta `odoo_generator/lib/src` a un bloque general que no sea leído por `build_runner`).
2. Eliminar referencias directas de Riverpod en las clases maestras (Network/Dio) y agrupar todo el Riverpod en archivos dedicados `providers.dart`.
3. Renombrar `d.dart` a `odoo_base.dart` (o similar) para que sea oficial.

## Próximos pasos
Si te gusta este diseño, puedo guiarte refactorizando tu `OdooRpcService` para coincidir 100% con los requerimientos del Repositorio que creamos hace un momento, o refactorizar tu `OdooRepository` temporal para que se case con el tipado exacto que diseñaste en `OdooRpcService`. ¿Por dónde prefieres empezar?
