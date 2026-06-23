-- Inbox read state + message notifications.

alter table public.notifications
  drop constraint if exists notifications_notification_type_check;

alter table public.notifications
  add constraint notifications_notification_type_check
  check (notification_type in (
    'system', 'event', 'study', 'volunteer', 'recommendation', 'message'
  ));

create table if not exists public.peer_direct_message_reads (
  user_id uuid not null references public.users(id) on delete cascade,
  peer_user_id uuid not null references public.users(id) on delete cascade,
  last_read_at timestamptz not null default now(),
  primary key (user_id, peer_user_id),
  check (user_id <> peer_user_id)
);

create index if not exists idx_peer_direct_message_reads_user
  on public.peer_direct_message_reads(user_id, last_read_at desc);

alter table public.peer_direct_message_reads enable row level security;

drop policy if exists peer_direct_message_reads_self on public.peer_direct_message_reads;
create policy peer_direct_message_reads_self on public.peer_direct_message_reads
for all using (user_id = auth.uid())
with check (user_id = auth.uid());
