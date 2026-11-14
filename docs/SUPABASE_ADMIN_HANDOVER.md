# Supabase authentication and administrator handover

## Current implementation audit (2026-11-15)

The Flutter application is **not yet Supabase-first**, despite containing a Supabase service:

- `lib/main.dart` initializes Firebase unconditionally and the root `AuthGate` reads `AppProvider`.
- `AppProvider` subscribes to `FirebaseService.authStateChanges` and routes its CRUD operations through `FirebaseService`.
- `BackendConfig` defaults to Firebase. It persists an administrator email allow-list in local `SharedPreferences`.
- `SupabaseService` has email/password methods and CRUD helpers, but it is not wired into `AppProvider`'s active authentication/data lifecycle.
- `SupabaseService.isSystemAdmin()` currently trusts the local email allow-list. A client-side preference is not an authorization boundary and must not grant administrator permissions.
- The Supabase SQL schema currently creates the business tables but does not establish a complete role model or RLS policies. The live source project audit found RLS enabled on the nine public tables but no policies. This means client access will be denied; do not fix this with permissive public policies.

## Required target architecture

1. Use Supabase Auth as the sole identity provider for both Flutter Web and mobile.
2. Use one shared repository/data layer for both builds; keep platform-specific barcode input behind adapters:
   - Web/desktop: USB HID scanner input behaves as keyboard input; capture focused/scanner input and support manual entry.
   - Mobile: camera scanning via `mobile_scanner`.
3. Put roles in a protected database table (or trusted `app_metadata` set only by trusted server-side code). Never authorize from email strings, `user_metadata`, or local preferences.
4. Enforce every data operation in PostgreSQL RLS. Use narrowly scoped policies for authenticated users and a trusted admin role check. Do not ship a service-role key in Flutter.
5. Put privileged operations (role assignment, approvals, handover execution, migration orchestration) behind authenticated Edge Functions/server-side code. Validate caller identity and current role on every request.
6. Keep audit records append-only and include actor ID, timestamp, action, target, and transfer correlation ID.

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
- Nine public business tables; all currently empty at the time of the audit.
- Two Auth users; identity-to-administrator assignment has not been confirmed.
- No Storage buckets and no Edge Functions were found at audit time.
- 26 custom database functions require definition/signature review before schema transfer.
- No recorded migrations were found before the handover preparation migration.
- No public RLS policies were found, although RLS is enabled on the nine business tables.

These are point-in-time findings and must be rechecked immediately before a real transfer.

## Important boundaries

The handover preparation migration adds only internal metadata tables under the non-exposed `private` schema. It does **not** transfer ownership, data, Auth users, Storage objects, secrets, or project billing. It does not designate either existing Auth user as administrator. The target project has not yet been created, so no cutover is possible yet.
