-- Keep privileged table lookup out of the exposed public schema.
-- Public RPC wrappers are SECURITY INVOKER and delegate only the caller's own role.
create or replace function private.current_app_role_internal()
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select a.role
  from private.admin_assignments as a
  where a.user_id = (select auth.uid())
    and a.revoked_at is null
  limit 1
$$;
revoke all on function private.current_app_role_internal() from public, anon;
grant usage on schema private to authenticated;
grant execute on function private.current_app_role_internal() to authenticated;

create or replace function public.current_app_role()
returns text
language sql
stable
security invoker
set search_path = ''
as $$
  select private.current_app_role_internal()
$$;
create or replace function public.is_app_admin()
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select coalesce((select public.current_app_role()) in ('primary_admin','admin'), false)
$$;
revoke all on function public.current_app_role() from public, anon;
revoke all on function public.is_app_admin() from public, anon;
grant execute on function public.current_app_role() to authenticated;
grant execute on function public.is_app_admin() to authenticated;
