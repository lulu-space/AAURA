-- Study session seat limits are optional (null = open / unlimited).
alter table public.study_sessions
  alter column capacity drop not null;

alter table public.study_sessions
  drop constraint if exists study_sessions_capacity_check;

alter table public.study_sessions
  add constraint study_sessions_capacity_check
  check (capacity is null or capacity > 0);
