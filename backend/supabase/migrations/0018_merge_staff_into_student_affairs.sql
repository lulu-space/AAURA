-- Merge legacy staff role into student_affairs.
-- @staff.aaup.edu and @aaup.edu (non-student) both provision as student_affairs.

update public.users
set role = 'student_affairs'
where role = 'staff';

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

  if v_email like '%@staff.aaup.edu' then
    v_role := 'student_affairs';
  elsif v_email like '%@aaup.edu'
        and v_email not like '%@student.aaup.edu'
        and v_email not like '%@staff.aaup.edu' then
    v_role := 'student_affairs';
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

-- Volunteer hour review: student affairs (merged staff role).
drop policy if exists volunteering_self_staff_admin on public.volunteering_records;
create policy volunteering_self_staff_admin on public.volunteering_records
for select using (
  user_id = auth.uid()
  or public.current_app_role() in ('student_affairs', 'dean_of_faculty', 'admin')
);

drop policy if exists volunteering_update_self_staff_admin on public.volunteering_records;
create policy volunteering_update_self_staff_admin on public.volunteering_records
for update using (
  user_id = auth.uid()
  or public.current_app_role() in ('student_affairs', 'dean_of_faculty', 'admin')
)
with check (
  user_id = auth.uid()
  or public.current_app_role() = 'admin'
  or (
    public.current_app_role() in ('student_affairs', 'dean_of_faculty')
    and approved_by_staff_id = auth.uid()
  )
);
