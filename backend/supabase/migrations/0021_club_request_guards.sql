-- Club request guardrails: normalized names, stronger application fields, unique pending names.

create or replace function public.normalize_entity_name(p_name text)
returns text
language sql
immutable
as $$
  select trim(
    regexp_replace(
      regexp_replace(lower(trim(coalesce(p_name, ''))), '[^a-zA-Z0-9\s]', '', 'g'),
      '\s+',
      ' ',
      'g'
    )
  );
$$;

alter table public.clubs
  add column if not exists normalized_name text;

update public.clubs
set normalized_name = public.normalize_entity_name(name)
where normalized_name is null or normalized_name = '';

alter table public.club_requests
  add column if not exists normalized_name text,
  add column if not exists advisor_email text,
  add column if not exists co_founder_names text[] not null default '{}'::text[];

update public.club_requests
set normalized_name = public.normalize_entity_name(proposed_name)
where normalized_name is null or normalized_name = '';

-- Keep one pending request per normalized name (newest wins); reject older duplicates.
with ranked_pending as (
  select
    id,
    row_number() over (
      partition by normalized_name
      order by created_at desc, id desc
    ) as rn
  from public.club_requests
  where status = 'pending'
    and normalized_name is not null
    and normalized_name <> ''
)
update public.club_requests cr
set
  status = 'rejected',
  review_note = coalesce(nullif(trim(cr.review_note), ''), '')
    || case when nullif(trim(cr.review_note), '') is not null then ' ' else '' end
    || '[auto] Duplicate pending club name; kept the newest request.',
  reviewed_at = coalesce(cr.reviewed_at, now())
from ranked_pending rp
where cr.id = rp.id
  and rp.rn > 1;

create unique index if not exists idx_clubs_normalized_name
  on public.clubs(normalized_name)
  where normalized_name is not null and normalized_name <> '';

create unique index if not exists idx_club_requests_pending_normalized_name
  on public.club_requests(normalized_name)
  where status = 'pending' and normalized_name is not null and normalized_name <> '';

create or replace function public.set_club_normalized_name()
returns trigger
language plpgsql
as $$
begin
  new.normalized_name := public.normalize_entity_name(new.name);
  return new;
end;
$$;

drop trigger if exists trg_clubs_normalized_name on public.clubs;
create trigger trg_clubs_normalized_name
before insert or update of name on public.clubs
for each row execute function public.set_club_normalized_name();

create or replace function public.set_club_request_normalized_name()
returns trigger
language plpgsql
as $$
begin
  new.normalized_name := public.normalize_entity_name(new.proposed_name);
  return new;
end;
$$;

drop trigger if exists trg_club_requests_normalized_name on public.club_requests;
create trigger trg_club_requests_normalized_name
before insert or update of proposed_name on public.club_requests
for each row execute function public.set_club_request_normalized_name();
