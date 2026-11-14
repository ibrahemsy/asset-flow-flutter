# Supabase database access model

Project: `cqqibuobtfgoxavskrjp`

## Applied migration

`20261115010000_supabase_app_access_and_payloads.sql` was applied to the connected Supabase project and its policies/functions were verified afterward.

- Added a JSONB `data` payload column to tables whose existing relational columns do not cover the complete Flutter model.
- Kept the existing `devices.data` and `network_switches.data` columns.
- Added `public.current_app_role()` and `public.is_app_admin()` as SECURITY DEFINER functions with an empty search_path. They read trusted assignments from `private.admin_assignments`; they do not trust email addresses or client-editable metadata.
- Revoked anonymous access to the application tables.
- Provisioned-user reads are allowed; direct operational table writes and audit-log writes are restricted to `primary_admin` / `admin`.
- An authenticated user may create and read their own pending request; only an administrator may review/update requests.

## Important onboarding requirement

No initial administrator was assigned by this migration. The Auth users already present in the project must not be promoted automatically. Until an authorized operator explicitly inserts a verified Auth UID into `private.admin_assignments`, application table access is intentionally denied by RLS.

Do not place SQL service credentials or a Supabase service-role key in the Flutter app. Initial role provisioning must be performed through a trusted administrative path (for example, SQL Editor by the project owner or a protected server-side function).

## Client integration status

The active Flutter provider now uses Supabase Auth and the Supabase data service. Operational records are serialized into each table's `data` JSONB column, with the currently supported searchable fields also written to their normalized snake_case columns.

The integration remains subject to successful Flutter analysis/tests/builds and live Auth/RLS/CRUD verification. Realtime subscriptions are not yet implemented. Google Sheets export is disabled pending a separate Google OAuth setup. The app does not provision an administrator automatically; an owner must explicitly assign a verified Auth UID in `private.admin_assignments`.
