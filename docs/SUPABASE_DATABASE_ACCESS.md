# Supabase database access model

Project: `cqqibuobtfgoxavskrjp`

## Applied migration

The baseline access/payload migration and the subsequent migrations in `supabase/migrations/` are applied to the connected Supabase project. The repository migration filenames were aligned with the migration versions recorded remotely.

- Added a JSONB `data` payload column to tables whose existing relational columns do not cover the complete Flutter model.
- Kept the existing `devices.data` and `network_switches.data` columns.
- Public `current_app_role()` and `is_app_admin()` are SECURITY INVOKER wrappers with an empty search_path. The narrowly scoped `private.current_app_role_internal()` helper is SECURITY DEFINER, has an empty search_path, and returns only the caller's own assignment. It reads trusted assignments from `private.admin_assignments`; it does not trust email addresses or client-editable metadata.
- Revoked anonymous access to the application tables.
- Provisioned-user reads are allowed; direct operational table writes and audit-log writes are restricted to `primary_admin` / `admin`.
- An authenticated user may create and read their own pending request; only an administrator may review/update requests.

## Current administrator assignment

The Auth user `baselformobile@gmail.com` has been explicitly assigned `primary_admin` in `private.admin_assignments`. The role RPC returned `primary_admin` and `is_app_admin()` returned true for that UID.

A separate test using an unassigned authenticated UID returned a null role, false for admin, and no visible operational or pending-request rows. This verifies the database authorization boundary in SQL; it is not a substitute for a real app sign-in test.

## Client integration status

The active Flutter provider uses Supabase Auth and the Supabase data service. Operational records are serialized into each table's `data` JSONB column, with supported searchable fields also written to normalized snake_case columns.

The main asset, custody, movement, maintenance, phone-directory, telecom-network, audit, and approval-request paths are connected to Supabase. The switch registry is connected end-to-end in the Flutter provider/UI. `network_switches` stores switch records and `network_switch_ports` stores each port separately, optionally referencing `devices.id`. `save_network_switch_with_ports(jsonb,jsonb)` validates admin access, port bounds, duplicate port numbers/device assignments, and device references; it saves the switch and ports atomically as SECURITY INVOKER so table RLS remains effective. The RPC was transaction-tested and rolled back; physical user-session acceptance testing is still required.

Google Sheets export is disabled pending a separate Google OAuth setup. Realtime subscriptions are not implemented. USB keyboard-wedge and camera scanning are implemented in the UI, but physical barcode acceptance testing and real end-to-end app sign-in/CRUD testing remain outstanding.

Do not place SQL service credentials or a Supabase service-role key in the Flutter app. Role provisioning and administrator handover must use a trusted administrative path.
