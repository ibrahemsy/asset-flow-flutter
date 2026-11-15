# Supabase authentication and administrator handover

## Current implementation audit (2026-11-15)

The active Flutter application now uses Supabase as its only runtime backend:

- `main.dart` initializes Supabase; Firebase initialization and Firebase service/config files are absent from the active source tree.
- `AppProvider` uses Supabase Auth sessions, trusted role RPCs, and Supabase CRUD.
- Email/password login is provided by Supabase Auth.
- The application uses the public publishable key only; no service-role key is embedded in the client.
- The connected project has RLS policies on the operational tables. Direct operational writes are restricted to `primary_admin` / `admin`; ordinary provisioned users submit approval requests.
- The Auth account `baselformobile@gmail.com` is assigned `primary_admin` in `private.admin_assignments`. The role RPC and administrator check were tested using that Auth UID.
- An unassigned authenticated test identity receives no application role, no admin permission, and no rows from protected operational/pending-request queries.

## Remaining application verification

- Latest recorded CI run: [Flutter validation #171](https://github.com/ibrahemsy/asset-flow-flutter/actions/runs/43672961220).
- Flutter static analysis and unit/widget tests have passed in that run.
- At the last inspection, the Web release build was running and the Android APK build had not started. Neither downloadable artifact should be considered ready until both build and upload steps succeed.
- A real interactive sign-in with the administrator's password has not been performed from a browser or physical phone in this session.
- USB keyboard-wedge and camera barcode flows still require physical-device/browser testing.
- The switch register CRUD workflow is wired through AppProvider and SupabaseService. Switches and their port mappings are fetched from the relational `network_switch_ports` table; saving a switch and its ports uses one PostgreSQL RPC transaction. Port rows can reference registered inventory devices by `device_id`.
- The RPC validates administrator authorization, switch port bounds, duplicate port numbers, registered device references, and duplicate device assignments. It runs as SECURITY INVOKER so the caller's RLS policies remain in force.
- Realtime subscriptions are not implemented; the current app refreshes data through its load/reload flow.
- Google Sheets export is intentionally disabled until a separate Google OAuth integration is configured.
- USB keyboard-wedge barcode readers and the camera scanner UI are implemented; hardware/browser acceptance testing is still outstanding.

## Switch registry implementation

- `public.network_switches` stores each switch once; a unique case-insensitive index protects non-empty switch numbers.
- `public.network_switch_ports` stores each port independently, with a foreign key to the switch and an optional foreign key to `public.devices`.
- Unique constraints prevent duplicate port numbers on a switch and prevent assigning one device to multiple ports.
- `public.save_network_switch_with_ports(jsonb,jsonb)` saves the switch and complete port list atomically. It is SECURITY INVOKER, checks `auth.uid()` and `public.is_app_admin()`, and relies on table RLS policies for actual writes.
- The app uses the same RPC when an administrator approves a pending switch-save request.
- Switch deletion cascades to its port records.

## Handover lifecycle

- The current administrator creates a request naming the proposed administrator and target project reference.
- The current administrator explicitly approves; the new administrator separately accepts.
- Generate a transfer manifest containing schemas, tables, constraints, indexes, views, functions, triggers, extensions, grants, RLS policies, counts and checksums.
- Transfer schema and data while preserving primary keys and relationships; verify counts and checksums before cutover.
- Transfer Storage buckets and objects separately if present.
- Handle Auth identities using a supported Supabase migration or re-invitation/reset flow. Never copy password hashes, refresh tokens, service-role keys, or secrets through application code.
- Reconfigure Edge Function secrets and OAuth providers separately in the target project.
- Run smoke tests for login, role checks, RLS, CRUD, audit trail, exports and barcode workflows.
- Only after both parties approve the verified cutover, make the new administrator primary and revoke the old administrator's application role. Do not delete the source project as part of the automated workflow.

## Current source-project audit snapshot

- Supabase project ref: `cqqibuobtfgoxavskrjp`.
- The operational tables currently contain zero rows; no legacy asset/custody data has been migrated into this project.
- `baselformobile@gmail.com` is the active `primary_admin` assignment.
- The requested proposed administrator `ferasnatof@gmail.com` was not found in Auth during the latest check.
- The handover metadata tables are internal to the non-exposed `private` schema.
- No target Supabase project has been identified or verified, so a real project/database handover has not been executed.

These are point-in-time findings and must be rechecked immediately before a real transfer.

## Important boundaries

The handover preparation migration adds only internal metadata tables under the non-exposed `private` schema. It does **not** transfer ownership, data, Auth users, Storage objects, secrets, or project billing. The new administrator's Auth account and target project must be verified before any transfer. No administrator has been removed or replaced.
