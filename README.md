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
- [ ] Base de datos real (reemplazar `InMemoryTodoRepository` → MySQL/Postgres)
- [ ] Despliegue en el VPS de Hostinger (guía en "Despliegue — recomendación")
- [ ] Restringir CORS al dominio del front en producción
- [ ] Manejo de errores global (dio interceptor → `Failure` + logging)
- [ ] Autenticación (token en interceptores + guard en el router)
- [ ] Generación de código con `riverpod_generator`/`freezed` si el proyecto crece
