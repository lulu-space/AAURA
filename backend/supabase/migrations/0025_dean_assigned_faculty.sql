-- Dean of Faculty: scope dashboard and reports to one assigned faculty.

alter table public.users
  add column if not exists assigned_faculty text;

comment on column public.users.assigned_faculty is
  'Faculty scope for dean_of_faculty (Engineering, Business, Arts, Sciences, Medicine, Computer Science).';
