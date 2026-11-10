-- 🗄️ Tabla "todos" para la API de Kontec
-- Ejecutar en Supabase: SQL Editor > New query > pegar > Run.

create table if not exists public.todos (
  id         bigint generated always as identity primary key,
  title      text not null,
  completed  boolean not null default false,
  created_at timestamptz not null default now()
);

-- La API usa la Service Role Key, que BYPASSA RLS,
-- por eso basta con deshabilitar RLS (no se expone al navegador).
alter table public.todos disable row level security;
