-- Cover foreign-key lookups used by administrator handover and transfer metadata.
create index if not exists idx_admin_assignments_assigned_by
  on private.admin_assignments (assigned_by);
create index if not exists idx_admin_handover_current_admin_id
  on private.admin_handover_requests (current_admin_id);
create index if not exists idx_admin_handover_proposed_admin_id
  on private.admin_handover_requests (proposed_admin_id);
create index if not exists idx_database_transfer_events_transfer_id
  on private.database_transfer_events (transfer_id);
create index if not exists idx_database_transfer_runs_handover_id
  on private.database_transfer_runs (handover_id);
