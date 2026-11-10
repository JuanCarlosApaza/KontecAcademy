# Clean Architecture — Contrato de arquitectura del proyecto

Estándar obligatorio para todas las features (nuevas y existentes).

## Roles por capa

| Concepto | Definición (Rol) | Node.js (TypeScript) | Flutter (Dart) |
|---|---|---|---|
| **Entidad (Entity)** | Objeto de negocio puro con sus reglas internas. | Clase/Tipo TypeScript sin decoradores de DB. | Clase Dart pura (sin anotaciones de JSON/Hive, sin imports de Flutter UI). |
| **Caso de Uso (Use Case)** | Una sola acción del sistema (ej. CrearUsuario). | Clase con método `execute()`. | Clase con método `call()` o `execute()` (extiende `UseCase<T, Params>`). |
| **Interfaz (Interface)** | Contrato que define qué hacer sin importar cómo. | `IUserRepository` (interface) | `abstract class UserRepository` |
| **DTO (Data Transfer Obj)** | Estructura de datos para mover entre capas. | Interfaces o Types (ej. `CreateUserDTO`). | Clases o Records para transportar datos. |
| **Mapper** | Traductor entre tipos externos y tipos de dominio. | Funciones puras (`toDomain()`, `toPersistence()`). | Métodos estáticos (`fromEntity()`, `toModel()`) / `toEntity()`. |

## Estructura de carpetas

### Node.js — `server/src/`

```
src/
├── index.ts                  # Composition root (DI)
├── app.ts                    # Adaptador HTTP delgado: parsea DTO → llama use case → mapea a HTTP
├── domain/                   # Entidades + interfaces de repositorio (cero imports de Express/Supabase)
├── application/
│   ├── dtos/                 # Tipos de entrada + funciones puras de validación
│   └── usecases/             # Una clase por acción, con execute()
└── data/                     # Implementaciones de repositorios + mappers (Supabase / InMemory)
```

Reglas:
- Los handlers de `app.ts` NO contienen lógica de negocio: solo parsing HTTP, invocación de un caso de uso y mapeo de errores a códigos de estado.
- Todo acceso a Supabase vive en `data/`. Nunca `as unknown as`: siempre mapper con nombre (`toDomain()`, `toPersistence()`).
- `domain/` no importa de `application/`, `data/` ni Express.

### Flutter — `lib/features/<feature>/`

```
feature/
├── <feature>_injector.dart   # Composition root (providers Riverpod)
├── domain/
│   ├── entities/             # Clases puras: sin JSON, sin flutter/material
│   ├── repositories/         # abstract class (interfaz)
│   └── usecases/             # clases con call() sobre UseCase<T, Params>
├── data/
│   ├── datasources/          # Dio/Supabase → DTOs; errores → exceptions
│   ├── models/               # DTOs: fromJson/toJson + toEntity()/fromEntity()
│   └── repositories/         # implements la interfaz del dominio; traduce exceptions → Failure
└── presentation/
    ├── screens/              # solo ref.watch / ref.read de viewmodels
    ├── viewmodels/           # Notifier: estado inmutable + copyWith; consume SOLO use cases
    └── widgets/              # widgets de UI puros
```

Reglas:
- La presentation NUNCA importa `dio`, `Supabase` ni parsers JSON.
- El dominio NUNCA importa Flutter UI ni JSON. Los datos de UI derivados (colores, etiquetas de texto) viven en `presentation/` como extensión/mapper de presentación.
- Una sola fuente para cada regla de negocio (ej. total del carrito en `domain/`, no duplicado en pantallas).

## Checklist de revisión por PR

- [x] Entidades sin `fromJson` y sin imports de UI.
- [x] Toda acción de sistema tiene su caso de uso (`call()` / `execute()`).
- [x] Las interfaces de repositorio viven en `domain/`; las impls en `data/`.
- [x] Cada DTO externo tiene su modelo con mapper (`toEntity`/`fromEntity` o `toDomain`/`toPersistence`).
- [x] Presentation sin acceso directo a HTTP/DB.
- [x] Sin casts crudos (`as unknown as`, `as Map<String, dynamic>` sobre respuestas) fuera de models.

> **Verificado 2026-10-24** (grep + `flutter analyze` + `npm run typecheck`):
> - Sin `fromJson` ni `package:flutter/*` bajo `domain/`; sin `dio`/`supabase_flutter`
>   bajo `presentation/` (solo `main.dart`, `core/network` y `data/datasources`).
> - `cart`, `aula` y `mycourses` recibieron sus casos de uso (`LoadCart`/`SaveCart`,
>   `GetCurriculum`/`SetLessonProgress`, `FetchMyCourses`): la presentation ya solo
>   invoca casos de uso ensamblados en los `*_injector.dart` (las lecturas de estado
>   de sesión —`authStateChanges`/`accessToken`/`currentUser`— usan la interfaz de
>   dominio, sin HTTP/DB directo).
> - `as unknown as`/`as any` = **0** en Node (helper `asRows` → `data/postgrest-rows.ts`);
>   los `as Map<String, dynamic>` solo existen en `data/` como frontera DTO hacia
>   `Model.fromJson` (el parseo de campos vive en models); ninguno en domain ni
>   presentation.

---

# Plan de migración por fases

- [x] **Fase 0** — Este documento.
- [x] **Fase 1 (Flutter)** — Capa de datos de `admin`: DTOs + models (`admin_stats_model`, `student_record_model`, `admin_user_record_model`, `created_user_model`, `uploaded_image_model`), `fromJson` fuera de las entidades, datasources devuelven models y repositorios hacen `toEntity()`.
- [x] **Fase 2 (Flutter)** — `AdminSessionRepository` + `GetMyRoles` + `SessionRolesModel` (el `GET /me` ya no se llama desde presentation); router resuelve la sesión vía `AuthRepository` (sin `Supabase.instance` directo).
- [x] **Fase 3 (Flutter)** — `TrainingCourse` puro (sin `flutter/material`: `modality` guarda el código de BD y los textos/colores de UI viven en `presentation/course_display.dart`); total del carrito en una sola fuente (`CartItemsTotal.totalPrice`); `GetCourseById` con `GET /courses/:id` (la pantalla de detalle ya no busca en listas); formato de moneda único (`core/format/currency.dart`); helper de modalidad único (`core/format/course_labels.dart`).
- [x] **Fase 4 (Flutter)** — `CartItemModel` (persistencia con `fromJson/toJson/fromEntity/toEntity`), `CheckoutResultModel`; regla de slug única en `admin/domain/category_slug.dart` (antes duplicada en 2 use cases + repositorio); borrado `course_mock_datasource.dart` (dead code).
- [x] **Fase 5 (Node)** — Capa `application/` con casos de uso (`execute()`) y DTOs; `app.ts` delgado.
- [x] **Fase 6 (Node)** — Mappers con nombre en todos los repos Supabase (eliminar `as unknown as`), `findById`, limpieza de `AppDependencies` duplicado, tipos unión para enums.
- [x] **Fase 7** — Verificación final: `flutter analyze`/`flutter test`, `npm run typecheck`/`npm test`, checklist cruzado + smoke HTTP de la API (health, `/courses`, `/courses/:id`, 404). El smoke visual en navegador queda pendiente de revisión manual (sin navegador conectado a la sesión).

## Deuda registrada (fuera de alcance de este plan)

- `_serverOrNetwork` (Dio → excepción) está duplicado en 3 datasources de `admin` (y probablemente en otros features). Consolidar en un mapper compartido en `core/error/`.
