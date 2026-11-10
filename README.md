# Kontec

Monorepo con **frontend Flutter** (web + Android, iOS listo) y
**backend Node.js + TypeScript**, con **Clean Architecture + MVVM + Riverpod + go_router + dio**.

```
Kontec/
├── lib/   app/  core/  features/   # 🖥️ Frontend Flutter (Clean + MVVM)
├── server/                         # 🟩 Backend Node.js + TypeScript
│   ├── src/domain|data|app|index   #    misma separación de capas que el front
│   ├── tests/                      #    tests con Vitest + Supertest
│   └── Dockerfile                  #    listo para desplegar (VPS/Docker)
├── tool/                           # 🛠️ Scripts de desarrollo y despliegue
│   ├── dev-all.ps1                 #    abre las DOS terminales de golpe
│   ├── dev-api.ps1                 #    terminal 1 → backend :3000
│   ├── dev-web.ps1                 #    terminal 2 → frontend :8080 (CORS libre)
│   └── build.ps1                   #    compila todo → dist\ ZIPs para Hostinger
└── test/                           # 🧪 tests del frontend
```

## Desarrollo en dos terminales (back + front)

### Opción A — un comando que abre las dos ventanas

```powershell
powershell -ExecutionPolicy Bypass -File tool\dev-all.ps1
```

### Opción B — tus dos terminales a mano

```powershell
# TERMINAL 1 — Backend Node.js (http://localhost:3000)
powershell -ExecutionPolicy Bypass -File tool\dev-api.ps1

# TERMINAL 2 — Frontend (Flutter web en http://localhost:8080, CORS libre)
powershell -ExecutionPolicy Bypass -File tool\dev-web.ps1
```

| Terminal | Puerto | Hot reload |
|---|---|---|
| 1 · `dev-api.ps1` | `http://localhost:3000` | automático al guardar en `server/` |
| 2 · `dev-web.ps1` | `http://localhost:8080` | `r` = recargar · `R` = reiniciar |

**Endpoints disponibles:** `GET /` (health) · `GET /todos` · `POST /todos {"title":"..."}`

Los dos procesos pueden reiniciarse por separado sin afectar al otro:
si solo tocas el backend, la terminal 2 sigue viva y viceversa.

**Comandos del backend Node** (dentro de `server/`):

```powershell
npm run dev         # desarrollo con hot reload (tsx watch)
npm test            # 6 tests (Vitest + Supertest)
npm run typecheck   # TypeScript estricto
npm run build       # compila a dist/
npm start           # producción (node dist/index.js)
```

## Plataformas

```powershell
# 🚀 Desarrollo normal: backend + frontend (ver sección superior)
powershell -ExecutionPolicy Bypass -File tool\dev-all.ps1

# Web sin opciones especiales
flutter run -d chrome   # o: flutter run -d edge

# Android (emulador o dispositivo)
flutter run -d android

# iOS (solo en macOS con Xcode)
flutter run -d ios

# Compilar para producción (recuerda: la API no es localhost)
flutter build web --dart-define=API_URL=https://mi-api.com
flutter build apk --dart-define=API_URL=https://mi-api.com
```

### Desarrollo web con CORS libre (solo local)

Durante el desarrollo, `tool\dev-web.ps1` arranca Edge en un **perfil
aislado** (`.dart_tool\nocors-profile`) con `--disable-web-security`, así
la app puede llamar a APIs que todavía no tienen cabeceras CORS:

```powershell
powershell -ExecutionPolicy Bypass -File tool\dev-web.ps1

# apuntando a tu API local de backend
powershell -ExecutionPolicy Bypass -File tool\dev-web.ps1 -ApiUrl http://localhost:3000
```

> ⚠️ **Solo desarrollo**: en producción el navegador del usuario bloqueará
> esas peticiones → hay que habilitar CORS en el backend
> (`Access-Control-Allow-Origin`). Tu Edge normal no se ve afectado
> (el script usa un perfil temporal aparte). En **Android/iOS no existe
> CORS**, eso es una restricción exclusiva del navegador.

Configura la URL de tu API por entorno:

```powershell
flutter run -d chrome --dart-define=API_URL=https://mi-api.com
```

