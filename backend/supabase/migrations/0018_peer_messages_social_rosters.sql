-- Direct messages between connected students.

create table if not exists public.peer_direct_messages (
  id uuid primary key default gen_random_uuid(),
  sender_user_id uuid not null references public.users(id) on delete cascade,
  recipient_user_id uuid not null references public.users(id) on delete cascade,
  body text not null check (char_length(trim(body)) >= 1),
  created_at timestamptz not null default now(),
  check (sender_user_id <> recipient_user_id)
);

create index if not exists idx_peer_direct_messages_pair
  on public.peer_direct_messages(sender_user_id, recipient_user_id, created_at);

create index if not exists idx_peer_direct_messages_recipient
  on public.peer_direct_messages(recipient_user_id, created_at desc);

alter table public.peer_direct_messages enable row level security;

drop policy if exists peer_direct_messages_participants on public.peer_direct_messages;
create policy peer_direct_messages_participants on public.peer_direct_messages
for all using (
  sender_user_id = auth.uid() or recipient_user_id = auth.uid()
)
with check (
  sender_user_id = auth.uid()
);
