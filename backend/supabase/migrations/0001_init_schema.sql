-- AAURA Phase 1: Core schema for Supabase Postgres
-- Scope: all 20 tables, constraints, indexes, and role utilities.

create extension if not exists pgcrypto;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'app_role') then
    create type app_role as enum ('student', 'staff', 'organizer', 'admin');
  end if;
end $$;

create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique not null,
  full_name text not null,
  role app_role not null default 'student',
  is_suspended boolean not null default false,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Must be defined after public.users exists (Postgres validates SQL function bodies at CREATE time).
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

create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique not null references public.users(id) on delete cascade,
  university_id text unique not null,
  major text,
  department text,
  academic_year int,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.student_profile_drafts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique not null references public.users(id) on delete cascade,
  profile_text text,
  traits jsonb not null default '{}'::jsonb,
  confidence numeric(5,2) not null default 0,
  source text not null default 'manual',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.student_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique not null references public.users(id) on delete cascade,
  profile_summary text,
  strengths jsonb not null default '[]'::jsonb,
  goals jsonb not null default '[]'::jsonb,
  interests jsonb not null default '[]'::jsonb,
  confidence numeric(5,2) not null default 0,
  last_ai_refresh_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  organizer_id uuid not null references public.users(id) on delete restrict,
  title text not null,
  description text,
  location text,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  capacity int not null check (capacity > 0),
  status text not null default 'draft' check (status in ('draft', 'published', 'completed', 'cancelled')),
  is_approved boolean not null default false,
  ai_success_score numeric(5,2),
  ai_engagement_score numeric(5,2),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint events_time_check check (ends_at > starts_at)
);

create table if not exists public.event_reservation (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  reservation_status text not null default 'reserved' check (reservation_status in ('reserved', 'checked_in', 'cancelled')),
  qr_token text unique,
  reserved_at timestamptz not null default now(),
  checked_in_at timestamptz,
  created_at timestamptz not null default now(),
  unique (event_id, user_id)
);

create table if not exists public.event_feedback (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  rating int not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now(),
  unique (event_id, user_id)
);

create table if not exists public.clubs (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  description text,
  organizer_id uuid references public.users(id) on delete set null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.club_membership (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  role text not null default 'member' check (role in ('member', 'lead')),
  joined_at timestamptz not null default now(),
  unique (club_id, user_id)
);

create table if not exists public.volunteering_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  title text not null,
  hours numeric(6,2) not null check (hours >= 0),
  occurred_at timestamptz not null,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  approved_by_staff_id uuid references public.users(id) on delete set null,
  approval_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.recommendations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  source text not null check (source in ('rule_based', 'ai')),
  recommendation_type text not null check (recommendation_type in ('event', 'club', 'study', 'volunteer')),
  target_id uuid,
  reason text,
  score numeric(6,3),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.search_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  query text not null,
  filters jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.engagement_metrics (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  event_id uuid references public.events(id) on delete set null,
  metric_type text not null check (metric_type in ('view', 'click', 'join', 'complete')),
  value numeric(10,2) not null default 1,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.study_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  title text not null,
  goals jsonb not null default '[]'::jsonb,
  schedule jsonb not null default '[]'::jsonb,
  source text not null default 'manual' check (source in ('manual', 'ai')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.calendar (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  title text not null,
  item_type text not null check (item_type in ('event', 'study', 'reminder')),
  starts_at timestamptz not null,
  ends_at timestamptz,
  reference_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.study_sessions (
  id uuid primary key default gen_random_uuid(),
  host_user_id uuid not null references public.users(id) on delete cascade,
  title text not null,
  topic text,
  location text,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  capacity int not null check (capacity > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint study_sessions_time_check check (ends_at > starts_at)
);

create table if not exists public.study_session_membership (
  id uuid primary key default gen_random_uuid(),
  study_session_id uuid not null references public.study_sessions(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  joined_at timestamptz not null default now(),
  unique (study_session_id, user_id)
);

create table if not exists public.gamification (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique not null references public.users(id) on delete cascade,
  points int not null default 0 check (points >= 0),
  level int not null default 1 check (level > 0),
  badges jsonb not null default '[]'::jsonb,
  streak_days int not null default 0 check (streak_days >= 0),
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  title text not null,
  body text not null,
  notification_type text not null check (notification_type in ('system', 'event', 'study', 'volunteer', 'recommendation')),
  is_read boolean not null default false,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.system_logs (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid references public.users(id) on delete set null,
  action text not null,
  resource text not null,
  resource_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  severity text not null default 'info' check (severity in ('info', 'warn', 'error')),
  created_at timestamptz not null default now()
);

create index if not exists idx_users_role on public.users(role);
create index if not exists idx_events_organizer on public.events(organizer_id);
create index if not exists idx_events_starts_at on public.events(starts_at);
create index if not exists idx_event_reservation_event on public.event_reservation(event_id);
create index if not exists idx_event_reservation_user on public.event_reservation(user_id);
create index if not exists idx_volunteering_user on public.volunteering_records(user_id);
create index if not exists idx_recommendations_user on public.recommendations(user_id);
create index if not exists idx_search_history_user on public.search_history(user_id);
create index if not exists idx_engagement_user on public.engagement_metrics(user_id);
create index if not exists idx_study_plans_user on public.study_plans(user_id);
create index if not exists idx_calendar_user on public.calendar(user_id);
create index if not exists idx_study_sessions_host on public.study_sessions(host_user_id);
create index if not exists idx_notifications_user on public.notifications(user_id, is_read);
create index if not exists idx_system_logs_actor on public.system_logs(actor_user_id);
