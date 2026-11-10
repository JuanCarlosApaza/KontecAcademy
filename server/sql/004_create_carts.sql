-- ==========================================================
-- 11. CARRITO DE COMPRAS POR USUARIO (carritos abandonados)
-- ==========================================================
-- Guarda qué cursos dejó cada usuario en su carrito, para que:
--  * el front sincronice el carrito entre dispositivos, y
--  * el panel admin pueda ver "agregó X pero nunca pagó".
-- El backend (service role) es el ÚNICO que lee/escribe aquí: RLS
-- activo y SIN policies → anon/authenticated NO tienen acceso.
-- Título y precio NO se guardan: se leen de public.courses al
-- consultar, así el carrito siempre muestra los datos vigentes.

create table if not exists public.carts (
  user_id uuid not null references auth.users(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade,
  added_at timestamp with time zone not null default timezone('utc'::text, now()),
  primary key (user_id, course_id)
);

alter table public.carts enable row level security;
