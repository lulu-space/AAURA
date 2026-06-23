-- Platform settings, announcements, and content moderation support for admin.

alter table public.notifications
  drop constraint if exists notifications_notification_type_check;

alter table public.notifications
  add constraint notifications_notification_type_check
  check (notification_type in (
    'system', 'event', 'study', 'volunteer', 'recommendation', 'message', 'announcement'
  ));

create table if not exists public.platform_settings (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.users(id) on delete set null
);

insert into public.platform_settings (key, value) values
  (
    'ai_settings',
    '{"recommendation_weight": 0.65, "prediction_threshold": 0.55, "interest_match_weight": 0.4}'::jsonb
  ),
  (
    'points_rules',
    '{"event_check_in_points": 10, "volunteer_hour_points": 5, "club_join_points": 3}'::jsonb
  ),
  (
    'event_categories',
    '["learn", "serve", "connect", "explore"]'::jsonb
  )
on conflict (key) do nothing;

alter table public.club_messages
  add column if not exists is_hidden boolean not null default false;

alter table public.club_activity_posts
  add column if not exists is_hidden boolean not null default false;

alter table public.events
  add column if not exists is_hidden boolean not null default false;
