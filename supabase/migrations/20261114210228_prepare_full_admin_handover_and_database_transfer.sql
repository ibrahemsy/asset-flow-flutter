-- Internal administrator handover and database transfer metadata.
-- This migration intentionally does not move data, Auth users, Storage objects,
-- project ownership, or revoke any current administrator.
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
grant usage on schema private to service_role;

create table if not exists private.admin_assignments (
  user_id uuid primary key references auth.users(id) on delete restrict,
  role text not null check (role in ('primary_admin','admin','operator','viewer')),
  is_primary_admin boolean not null default false,
  assigned_at timestamptz not null default now(),
  assigned_by uuid references auth.users(id) on delete set null,
  revoked_at timestamptz,
  check ((role = 'primary_admin') = is_primary_admin)
);
create unique index if not exists admin_assignments_one_primary
  on private.admin_assignments (is_primary_admin)
  where is_primary_admin = true;

create table if not exists private.admin_handover_requests (
  id uuid primary key default gen_random_uuid(),
  current_admin_id uuid not null references auth.users(id) on delete restrict,
  proposed_admin_id uuid not null references auth.users(id) on delete restrict,
  status text not null default 'pending_current_approval'
    check (status in ('pending_current_approval','pending_new_admin_acceptance','approved','executing','completed','failed','cancelled')),
  source_project_ref text not null,
  target_project_ref text,
  requested_at timestamptz not null default now(),
  current_admin_approved_at timestamptz,
  new_admin_accepted_at timestamptz,
  completed_at timestamptz,
  failure_reason text,
  metadata jsonb not null default '{}'::jsonb,
  check (current_admin_id <> proposed_admin_id)
);

create table if not exists private.database_transfer_runs (
  id uuid primary key default gen_random_uuid(),
  handover_id uuid references private.admin_handover_requests(id) on delete restrict,
  source_project_ref text not null,
  target_project_ref text not null,
  status text not null default 'prepared'
    check (status in ('prepared','schema_exported','schema_imported','data_copying','data_verified','auth_migrating','storage_migrating','ready_for_cutover','completed','failed','rolled_back')),
  manifest jsonb not null default '{}'::jsonb,
  source_counts jsonb not null default '{}'::jsonb,
  target_counts jsonb not null default '{}'::jsonb,
  checksum text,
  started_at timestamptz not null default now(),
  verified_at timestamptz,
  completed_at timestamptz,
  error_details jsonb not null default '{}'::jsonb
);

create table if not exists private.database_transfer_events (
  id bigint generated always as identity primary key,
  transfer_id uuid not null references private.database_transfer_runs(id) on delete restrict,
  event_type text not null,
  event_details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table private.admin_assignments enable row level security;
alter table private.admin_handover_requests enable row level security;
alter table private.database_transfer_runs enable row level security;
alter table private.database_transfer_events enable row level security;

revoke all on all tables in schema private from public, anon, authenticated;
grant select, insert, update on all tables in schema private to service_role;
grant usage, select on all sequences in schema private to service_role;

comment on schema private is 'Non-exposed internal schema for secure administrator handover and full database transfer workflow. No client-role access.';
