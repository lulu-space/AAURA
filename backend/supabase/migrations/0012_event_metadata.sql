-- Persist event metadata so the UI no longer fakes category/points/targets,
-- and so the success-prediction model can use the real event type + audience.

alter table public.events
  add column if not exists category text not null default 'learn'
    check (category in ('learn', 'serve', 'connect', 'explore')),
  add column if not exists reward_points int not null default 10 check (reward_points >= 0),
  add column if not exists format text not null default 'On-campus',
  add column if not exists promotion_level int not null default 2 check (promotion_level between 1 and 5),
  add column if not exists tags jsonb not null default '[]'::jsonb,
  add column if not exists target_majors jsonb not null default '[]'::jsonb,
  add column if not exists target_years jsonb not null default '[]'::jsonb,
  add column if not exists target_interests jsonb not null default '[]'::jsonb,
  add column if not exists club_id uuid references public.clubs(id) on delete set null;

create index if not exists idx_events_club on public.events(club_id);
create index if not exists idx_events_category on public.events(category);
