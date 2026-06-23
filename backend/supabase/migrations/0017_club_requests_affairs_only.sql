-- Club founding requests are reviewed by Student Affairs (not campus staff).

drop policy if exists club_requests_select_own_or_reviewer on public.club_requests;
create policy club_requests_select_own_or_reviewer on public.club_requests
  for select to authenticated
  using (
    requester_id = auth.uid()
    or public.current_app_role() in ('student_affairs', 'dean_of_faculty', 'admin')
  );

drop policy if exists club_requests_update_reviewer on public.club_requests;
create policy club_requests_update_reviewer on public.club_requests
  for update to authenticated
  using (
    public.current_app_role() in ('student_affairs', 'dean_of_faculty', 'admin')
  )
  with check (
    public.current_app_role() in ('student_affairs', 'dean_of_faculty', 'admin')
  );
