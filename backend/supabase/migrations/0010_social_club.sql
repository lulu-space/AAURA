-- Peer connections and club channel messages.

create table if not exists public.peer_connections (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.users(id) on delete cascade,
  addressee_id uuid not null references public.users(id) on delete cascade,
  status text not null default 'accepted' check (status in ('pending', 'accepted', 'blocked')),
  created_at timestamptz not null default now(),
  unique (requester_id, addressee_id),
  check (requester_id <> addressee_id)
);

create table if not exists public.club_messages (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  channel_id text not null default 'general',
  author_user_id uuid not null references public.users(id) on delete cascade,
  body text not null check (char_length(body) >= 1),
  created_at timestamptz not null default now()
);

create index if not exists idx_peer_connections_requester on public.peer_connections(requester_id);
create index if not exists idx_peer_connections_addressee on public.peer_connections(addressee_id);
create index if not exists idx_club_messages_club_channel on public.club_messages(club_id, channel_id, created_at);