## Arquitectura

Feature-first: cada módulo se aísla en `lib/features/<feature>/`
y dentro sigue las capas de Clean Architecture, con MVVM en la presentación.

```
lib/
├── main.dart                  # runApp + ProviderScope (contenedor DI)
├── app/                       # 🎨 Composición de la app (SOLO UI)
│   ├── app.dart               # MaterialApp.router, tema
│   └── router/app_router.dart # go_router
├── core/                      # ⚙️ Código compartido (sin reglas de negocio)
│   ├── error/                 #    exceptions (data) y failures (domain)
│   ├── network/               #    dio_client, api_config
│   └── usecase/               #    contrato UseCase<T, Params>
└── features/
    ├── landing/               # 🏠 Home/landing (insight-construction.com)
    │   ├── landing_injector.dart
    │   ├── domain/            #    TrainingCourse, GetFeaturedCourses
    │   ├── data/              #    CourseMockDataSource (🔴 datos quemados)
    │   └── presentation/      #    HomeViewModel + navbar/hero/carousel
    └── tasks/                 # 📦 Feature de ejemplo
        ├── task_injector.dart #    composition root (ensambla capas)
        ├── domain/            # 🧠 Lógica pura (SIN Flutter, Dio, JSON)
        │   ├── entities/      #    Task (lenguaje del negocio)
        │   ├── repositories/  #    abstract TaskRepository (interfaz)
        │   └── usecases/      #    GetTasks, CreateTask
        ├── data/              # 🔌 Implementación técnica
        │   ├── models/        #    TaskModel (JSON <-> entidad)
        │   ├── datasources/   #    TaskRemoteDataSource (habla con la API)
        │   └── repositories/  #    TaskRepositoryImpl (errores -> failures)
        └── presentation/      # 🖼️ MVVM
            ├── viewmodels/    #    TasksViewModel (Notifer de Riverpod)
            ├── screens/       #    TasksScreen (vista)
            └── widgets/       #    componentes reutilizables
```

### Reglas de dependencia (⚠️ se chequean en code review)

```
presentation ──▶ domain ◀── data
      │              ▲          │
      │      (el dominio no     │
      │      sabe quién lo      │
      │      implementa)        │
      └──── task_injector ◀─────┘
```

| Capa | Puede importar | Jamás importa |
|------|----------------|---------------|
| `domain` | nada externo | Flutter, Dio, JSON, Riverpod |
| `data` | `domain`, dio | Widgets, pantallas |
| `presentation` | `domain`, Flutter, Riverpod | Dio, datasources, modelos |
| `app` / `main` | todo (ensambla) | lógica de negocio |

### Flujo MVVM

```
Widget (view) ──eventos──▶ ViewModel ──▶ Caso de uso ──▶ Repositorio (interfaz)
     ▲                        │                              ▲
     └──── ref.watch(state) ◀─┘                    RepositorioImpl / DataSource
```

1. El **Widget** dibuja `state` y emite eventos (`viewModel.addTask(...)`).
2. El **ViewModel** (`presentation/viewmodels`) no hace llamadas HTTP:
   invoca casos de uso y transforma el resultado en `TasksState`.
3. El **Caso de uso** (`domain/usecases`) contiene la regla de negocio.
4. El **Repositorio** (`domain/repositories`) es una interfaz; la
   implementación (`data/repositories`) usa un **DataSource** que llama a Dio
   y traduce excepciones → `Failure`.

## Cómo añadir una feature nueva

1. `lib/features/<nueva>/domain/` → entidad, interfaz de repositorio, casos de uso.
2. `lib/features/<nueva>/data/` → modelo, datasource remoto, `RepositorioImpl` + provider.
3. `<nueva>_injector.dart` → `Provider` de los casos de uso (composition root).
4. `presentation/` → `ViewModel` (Riverpod) + screens/widgets.
5. `app/router/app_router.dart` → añade la ruta.

Copia `features/tasks/` como plantilla.

## Backend (Node.js + TypeScript) — `server/`

Backend **recomendado** (mismos endpoints y mismo JSON que el original:
el frontend funciona sin cambios, solo se cambió la implementación).

