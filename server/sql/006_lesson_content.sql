-- Migración 006: contenido de lecciones más allá de video.
--  * content_text      → texto de la lección (ej: bienvenida, guía).
--  * attachment_url    → archivo o enlace adjunto (Drive/descarga).
--  * attachment_name   → nombre visible del adjunto.
-- Aplicar: npm run db:sql -- --migrate

alter table public.lessons add column if not exists content_text text;
alter table public.lessons add column if not exists attachment_url text;
alter table public.lessons add column if not exists attachment_name text;
