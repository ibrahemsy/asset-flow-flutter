-- A new administrator may not yet have an Auth identity in the source project.
-- Keep their verified contact email in the private request and link the Auth UUID
-- later when the nominee accepts. This does not create or invite an Auth user.
alter table private.admin_handover_requests
  alter column proposed_admin_id drop not null;
alter table private.admin_handover_requests
  add column if not exists proposed_admin_email text;

create or replace function private.create_admin_handover_request_internal(
  p_proposed_admin_email text,
  p_source_project_ref text,
  p_target_project_ref text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_current_admin uuid := auth.uid();
  v_proposed_admin uuid;
  v_request_id uuid;
  v_email text := lower(trim(coalesce(p_proposed_admin_email, '')));
begin
  if v_current_admin is null or not public.is_app_admin() then
    raise exception 'Only the current system administrator may request a handover'
      using errcode = '42501';
  end if;

  if p_source_project_ref !~ '^[a-z0-9]{20}$'
     or p_target_project_ref !~ '^[a-z0-9]{20}$'
     or p_source_project_ref = p_target_project_ref then
    raise exception 'Invalid or identical Supabase project references'
      using errcode = '22023';
  end if;

  if v_email !~ '^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$' then
    raise exception 'A valid new administrator email is required'
      using errcode = '22023';
  end if;

  select u.id into v_proposed_admin
  from auth.users u
  where lower(u.email) = v_email
  limit 1;

  if v_proposed_admin = v_current_admin then
    raise exception 'The current administrator cannot be the proposed administrator'
      using errcode = '22023';
  end if;

  if exists (
    select 1 from private.admin_handover_requests h
    where h.status in ('pending_current_approval','pending_new_admin_acceptance','approved','executing')
  ) then
    raise exception 'There is already an active administrator handover request'
      using errcode = '23505';
  end if;

  insert into private.admin_handover_requests (
    current_admin_id, proposed_admin_id, proposed_admin_email, status,
    source_project_ref, target_project_ref, current_admin_approved_at, metadata
  ) values (
    v_current_admin, v_proposed_admin, v_email, 'pending_new_admin_acceptance',
    p_source_project_ref, p_target_project_ref, now(),
    jsonb_build_object('proposed_admin_email', v_email,
                       'proposed_admin_registered_in_source', v_proposed_admin is not null,
                       'created_by_current_admin', true)
  )
  returning id into v_request_id;

  return v_request_id;
end;
$$;

revoke all on function private.create_admin_handover_request_internal(text,text,text) from public, anon, authenticated;
grant execute on function private.create_admin_handover_request_internal(text,text,text) to authenticated;
