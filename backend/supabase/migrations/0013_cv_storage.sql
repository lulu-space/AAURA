-- Storage bucket for user-uploaded CVs (PDF). Public-read so the app can open
-- the file via its public URL; writes are restricted to each user's own folder
-- (path must start with `<auth.uid()>/...`).

insert into storage.buckets (id, name, public)
values ('cvs', 'cvs', true)
on conflict (id) do nothing;

drop policy if exists "cv_public_read" on storage.objects;
create policy "cv_public_read"
  on storage.objects for select
  using (bucket_id = 'cvs');

drop policy if exists "cv_owner_insert" on storage.objects;
create policy "cv_owner_insert"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'cvs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "cv_owner_update" on storage.objects;
create policy "cv_owner_update"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'cvs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "cv_owner_delete" on storage.objects;
create policy "cv_owner_delete"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'cvs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
