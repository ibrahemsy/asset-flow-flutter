-- Allow the authenticated current administrator to nominate a new manager
-- and enter the destination Supabase project reference from the application.
-- This records a handover request only; it does not copy or delete project data.

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

  if p_proposed_admin_email is null
     or length(trim(p_proposed_admin_email)) < 5
     or position('@' in trim(p_proposed_admin_email)) < 2 then
    raise exception 'A valid new administrator email is required'
      using errcode = '22023';
  end if;

  select u.id into v_proposed_admin
  from auth.users u
  where lower(u.email) = lower(trim(p_proposed_admin_email))
  limit 1;

  if v_proposed_admin is null then
    raise exception 'The proposed administrator must first register in the source project'
      using errcode = 'P0002';
  end if;

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
    current_admin_id, proposed_admin_id, status, source_project_ref,
    target_project_ref, current_admin_approved_at, metadata
  ) values (
    v_current_admin, v_proposed_admin, 'pending_new_admin_acceptance',
    p_source_project_ref, p_target_project_ref, now(),
    jsonb_build_object('proposed_admin_email', lower(trim(p_proposed_admin_email)),
                       'created_by_current_admin', true)
  )
  returning id into v_request_id;

  return v_request_id;
end;
$$;

revoke all on function private.create_admin_handover_request_internal(text,text,text) from public, anon, authenticated;
grant execute on function private.create_admin_handover_request_internal(text,text,text) to authenticated;

create or replace function public.request_admin_handover(
  p_proposed_admin_email text,
  p_source_project_ref text,
  p_target_project_ref text
)
returns uuid
language sql
security invoker
set search_path = ''
as $$
  select private.create_admin_handover_request_internal(
    p_proposed_admin_email, p_source_project_ref, p_target_project_ref
  );
$$;

revoke all on function public.request_admin_handover(text,text,text) from public, anon;
grant execute on function public.request_admin_handover(text,text,text) to authenticated;
