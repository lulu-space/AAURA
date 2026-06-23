-- Faculty announcements sent by deans (for history in dean dashboard).

create table if not exists public.faculty_announcements (
  id uuid primary key default gen_random_uuid(),
  dean_user_id uuid not null references public.users(id) on delete cascade,
  faculty text not null,
  title text not null,
  body text not null,
  sent_count int not null default 0 check (sent_count >= 0),
  created_at timestamptz not null default now()
);

create index if not exists idx_faculty_announcements_dean
  on public.faculty_announcements(dean_user_id, created_at desc);