```
server/
├── src/
│   ├── domain/todo.ts               # 🧠 dominio: interfaz Todo + TodoRepository
│   ├── data/in-memory-todo-repository.ts  # 🔌 datos: implementación (futura BD)
│   ├── app.ts                       # 🎨 Express: CORS, rutas, validación, errores
│   └── index.ts                     # composition root: escucha en PORT
├── tests/app.test.ts                # 🧪 6 tests (Vitest + Supertest)
├── Dockerfile                       # 🐳 imagen de producción (etapas multi-stage)
├── tsconfig.json                    # TypeScript estricto (strict + noUncheckedIndexedAccess)
└── package.json
```

| Capa Node | Equivalente en el front (Clean + MVVM) |
|---|---|
| `src/domain` | `lib/features/*/domain` |
| `src/data` | `lib/features/*/data` |
| `src/app.ts` (rutas/CORS) | `lib/app` + presentación (sin lógica de negocio) |
| `src/index.ts` (composition root) | `task_injector.dart` + `main.dart` |

- **CORS** ya incluido con `cors()` en `src/app.ts`. Para producción,
  restringe al dominio real: `app.use(cors({ origin: ['https://tudominio.com'] }))`.
- Para añadir ruta: `app.get/post(...)` en `app.ts` (o crear `src/routes/*.ts` cuando crezca).
- Para cambiar a BD: implementa `TodoRepository` y cambia `src/index.ts`.
  Los handlers no cambian.
- ⚠️ **Memoria volátil**: mientras no haya BD, la lista se vacía al reiniciar.

### Backend alternativo

*(eliminado: el proyecto usa únicamente Node.js — el backend Dart Frog original
queda en el historial de git del primer commit, por si se quisiera retomar)*

### Herramienta de BD (`npm run db:sql`)

Para consultar o modificar la base de datos **directo desde la terminal**
(sin entrar al SQL Editor de Supabase):

```powershell
cd server

# SQL en línea (SELECT, UPDATE, INSERT…)
npm run db:sql -- "select id, email from public.users limit 10"

# Ejecutar un archivo .sql
npm run db:sql -- --file sql/004_create_carts.sql

# Aplicar TODAS las migraciones de sql/*.sql pendientes
# (control en la tabla _migrations; cada archivo en su transacción)
npm run db:sql -- --migrate

# Verificar que el esquema publicado coincide con el proyecto
npx tsx tool/check-schema.ts
```

Requiere `SUPABASE_DB_URL` en `server/.env` (Supabase → Project
Settings → Database → Connection string → URI, modo **Direct
connection**, usuario `postgres`). La conexión usa SSL y se cierra
siempre al terminar.

## Autenticación, carrito y panel admin (Supabase)

Flujo de compra: **ver cursos → "agregar al carrito" (pide login) →
checkout con datos personales → inscripción + pago pendiente en Supabase**.

### Configuración

1. **Clave pública del cliente** — ya está en
   `lib/core/config/supabase_config.dart` (`SupabaseConfig.anonKey`);
   se puede sobrescribir en build con
   `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`.
2. **Backend** — `server/.env` con `SUPABASE_URL` y
   `SUPABASE_SERVICE_ROLE_KEY` (la clave **secreta**, jamás en el front).
3. **Migraciones SQL** — ya no hace falta el SQL Editor: desde `server/`
   aplicas todo con la tool de BD (ver "Herramienta de BD" más abajo):
   `npm run db:sql -- --migrate`. A mano (SQL Editor) también vale:
   - `server/sql/002_add_user_document.sql` — agrega `document_number` a `public.users`.
   - `server/sql/003_seed_roles.sql` — crea los roles `admin` y `student`.
   - `server/sql/004_create_carts.sql` — tabla `carts` (carritos por usuario).
4. **URLs de redirect** (Supabase → Authentication → URL Configuration):
   - Web: `http://localhost:8080/**` (dev) y tu dominio de producción.
   - Android: `kontec://login-callback` (deep link ya declarado en
     `android/app/src/main/AndroidManifest.xml`).

### Endpoints nuevos del backend

