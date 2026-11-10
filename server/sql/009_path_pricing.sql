-- Migración009: precio de la ruta con % de rebaja propio.
--
-- El TOTAL de referencia no se guarda: se calcula en el API sumando
-- el precio EFECTIVO de cada curso de la ruta (con oferta aplicada,
-- igual que course_display.dart). `discount_percent` es el % que el
-- admin aplica sobre ese total por adquirir la ruta.
--
-- Idempotente: add column if not exists.

alter table public.learning_paths
  add column if not exists discount_percent int not null default 0;

-- Rango defensivo a nivel de BD (0-100).
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'learning_paths_discount_range'
  ) then
    alter table public.learning_paths
      add constraint learning_paths_discount_range
      check (discount_percent between 0 and 100);
  end if;
end $$;
