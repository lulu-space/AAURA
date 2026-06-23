-- AAURA: extended roles, volunteering opportunities, club activity tracking.

alter type app_role add value if not exists 'student_affairs';
alter type app_role add value if not exists 'dean_of_faculty';
alter type app_role add value if not exists 'club_organizer';

alter table public.clubs
  add column if not exists last_activity_at timestamptz not null default now(),
  add column if not exists inactive_notified_at timestamptz;

create table if not exists public.volunteering_opportunities (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  department text,
  estimated_hours numeric(6,2) not null check (estimated_hours >= 0),
  slots int not null default 1 check (slots > 0),
  status text not null default 'open' check (status in ('open', 'closed')),
  created_by uuid not null references public.users(id) on delete restrict,
  starts_at timestamptz,
  ends_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.volunteering_records
  add column if not exists opportunity_id uuid references public.volunteering_opportunities(id) on delete set null;

create index if not exists idx_volunteering_opportunities_status on public.volunteering_opportunities(status);
create index if not exists idx_volunteering_opportunities_created_by on public.volunteering_opportunities(created_by);
create index if not exists idx_clubs_last_activity on public.clubs(last_activity_at);
create index if not exists idx_volunteering_records_opportunity on public.volunteering_records(opportunity_id);

drop trigger if exists trg_volunteering_opportunities_updated_at on public.volunteering_opportunities;
create trigger trg_volunteering_opportunities_updated_at
before update on public.volunteering_opportunities
for each row execute function public.set_updated_at();
