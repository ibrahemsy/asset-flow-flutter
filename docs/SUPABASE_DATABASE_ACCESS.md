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

## Current administrator assignment

The Auth user `baselformobile@gmail.com` has been explicitly assigned `primary_admin` in `private.admin_assignments`. The role RPC returned `primary_admin` and `is_app_admin()` returned true for that UID.

A separate test using an unassigned authenticated UID returned a null role, false for admin, and no visible operational or pending-request rows. This verifies the database authorization boundary in SQL; it is not a substitute for a real app sign-in test.

## Client integration status

The active Flutter provider uses Supabase Auth and the Supabase data service. Operational records are serialized into each table's `data` JSONB column, with supported searchable fields also written to normalized snake_case columns.

The main asset, custody, movement, maintenance, phone-directory, telecom-network, audit, and approval-request paths are connected to Supabase. The separate `network_switches` table exists and has RLS policies, but a full switch/port CRUD workflow is not yet connected to the provider/UI.

Google Sheets export is disabled pending a separate Google OAuth setup. Realtime subscriptions are not implemented. Physical barcode and end-to-end app testing remain outstanding.

Do not place SQL service credentials or a Supabase service-role key in the Flutter app. Role provisioning and administrator handover must use a trusted administrative path.
