-- Migración 003: roles base del sistema.
-- Ejecutar en Supabase: SQL Editor > New query > pegar > Run.
--
-- El panel administrativo valida el rol "admin" contra esta tabla.
-- Para dar permisos de admin a un usuario:
--
--   insert into public.user_roles (user_id, role_id)
--   select u.id, r.id
--   from public.users u, public.roles r
--   where u.email = 'tu-email@dominio.com' and r.name = 'admin';

insert into public.roles (name, description)
values
  ('admin', 'Administrador del panel'),
  ('student', 'Estudiante / cliente')
on conflict (name) do nothing;

-- Perfil del admin dueño de la cuenta (ajusta el email al tuyo):
-- insert into public.users (id, email, full_name)
-- select id, email, coalesce(raw_user_meta_data->>'full_name', email)
-- from auth.users
-- where email = 'tu-email@dominio.com'
-- on conflict (id) do nothing;
