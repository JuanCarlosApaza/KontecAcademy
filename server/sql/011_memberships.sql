-- Migración011: MEMBRESÍAS (3 planes: mensual /6 meses / anual).
--
-- * membership_plans: los tipos de membresía (CRUD desde el panel).
-- * memberships: una fila por usuario con fechas de control
--   (start/end) y estado; 'active' dentro de su vigencia da acceso a
--   TODOS los cursos (los gates de aula/mis cursos lo consultan).
-- * carts: el check de tipos pasa a incluir 'membership'.
-- * payments: membership_id (ticket de la membresía) y enrollment_id
--   pasa a NULLABLE — un ticket de membresía no tiene inscripción.
--
-- Idempotente: todo con if not exists / on conflict / drop-if-exists.

create table if not exists public.membership_plans (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  months int not null,
  price numeric not null default 0,
  is_active boolean not null default true,
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.memberships (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  plan_id uuid not null references public.membership_plans(id),
  -- pending_payment | active | rejected | expired | revoked
  status text not null default 'pending_payment',
  start_date timestamptz,
  end_date timestamptz,
  payment_id uuid references public.payments(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_memberships_user
  on public.memberships(user_id, status);

-- Carrito: el check de tipos gana 'membership' (id = plan_id).
do $$
begin
  alter table public.carts drop constraint if exists carts_item_type_check;
  alter table public.carts
    add constraint carts_item_type_check
    check (item_type in ('course', 'path', 'membership'));
end $$;

-- Pagos: ticket de la membresía.
alter table public.payments
  add column if not exists membership_id uuid
  references public.memberships(id) on delete set null;

-- Un ticket de membresía no tiene inscripción asociada.
alter table public.payments alter column enrollment_id drop not null;

-- Seed:3 planes con precios de EJEMPLO (se editan desde el panel admin).
insert into public.membership_plans (slug, name, months, price, sort_order) values
  ('mensual', 'Mensual', 1, 29, 0),
  ('semestral', 'Semestral (6 meses)', 6, 149, 1),
  ('anual', 'Anual', 12, 249, 2)
on conflict (slug) do nothing;
