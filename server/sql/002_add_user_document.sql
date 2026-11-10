-- Migración 002: documento de identidad del usuario.
-- Ejecutar en Supabase: SQL Editor > New query > pegar > Run.
--
-- El formulario de pago pide DNI/documento; se guarda en el perfil
-- para emitir certificados. (El backend hace fallback automático si
-- esta migración no está aplicada todavía.)

alter table public.users
  add column if not exists document_number text;

comment on column public.users.document_number is
  'DNI / pasaporte / carnet de identidad del estudiante';
