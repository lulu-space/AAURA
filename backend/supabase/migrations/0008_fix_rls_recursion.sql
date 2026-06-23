-- Fix RLS infinite recursion (stack depth limit exceeded on events insert).
-- Cause: events policy calls current_app_role() -> reads users -> users policy
-- called current_app_role() again -> infinite loop.
-- Fix: role helpers bypass RLS; users policies use is_app_admin() only.

create or replace function public.current_app_role()
returns app_role
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  r app_role;
begin
  set local row_security = off;
  select role into r from public.users where id = auth.uid();
  return r;
end;
$$;

create or replace function public.is_app_admin()
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  ok boolean;
begin
  set local row_security = off;
  select exists (
    select 1
    from public.users
    where id = auth.uid()
      and role = 'admin'
  ) into ok;
  return coalesce(ok, false);
end;
$$;

grant execute on function public.current_app_role() to authenticated;
grant execute on function public.current_app_role() to service_role;
grant execute on function public.is_app_admin() to authenticated;
grant execute on function public.is_app_admin() to service_role;

-- users policies must NOT call current_app_role().
drop policy if exists users_select_self_or_admin on public.users;
create policy users_select_self_or_admin on public.users
for select using (id = auth.uid() or public.is_app_admin());

drop policy if exists users_update_self_or_admin on public.users;
create policy users_update_self_or_admin on public.users
for update using (id = auth.uid() or public.is_app_admin())
with check (id = auth.uid() or public.is_app_admin());

drop policy if exists users_insert_self_or_admin on public.users;
create policy users_insert_self_or_admin on public.users
for insert with check (id = auth.uid() or public.is_app_admin());