| Endpoint | Auth | Descripción |
|---|---|---|
| `GET /me` | JWT | Perfil + roles del usuario (`admin`, `student`, …) |
| `GET /my/courses` | JWT | Cursos inscritos del estudiante ("Mis cursos") con su estado |
| `GET /cart` | JWT | Carrito del usuario (título/precio vigentes de la BD) |
| `PUT /cart` | JWT | Reemplaza el carrito completo (`{ items: [{ courseId }] }`) |
| `POST /checkout` | JWT | Upsert `users` + `enrollments` (`pending_payment`) + `payments` (`pending_approval`) |
| `GET /admin/stats` | rol `admin` | KPIs del dashboard (estudiantes, cursos, ingresos…) |
| `GET /admin/students` | rol `admin` | Estudiantes + cursos inscritos |
| `GET /admin/carts` | rol `admin` | Carritos abandonados (agregaron cursos y nunca pagaron) |
| `GET /admin/payments` | rol `admin` | Pagos por estado (`?status=pending_approval` por defecto) |
| `PATCH /admin/payments/:id` | rol `admin` | Aprueba/rechaza un pago (`{ action: 'approve'\|'reject' }`) → da/quita acceso |
| `POST /admin/categories` | rol `admin` | Alta de categorías |
| `POST /admin/users` | rol `admin` | Alta de usuarios (auth + perfil + rol) |
| `GET /admin/courses/:id/curriculum` | rol `admin` | Temario completo del curso (con TODAS las URLs) |
| `POST /admin/courses/:id/modules` | rol `admin` | Alta de módulo `{ title }` |
| `PATCH /admin/modules/:id` | rol `admin` | Edita `{ title?, orderIndex? }` (orderIndex lo mueve) |
| `DELETE /admin/modules/:id` | rol `admin` | Borra el módulo **en cascada** (lecciones + progreso) |
| `POST /admin/modules/:id/lessons` | rol `admin` | Alta de lección `{ title, contentType, videoUrl?, zoomUrl?, driveUrl? }` |
| `PATCH /admin/lessons/:id` | rol `admin` | Edita campos y/o `orderIndex`; una URL se borra con `null` |
| `DELETE /admin/lessons/:id` | rol `admin` | Borra la lección y su progreso |

### Panel administrativo (`/admin`)

Dashboard estilo analítico con sidebar oscuro: **Resumen** (tarjetas KPI +
gráfico + cursos), **Estudiantes**, **Pagos y carritos**, **Cursos**,
**Categorías** y **Usuarios**. El shell valida la sesión y el rol
`admin` (via `GET /me`); sin rol se muestra "Acceso restringido". El
menú "Admin" del navbar solo aparece para administradores.

**Temario** (botón 📖 en la tabla de Cursos) gestiona los módulos y
lecciones que verá el estudiante en el aula: alta, edición, borrado en
cascada y reorden con ↑/↓. Cada lección admite tres URLs (video,
Zoom, Drive); el aula muestra la primera que encuentre. El contenido
solo se sirve al estudiante cuando su pago está **aprobado**.

### Aula del curso (`/capacitaciones/:id/aula`)

Donde el estudiante ve el temario y el contenido de un curso. El
backend calcula el acceso desde la inscripción
(`GET /courses/:id/curriculum`, con `optionalAuth`), así que la misma
pantalla sirve para los cuatro casos:

| `access` | Qué ve el estudiante |
|---|---|
| `full` | Temario navegable, contenido y barra de progreso |
| `pending` | Aviso "Pago en verificación" (sin contenido) |
| `rejected` | Aviso "Pago rechazado" |
| `none` | Invitación a iniciar sesión |

Marcar una lección usa `PATCH /lessons/:id/progress` (exige pago
aprobado → 403 si no) y el progreso se guarda en `lesson_progress`.

**Pagos y carritos** (`/admin/pagos`) es el diagnóstico de ventas
incompletas (estilo WooCommerce):

- **Pagos por aprobar**: quien llegó al checkout y registró un pago,
  filtrable por estado (pendiente / aprobado / rechazado). Cada fila
  pendiente tiene botones **Aprobar** / **Rechazar** (con confirmación).
- **Carritos abandonados**: quién agregó cursos al carrito pero nunca
  completó el checkout (registrado en `public.carts`).

