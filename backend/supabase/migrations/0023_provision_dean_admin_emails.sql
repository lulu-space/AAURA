-- Email → role at provisioning:
--   @student.aaup.edu     -> student
--   @staff.aaup.edu       -> student_affairs
--   admin@aaup.edu        -> admin (only this address)
--   other *@aaup.edu      -> dean_of_faculty

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
  v_role text := 'student';
  v_email text := lower(trim(p_email));
begin
  if not exists (select 1 from auth.users where id = p_user_id) then
    raise exception 'auth user % does not exist', p_user_id;
  end if;

  if v_email = 'admin@aaup.edu' then
    v_role := 'admin';
  elsif v_email like '%@staff.aaup.edu' then
    v_role := 'student_affairs';
  elsif v_email like '%@aaup.edu'
        and v_email not like '%@student.aaup.edu'
        and v_email not like '%@staff.aaup.edu' then
    v_role := 'dean_of_faculty';
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
    v_role,
    false
  )
  on conflict (id) do update set
    email = excluded.email,
    full_name = excluded.full_name,
    role = excluded.role
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

-- Align existing campus accounts with the new email rules.
update public.users
set role = 'admin'
where lower(trim(email)) = 'admin@aaup.edu';

update public.users
set role = 'dean_of_faculty'
where lower(trim(email)) like '%@aaup.edu'
  and lower(trim(email)) not like '%@student.aaup.edu'
  and lower(trim(email)) not like '%@staff.aaup.edu'
  and lower(trim(email)) <> 'admin@aaup.edu'
  and role in ('student_affairs', 'staff');
