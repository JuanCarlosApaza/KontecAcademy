-- Migración010: compra de RUTAS (combo) en el carrito y en el checkout.
--
-- * carts.item_type: 'course' (default) | 'path'. Se elimina el FK
--   course_id → courses: una fila de tipo ruta guarda el id de
--   learning_paths. La validación de existencia vive en el repositorio
--   (courses y learning_paths según el tipo).
-- * payments.path_id: un pago de combo referencia la ruta; al
--   aprobarlo, decidePayment aprueba TODOS los enrollments de esa
--   ruta para ese usuario (un solo ticket para el combo).
--
-- Idempotente.

alter table public.carts drop constraint if exists carts_course_id_fkey;

alter table public.carts
  add column if not exists item_type text not null default 'course';

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'carts_item_type_check'
  ) then
    alter table public.carts
      add constraint carts_item_type_check
      check (item_type in ('course', 'path'));
  end if;
end $$;

alter table public.payments
  add column if not exists path_id uuid
  references public.learning_paths(id) on delete set null;
