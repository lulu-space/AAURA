-- Shareable join links / QR codes for event enrollment.
alter table public.events
  add column if not exists join_token uuid not null default gen_random_uuid();

create unique index if not exists idx_events_join_token
  on public.events(join_token);
