-- BIIN · Fase 1: cuentas con rol, catálogo y obras
-- Pega TODO este archivo en Supabase > SQL Editor > New query y presiona Run.
-- Se puede ejecutar más de una vez sin dañar nada.

-- 1) Perfiles: uno por usuario, con su rol ---------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users on delete cascade,
  email text,
  nombre text not null default '',
  rol text not null default 'cliente' check (rol in ('cliente', 'operacion', 'super_admin')),
  created_at timestamptz not null default now()
);
alter table public.profiles enable row level security;

-- Rol del usuario que hace la consulta (se usa en las políticas)
create or replace function public.mi_rol() returns text
language sql stable security definer set search_path = public
as $$ select rol from public.profiles where id = auth.uid() $$;

-- Crea el perfil al registrarse
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email) values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- Perfiles para usuarios que ya existían
insert into public.profiles (id, email)
select id, email from auth.users on conflict (id) do nothing;

drop policy if exists "perfil: ver el propio o todos si es staff" on public.profiles;
create policy "perfil: ver el propio o todos si es staff" on public.profiles
  for select to authenticated
  using (id = auth.uid() or public.mi_rol() in ('operacion', 'super_admin'));

drop policy if exists "perfil: editar el propio" on public.profiles;
create policy "perfil: editar el propio" on public.profiles
  for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- El usuario solo puede cambiar su nombre; el rol se asigna desde este editor
revoke all on public.profiles from anon, authenticated;
grant select on public.profiles to authenticated;
grant update (nombre) on public.profiles to authenticated;

-- 2) Catálogo: categorías, materiales, bases del cálculo y ajustes ---------
create table if not exists public.configuracion (
  id int primary key default 1 check (id = 1),
  datos jsonb not null,
  updated_at timestamptz not null default now()
);
alter table public.configuracion enable row level security;

drop policy if exists "catalogo: lo lee cualquiera" on public.configuracion;
create policy "catalogo: lo lee cualquiera" on public.configuracion
  for select to anon, authenticated using (true);

drop policy if exists "catalogo: lo crea el super admin" on public.configuracion;
create policy "catalogo: lo crea el super admin" on public.configuracion
  for insert to authenticated with check (public.mi_rol() = 'super_admin');

drop policy if exists "catalogo: lo edita el super admin" on public.configuracion;
create policy "catalogo: lo edita el super admin" on public.configuracion
  for update to authenticated
  using (public.mi_rol() = 'super_admin') with check (public.mi_rol() = 'super_admin');

grant select on public.configuracion to anon, authenticated;
grant insert, update on public.configuracion to authenticated;

-- 3) Obras y cálculos guardados de cada cliente ----------------------------
create table if not exists public.obras (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  nombre text not null,
  ciudad text,
  calculos jsonb not null default '[]',
  created_at timestamptz not null default now()
);
create index if not exists obras_user_id_idx on public.obras (user_id);
alter table public.obras enable row level security;

drop policy if exists "obras: cada quien las suyas" on public.obras;
create policy "obras: cada quien las suyas" on public.obras
  for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "obras: el staff las puede ver" on public.obras;
create policy "obras: el staff las puede ver" on public.obras
  for select to authenticated
  using (public.mi_rol() in ('operacion', 'super_admin'));

grant select, insert, update, delete on public.obras to authenticated;

-- 4) DESPUÉS de crear tu cuenta en la app, conviértela en super administrador.
--    Cambia el correo, quita los dos guiones del inicio y ejecuta solo esta línea:
-- update public.profiles set rol = 'super_admin' where email = 'tu_correo@ejemplo.com';