### Flujo de compra con verificación manual de pagos

1. El estudiante se registra, agrega cursos al carrito y solicita el
   pago en `/checkout` → se crea `enrollments.status = 'pending_payment'`
   + `payments.status = 'pending_approval'`.
2. El pago llega a verificación **manual** (Yape/banco, fuera del
   sistema): en **Admin → Pagos y carritos** el administrador lo
   revisa y pulsa **Aprobar** (o **Rechazar**).
   - `PATCH /admin/payments/:id` actualiza `payments` (`approved_by`,
     `paid_at`) y pasa `enrollments.status = 'approved'` → **ese es
     el paso que concede el acceso al curso**.
3. El estudiante entra a **Mis cursos** (`/mis-cursos`, menú superior
   con sesión): ve sus cursos aprobados con botón **Entrar al curso**
   (`GET /my/courses`). Los pagos aún sin revisar aparecen como
   "Pago en verificación" y los rechazados como aviso.

### Carrito de compras por usuario

El carrito es **por cuenta**, nunca compartido entre usuarios:

- **Servidor** (`public.carts`): fuente de verdad; `GET/PUT /cart` con
  el JWT del usuario. Solo guarda `(user_id, course_id, added_at)`;
  título y precio se resuelven contra `courses` al leer (el precio
  siempre es el vigente de la BD, nunca el que envía el cliente).
  RLS habilitada sin policies: solo el backend (service role) accede.
- **Dispositivo**: caché local con clave `kontec_cart_v1::<user.id>`,
  así dos cuentas en el mismo navegador tampoco se mezclan. Si el
  servidor no responde, se usa la caché (modo offline).

**Darte permisos de admin** (SQL Editor):

```sql
insert into public.user_roles (user_id, role_id)
select u.id, r.id
from public.users u, public.roles r
where u.email = 'tu-email@dominio.com' and r.name = 'admin';
```

*(Si el usuario aún no tiene fila en `users`, créala primero desde el
panel con "Crear usuario", o ejecuta el insert de ejemplo incluido en
`003_seed_roles.sql`.)*

## Despliegue — recomendación para la empresa (Hostinger)

**Decisión tomada:** front Flutter + back **Node.js**, todo subible a Hostinger.
Dos rutas posibles (el código es idéntico para las dos):

| | 🅰️ Web Apps gestionado | 🅱️ VPS KVM 1 |
|---|---|---|
| Precio | 3,99 $/mes intro → ~16,99 $ renovación | 6,49 $/mes intro → **11,99 $/mes** renovación |
| Despliegue | subir ZIP o `git push` (hPanel levanta la app) | `docker build` / `pm2` en el server |
| Administra el server | Hostinger | la empresa |
| Front | sitio estático (File Manager) | mismo server (Nginx) |

### 🚀 Subida rápida: un solo comando de build

```powershell
powershell -ExecutionPolicy Bypass -File tool\build.ps1 -ApiUrl https://api.tudominio.com
```

Genera **dos ZIPs listos** en `dist\`:

| ZIP | Contenido | Dónde va en Hostinger |
|---|---|---|
| `kontec-web.zip` | Front compilado (`build\web`) con `.htaccess` SPA incluido | **File Manager → extraer en `public_html`** |
| `kontec-api.zip` | Backend con `dist\` ya compilado (sin `node_modules`) | **App Node de hPanel** (start: `npm start`) o VPS |

El `.htaccess` que incluye el ZIP ya resuelve las rutas de `go_router`
(recargas y enlaces directos tipo `midominio.com/tasks`) en Apache/LiteSpeed
(Hostinger). En el front solo recuerda compilar **siempre** con
`--dart-define=API_URL=https://api.tudominio.com` (el script ya lo hace).

### 1️⃣ Frontend (archivos estáticos)

```powershell
flutter build web --release --dart-define=API_URL=https://api.tudominio.com
```
Subir el contenido de `build\web\` a `/var/www/tudominio.com` (o `public_html`).

⚠️ **Rutas de go_router** → ya resueltas con `web\.htaccess` incluido en el build.
Si algún día usas Nginx a pelo, sería:
```nginx
location / { try_files $uri $uri/ /index.html; }
```

### 2️⃣ Backend (en el VPS)

```bash
git clone <repo> && cd Kontec/server
npm ci && npm run build

