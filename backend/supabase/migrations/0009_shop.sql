-- AAURA shop catalog and purchases.

create table if not exists public.shop_items (
  id text primary key,
  title text not null,
  description text not null default '',
  cost int not null check (cost >= 0),
  category text not null check (
    category in ('customizables', 'recognition', 'eventsCampus', 'academic')
  ),
  icon_key text not null default 'shopping_bag',
  tag text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.shop_purchases (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  shop_item_id text not null references public.shop_items(id) on delete restrict,
  points_spent int not null check (points_spent >= 0),
  purchased_at timestamptz not null default now(),
  unique (user_id, shop_item_id)
);

create index if not exists idx_shop_purchases_user on public.shop_purchases(user_id);

drop trigger if exists trg_shop_items_updated_at on public.shop_items;
create trigger trg_shop_items_updated_at
before update on public.shop_items
for each row execute function public.set_updated_at();

insert into public.shop_items (id, title, description, cost, category, icon_key, tag) values
  ('shop-customizable-theme-sunset', 'Sunset Profile Theme', 'Warm gradient and avatar ring for your AAURA profile.', 250, 'customizables', 'palette', 'Bestseller'),
  ('shop-customizable-theme-ocean', 'Ocean Profile Theme', 'Cool blues for the calm ones.', 250, 'customizables', 'water', null),
  ('shop-customizable-frame-gold', 'Gold Avatar Frame', 'Animated gold ring around your avatar.', 400, 'customizables', 'premium', null),
  ('shop-customizable-emoji-pack', 'AAURA Sticker Pack', 'University-themed stickers for chats and study rooms.', 120, 'customizables', 'emoji', null),
  ('shop-recognition-coder', 'CODER Spotlight Badge', 'Premium CODER badge with glow on your CV.', 600, 'recognition', 'code', 'Limited'),
  ('shop-recognition-volunteer', 'Volunteer Star Title', 'Volunteer Star title under your name.', 350, 'recognition', 'volunteer', null),
  ('shop-recognition-leader', 'Campus Leader Cert', 'Certificate of recognition.', 800, 'recognition', 'military_tech', null),
  ('shop-recognition-mentor', 'Peer Mentor Crest', 'Visible on profile and hosted sessions.', 500, 'recognition', 'school', null),
  ('shop-events-coffee', 'Free Cafeteria Coffee', 'Redeem one coffee voucher on campus.', 180, 'eventsCampus', 'coffee', null),
  ('shop-events-priority', 'Event Priority Pass', 'Early access registration for select events.', 420, 'eventsCampus', 'event', null),
  ('shop-academic-voucher', 'Bookstore Voucher', 'Credit toward course materials.', 550, 'academic', 'menu_book', null),
  ('shop-academic-tutor', 'Tutor Session Credit', 'One peer tutoring session credit.', 300, 'academic', 'school', null)
on conflict (id) do nothing;
