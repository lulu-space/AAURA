-- Allow backend (Supabase JS service_role) to call provisioning RPC.
grant execute on function public.provision_application_user(uuid, text, text, text, text, text, int) to service_role;
