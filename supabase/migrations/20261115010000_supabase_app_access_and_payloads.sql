-- Supabase-only application access control and model payload compatibility.
-- No user is promoted automatically. Access is denied until an operator is explicitly
-- provisioned in private.admin_assignments by a trusted project administrator.

alter table public.custody_cards add column if not exists data jsonb not null default '{}'::jsonb;
alter table public.movements add column if not exists data jsonb not null default '{}'::jsonb;
alter table public.maintenance_tickets add column if not exists data jsonb not null default '{}'::jsonb;
alter table public.phone_directory add column if not exists data jsonb not null default '{}'::jsonb;
alter table public.telecom_networks add column if not exists data jsonb not null default '{}'::jsonb;
alter table public.audit_logs add column if not exists data jsonb not null default '{}'::jsonb;
alter table public.pending_requests add column if not exists data jsonb not null default '{}'::jsonb;
alter table public.network_switches add column if not exists data jsonb not null default '{}'::jsonb;

create or replace function public.current_app_role()
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

create or replace function public.is_app_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (select public.current_app_role()) in ('primary_admin', 'admin'),
    false
  )
$$;

revoke all on function public.current_app_role() from public, anon;
revoke all on function public.is_app_admin() from public, anon;
grant execute on function public.current_app_role() to authenticated;
grant execute on function public.is_app_admin() to authenticated;

-- The API roles can reach the tables, but RLS is the actual authorization boundary.
revoke all on all tables in schema public from anon;
grant select, insert, update, delete on
  public.devices,
  public.custody_cards,
  public.movements,
  public.maintenance_tickets,
  public.phone_directory,
  public.telecom_networks,
  public.audit_logs,
  public.pending_requests,
  public.network_switches
to authenticated;

-- All provisioned application users may read operational records.
do $$
declare
  t text;
begin
  foreach t in array array[
    'devices','custody_cards','movements','maintenance_tickets',
    'phone_directory','telecom_networks','network_switches'
  ] loop
    execute format('drop policy if exists app_members_read on public.%I', t);
    execute format(
      'create policy app_members_read on public.%I for select to authenticated using ((select public.current_app_role()) in (''primary_admin'',''admin'',''operator'',''viewer''))',
      t
    );
    execute format('drop policy if exists app_admin_insert on public.%I', t);
    execute format(
      'create policy app_admin_insert on public.%I for insert to authenticated with check ((select public.is_app_admin()))',
      t
    );
    execute format('drop policy if exists app_admin_update on public.%I', t);
    execute format(
      'create policy app_admin_update on public.%I for update to authenticated using ((select public.is_app_admin())) with check ((select public.is_app_admin()))',
      t
    );
    execute format('drop policy if exists app_admin_delete on public.%I', t);
    execute format(
      'create policy app_admin_delete on public.%I for delete to authenticated using ((select public.is_app_admin()))',
      t
    );
  end loop;
end
$$;

-- A requester may create and read only their own approval requests.
drop policy if exists pending_request_owner_insert on public.pending_requests;
create policy pending_request_owner_insert
  on public.pending_requests for insert to authenticated
  with check (requester_uid = (select auth.uid())::text);

drop policy if exists pending_request_owner_or_admin_read on public.pending_requests;
create policy pending_request_owner_or_admin_read
  on public.pending_requests for select to authenticated
  using (
    requester_uid = (select auth.uid())::text
    or (select public.is_app_admin())
  );

drop policy if exists pending_request_admin_update on public.pending_requests;
create policy pending_request_admin_update
  on public.pending_requests for update to authenticated
  using ((select public.is_app_admin()))
  with check ((select public.is_app_admin()));

drop policy if exists pending_request_admin_delete on public.pending_requests;
create policy pending_request_admin_delete
  on public.pending_requests for delete to authenticated
  using ((select public.is_app_admin()));

-- Audit records are immutable to ordinary users and readable by provisioned staff.
drop policy if exists audit_admin_read on public.audit_logs;
create policy audit_admin_read
  on public.audit_logs for select to authenticated
  using ((select public.current_app_role()) in ('primary_admin','admin','operator','viewer'));

drop policy if exists audit_admin_insert on public.audit_logs;
create policy audit_admin_insert
  on public.audit_logs for insert to authenticated
  with check ((select public.is_app_admin()));

drop policy if exists audit_admin_update on public.audit_logs;
create policy audit_admin_update
  on public.audit_logs for update to authenticated
  using ((select public.is_app_admin()))
  with check ((select public.is_app_admin()));

drop policy if exists audit_admin_delete on public.audit_logs;
create policy audit_admin_delete
  on public.audit_logs for delete to authenticated
  using ((select public.is_app_admin()));

comment on function public.current_app_role() is
  'Returns the trusted role from private.admin_assignments for the authenticated user; no client metadata is trusted.';
comment on function public.is_app_admin() is
  'True only for users provisioned as primary_admin or admin in private.admin_assignments.';
