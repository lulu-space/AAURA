-- AAURA Phase 1: production-grade auth-to-app-user provisioning.
-- Flow:
-- 1. User signs up via Supabase Auth.
-- 2. Supabase creates auth.users.
-- 3. Backend receives the auth user UUID.
-- 4. Backend calls this function to create the application-level user row.
-- 5. Role defaults to student unless later promoted by admin.

create or replace function public.provision_application_user(
  p_user_id uuid,
  p_email text,
  p_full_name text,
  p_university_id text default null,
  p_major text default null,
  p_department text default null,
  p_academic_year int default null
)
returns public.users
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user public.users;
begin
  if not exists (select 1 from auth.users where id = p_user_id) then
    raise exception 'auth user % does not exist', p_user_id;
  end if;

  insert into public.users (
    id,
    email,
    full_name,
    role,
    is_suspended
  )
  values (
    p_user_id,
    p_email,
    p_full_name,
    'student',
    false
  )
  on conflict (id) do update set
    email = excluded.email,
    full_name = excluded.full_name
  returning * into v_user;

  if p_university_id is not null then
    insert into public.students (
      user_id,
      university_id,
      major,
      department,
      academic_year
    )
    values (
      p_user_id,
      p_university_id,
      p_major,
      p_department,
      p_academic_year
    )
    on conflict (user_id) do update set
      university_id = excluded.university_id,
      major = excluded.major,
      department = excluded.department,
      academic_year = excluded.academic_year;
  end if;

  return v_user;
end;
$$;

comment on function public.provision_application_user(uuid, text, text, text, text, text, int)
is 'Backend-only provisioning helper that creates public.users and optional students row after Supabase Auth signup.';
