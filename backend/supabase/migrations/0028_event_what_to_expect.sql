-- Optional student-facing guidance shown on event details.

alter table public.events
  add column if not exists what_to_expect text;

comment on column public.events.what_to_expect is
  'Plain-language summary for students: agenda, what to bring, dress code, etc.';
