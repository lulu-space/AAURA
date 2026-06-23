-- Volunteer hours on serve events + link opportunities for QR/join links.

alter table public.events
  add column if not exists volunteer_hours numeric(6,2)
    check (volunteer_hours is null or volunteer_hours >= 0);

alter table public.volunteering_opportunities
  add column if not exists event_id uuid references public.events(id) on delete cascade,
  add column if not exists join_token uuid not null default gen_random_uuid();

create unique index if not exists idx_volunteering_opportunities_event_id
  on public.volunteering_opportunities(event_id)
  where event_id is not null;

create unique index if not exists idx_volunteering_opportunities_join_token
  on public.volunteering_opportunities(join_token);
