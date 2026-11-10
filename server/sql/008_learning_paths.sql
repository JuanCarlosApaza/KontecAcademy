-- Migración 008: Rutas de entrenamiento (learning paths).
--
-- Una "ruta" agrupa cursos ORDENADOS con un nivel por curso
-- (Introductorio | Intermedio | Avanzado). Es informativa: cada curso
-- se compra por su cuenta (no hay checkout de ruta).
--
-- Idempotente: se puede re-ejecutar sin efecto (if not exists +
-- on conflict do nothing).

create table if not exists public.learning_paths (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  title text not null,
  description text not null default '',
  cover_url text,
  -- Modalidad con los mismos códigos crudos que courses.
  modality text not null default 'asynchronous',
  -- Horas totales de la ruta: null = se derivan de la suma de sus cursos.
  duration_hours int,
  access_months int not null default 12,
  sort_order int not null default 0,
  is_published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.path_courses (
  path_id uuid not null references public.learning_paths(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade,
  sort_order int not null default 0,
  level text,
  primary key (path_id, course_id)
);

create index if not exists idx_path_courses_path
  on public.path_courses(path_id, sort_order);

-- ── Seed (idempotente): rutas de ejemplo con cursos reales ─────────
-- Para que /rutas no nazca vacía; se edita/borra desde el panel admin.

insert into public.learning_paths (slug, title, description, modality, sort_order)
values
  ('fundamentos-bim', 'Fundamentos BIM',
   'Da el primer paso en BIM: planificación y gestión4D/5D de proyectos con enfoque práctico.',
   'asynchronous', 0),
  ('estructuras-y-diseno', 'Estructuras y diseño',
   'Ruta de diseño estructural: desde concreto armado hasta detallado de conexiones metálicas.',
   'asynchronous', 1)
on conflict (slug) do nothing;

-- Curso de BIM (si existe en el catálogo).
insert into public.path_courses (path_id, course_id, sort_order, level)
select lp.id, c.id, 0, 'Introductorio'
from public.learning_paths lp
join public.courses c on c.title ilike '%Bim 4D%'
where lp.slug = 'fundamentos-bim'
on conflict do nothing;

-- Ruta de estructuras: concreto armado (primero) y conexiones metálicas.
insert into public.path_courses (path_id, course_id, sort_order, level)
select lp.id, c.id, 0, 'Introductorio'
from public.learning_paths lp
join public.courses c on c.title ilike '%Concreto Armado%'
where lp.slug = 'estructuras-y-diseno'
on conflict do nothing;

insert into public.path_courses (path_id, course_id, sort_order, level)
select lp.id, c.id, 1, 'Intermedio'
from public.learning_paths lp
join public.courses c on c.title ilike '%Conexiones Metálicas%'
where lp.slug = 'estructuras-y-diseno'
on conflict do nothing;
