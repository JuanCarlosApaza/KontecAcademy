-- Migración 007: RBAC — catálogo de permisos por módulo:acción.
--
-- El panel admin se autoriza con `requirePermission(codigo)` en lugar
-- del antiguo `requireAdmin` binario. La convención es la que ya usaba
-- la BD sembrada a mano: `modulo:accion` (courses:view, payments:approve…).
--
-- IMPORTANTE: el rol admin NO recibe grants aquí. `getPermissions()`
-- del backend devuelve TODOS los códigos si el usuario tiene el rol
-- admin (bypass calculado), de modo que:
--   * un admin jamás se autobloquea por grants corruptos;
--   * añadir permisos en futuras migraciones no exige tocar `admin`.
--
-- Idempotente: se puede re-ejecutar sin efecto (on conflict do nothing).

-- Roles (admin y student ya están desde 003; teacher desde el seed
-- manual de la BD). Se repiten por si la BD es nueva.
insert into public.roles (name, description) values
  ('admin', 'Administrador del panel'),
  ('student', 'Estudiante / cliente'),
  ('teacher', 'Docente encargado de dictar cursos y responder preguntas')
on conflict (name) do nothing;

-- Catálogo de permisos (los 4 ya sembrados a mano se conservan tal cual).
insert into public.permissions (code, description) values
  ('dashboard:view',    'Ver el resumen (KPIs) del panel'),
  ('students:view',     'Ver estudiantes y sus perfiles'),
  ('students:manage',   'Quitar o restaurar el acceso de un estudiante a un curso'),
  ('payments:view',     'Ver pagos y carritos abandonados'),
  ('categories:edit',   'Crear y renombrar categorías'),
  ('users:view',        'Ver usuarios y sus roles'),
  ('users:create',      'Crear usuarios'),
  ('users:edit',        'Editar usuarios (nombre, rol, estado)'),
  ('roles:manage',      'Gestionar roles y su matriz de permisos')
on conflict (code) do nothing;

-- Permisos por defecto del rol docente: entra al panel (resumen) y
-- administra el temario de sus cursos. Sus grants existentes
-- (courses:view, questions:answer) se conservan.
insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
from public.roles r
join public.permissions p
  on p.code in ('dashboard:view', 'courses:view', 'courses:create')
where r.name = 'teacher'
on conflict do nothing;
