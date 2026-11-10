-- Migración 012: IMAGEN del plan de membresía.
--
-- membership_plans.image_url: URL pública de la imagen que el admin
-- sube desde el panel (/admin/membresias → sube al bucket "courses"
-- vía /admin/upload-image). La usa la tarjeta de /membresias.
--
-- Idempotente: if not exists.

alter table public.membership_plans
  add column if not exists image_url text;
