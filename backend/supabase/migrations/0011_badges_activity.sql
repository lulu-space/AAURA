-- Badge catalog and club activity posts for social feed.

create table if not exists public.badge_definitions (
  id text primary key,
  name text not null,
  description text not null default '',
  icon_key text not null default 'emoji_events',
  locked_by_default boolean not null default false,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.club_activity_posts (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  title text not null,
  body text not null default '',
  icon_key text not null default 'code',
  created_at timestamptz not null default now()
);

create index if not exists idx_club_activity_posts_club on public.club_activity_posts(club_id, created_at desc);

insert into public.badge_definitions (id, name, description, icon_key, locked_by_default, sort_order) values
  ('b-volunteer-champion', 'Volunteer Champion', '50+ volunteer hours completed', 'volunteer_activism', false, 1),
  ('b-peer-mentor', 'Peer Mentor', 'Actively tutored other students', 'school', false, 2),
  ('b-study-streak', 'Study Streak', 'Joined study sessions consistently', 'local_fire_department', false, 3),
  ('b-campus-leader', 'Campus Leader', 'Lead a university initiative', 'workspace_premium', true, 4),
  ('b-top-contributor', 'Top Contributor', 'Earn 2,000 total points', 'emoji_events', true, 5),
  ('b-skill-builder', 'Skill Builder', 'Reach 80% in any tracked skill', 'trending_up', true, 6)
on conflict (id) do nothing;

-- Seed activity posts when matching clubs exist (best-effort).
insert into public.club_activity_posts (id, club_id, title, body, icon_key, created_at)
select
  'a1111111-1111-4111-8111-111111111101'::uuid,
  c.id,
  'Python Hackathon kicks off Feb 10',
  'Final teams have been confirmed. Grab your team badge from the CS lobby on Sunday.',
  'code',
  now() - interval '2 hours'
from public.clubs c
where c.name ilike '%Computer Science%'
on conflict (id) do nothing;

insert into public.club_activity_posts (id, club_id, title, body, icon_key, created_at)
select
  'a1111111-1111-4111-8111-111111111102'::uuid,
  c.id,
  'Clean-Up Day - 20 spaces left',
  'Don''t miss our biggest service event. Service hours auto-logged to your CV.',
  'volunteer',
  now() - interval '1 day'
from public.clubs c
where c.name ilike '%Volunteer%'
on conflict (id) do nothing;

insert into public.club_activity_posts (id, club_id, title, body, icon_key, created_at)
select
  'a1111111-1111-4111-8111-111111111103'::uuid,
  c.id,
  'Cultural Exchange Day open call',
  'Submit your cultural booth idea by next Friday.',
  'culture',
  now() - interval '3 days'
from public.clubs c
where c.name ilike '%Cultural%'
on conflict (id) do nothing;

insert into public.club_activity_posts (id, club_id, title, body, icon_key, created_at)
select
  'a1111111-1111-4111-8111-111111111104'::uuid,
  c.id,
  'Inter-faculty debate sign-ups',
  'Defend your faculty''s honor on Feb 18 - sign-ups inside the club.',
  'debate',
  now() - interval '5 days'
from public.clubs c
where c.name ilike '%Debate%'
on conflict (id) do nothing;
