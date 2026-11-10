-- Migración 005: secciones de la plantilla de landing por curso.
-- Idempotente (puede re-ejecutarse sin efecto).
-- Aplicar: npm run db:sql -- --migrate

alter table public.courses add column if not exists total_weeks integer;
alter table public.courses add column if not exists professor_bio text;
alter table public.courses add column if not exists teaching_method text;
alter table public.courses add column if not exists target_audience text;
alter table public.courses add column if not exists certificate_info text;
alter table public.courses add column if not exists career_opportunities text;