# Opción A — PM2 (simple)
npm install -g pm2
pm2 start dist/index.js --name kontec-api
pm2 save && pm2 startup

# Opción B — Docker (usando el Dockerfile incluido)
docker build -t kontec-api .
docker run -d --restart unless-stopped -p 127.0.0.1:3000:3000 kontec-api
```

Reverse proxy en Nginx (el back escucha en `127.0.0.1:3000`, nunca expuesto):
```nginx
server {
  server_name api.tudominio.com;
  location / {
    proxy_pass http://127.0.0.1:3000;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  }
}
```
Certificado SSL: Let's Encrypt (certbot) desde el propio VPS.

### 3️⃣ Checklist antes de producción

- [ ] `flutter build web --dart-define=API_URL=https://api.tudominio.com`
- [ ] Restringir CORS en `server/src/app.ts` al dominio del front
- [ ] Base de datos real (reemplazar `InMemoryTodoRepository` por MySQL/Postgres)
- [ ] `.env` con `PORT` y secretos; `NODE_ENV=production`
- [ ] Backups (VPS) + `pm2` o Docker reiniciando solo

## Test

```powershell
# Frontend (raíz del proyecto)
flutter analyze
flutter test

# Backend Node (dentro de server/)
cd server
npm run typecheck   # TypeScript estricto
npm test            # 6 tests (Vitest + Supertest)
```

La arquitectura permite testear cada capa por separado: en `test/widget_test.dart`
se sustituye el repositorio real por un fake en memoria sin tocar la UI, y en
`server/tests/` se testinga la API completa (rutas + CORS) con Supertest.

## Pendiente / siguientes pasos sugeridos

- [x] Inyección de entorno con `--dart-define=API_URL` (default local `http://localhost:3000`)
- [x] CORS liberado en desarrollo (Edge aislado) y habilitado en el backend
- [x] Backend migrado de Dart Frog a **Node.js + TypeScript** (corre en el hosting
      de la empresa; mismos endpoints, front sin cambios)
- [x] Autenticación (Supabase Auth + guard en el router y en AdminShell)
- [x] **Landing**: cursos y categorías desde la API real (`/courses`, `/categories`)
- [x] **Carrito por usuario**: servidor (`public.carts` + `GET/PUT /cart`) y
      caché local por cuenta; admin ve carritos abandonados y pagos
- [x] Aplicar la migración `sql/004_create_carts.sql` en Supabase
      (aplicada: la tabla `carts` responde en PostgREST y `SUPABASE_DB_URL`
      está en el `.env`; para futuras migraciones: `npm run db:sql -- --migrate`)
- [x] Panel: **aprobar/rechazar** pagos desde "Pagos y carritos"
      (`PATCH /admin/payments/:id` + botones con confirmación; con tests)
- [x] **Aula del curso** (`/capacitaciones/:id/aula`): temario navegable,
      gate de acceso por pago (pending/rejected/none/full), contenido de
      las lecciones y progreso (`PATCH /lessons/:id/progress`)
- [x] **Temario en el panel**: CRUD de módulos y lecciones desde
      Cursos → 📖 (alta, edición, borrado en cascada y reorden)
- [ ] Despliegue en el VPS de Hostinger (guía en "Despliegue — recomendación")
- [x] Restringir CORS al dominio del front en producción
      (vía `CORS_ORIGIN` en `.env`, sin tocar código; sin variable = abierto en dev)
- [x] Manejo de errores global (interceptor en `dioProvider` que traza todo
      fallo de API en `[API ERROR] …`; el mapeo a `Failure` por capa ya existía)
- [ ] Generación de código con `riverpod_generator`/`freezed` si el proyecto crece
- [x] **Android (manifest)**: permiso `INTERNET` en
      `android/app/src/main/AndroidManifest.xml` (¡solo lo tenían debug/profile!)
      y `android:label="Kontec Academy"`
- [ ] **Android (pruebas)**: probar la API desde el emulador con
      `10.0.2.2:3000` (o IP local en móvil físico)
