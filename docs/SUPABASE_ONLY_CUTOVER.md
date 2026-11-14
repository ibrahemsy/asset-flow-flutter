# Supabase-only backend cutover

## Decision

The application backend is Supabase only. Firebase is not an accepted runtime, authentication provider, database, storage provider, or fallback.

Target services:
- Supabase Auth for sign-in, sessions, and account lifecycle.
- Supabase Postgres + Row Level Security for all application records and authorization.
- Supabase Realtime for live updates where required.
- Supabase Storage for uploaded files and images when needed.
- Supabase Edge Functions only for trusted server-side operations that must not run with client privileges.

## Current repository findings (branch: feature/supabase-admin-handover)

The active Flutter code has been switched to Supabase as the sole runtime backend:
- `main.dart` initializes Supabase at startup; Firebase initialization and generated Firebase options were removed.
- `AppProvider` uses Supabase Auth sessions, role RPCs, and Supabase CRUD queries.
- The login screen uses Supabase email/password authentication.
- Firebase packages were removed from `pubspec.yaml`; Firebase service/config source files were deleted.
- The public Supabase publishable key and project URL are used as build-time defaults and can be overridden with `SUPABASE_URL` and `SUPABASE_ANON_KEY`. No service-role key is shipped.
- Operational rows are stored in JSONB `data` alongside selected normalized SQL columns.
- Device form supports USB keyboard-wedge scanner input and has a camera scan action using `mobile_scanner`.
- Google Sheets export is temporarily disabled; Excel export remains available. A separate Google OAuth integration is required before restoring Sheets export.

Still unverified:
- Flutter analyze, tests, Web build, and Android APK build have not yet completed successfully.
- No live end-to-end Auth/RLS/CRUD test has been completed.
- No user has been assigned a trusted administrator role; access remains fail-closed until the project owner provisions a verified Auth UID.
- Realtime subscriptions and physical-device barcode testing remain outstanding.
- The resolved lockfile and the full repository must still be audited for residual Firebase references.

## Cutover rules

1. Do not initialize Firebase in any application entry point.
2. Do not import Firebase packages from application code.
3. Do not keep Firebase as a fallback or dual-write backend.
4. Use Supabase Auth user/session types throughout the application.
5. Keep authorization in Postgres/RLS and trusted server-side code. A client-side email list, user-editable metadata, or a client-supplied role flag is never proof of administrator privileges.
6. Never ship a Supabase service-role/secret key in Web, Android, iOS, or desktop builds. Client apps use the publishable key and rely on RLS.
7. Preserve the existing UI and domain models while replacing the data/auth layer in coherent, testable stages.
8. Do not remove Firebase packages/configuration until all Firebase imports and calls have been replaced and Flutter analyze/tests/build pass. Their removal is a completion step, not a first step.
9. Do not automatically assign either existing Auth user as system administrator. Initial administrator assignment requires an explicit owner decision and a trusted server-side operation.
10. Do not merge this work into the default branch without the repository owner's approval.

## Implementation sequence

- [x] Replace backend configuration with Supabase URL and publishable key build-time defaults; allow build-time overrides.
- [x] Initialize Supabase once at application startup; remove Firebase initialization.
- [x] Refactor AppProvider to Supabase Auth state and Supabase-backed queries; remove Firebase user types.
- [x] Replace Firebase login with Supabase email/password Auth. Google OAuth is not exposed in the login UI.
- [x] Connect devices, custody cards, movements, maintenance tickets, phone directory, telecom networks, audit logs, and pending requests to Supabase. Switch records are not yet wired into AppProvider.
- [ ] Supabase queries are wired; Realtime subscriptions remain to be implemented.
- [ ] Implement role and approval rules in database policies/RPC/Edge Functions, then test both allowed and denied operations.
- [ ] Migrate any required legacy records only after identifying and validating their source; do not silently discard data.
- [x] Remove Firebase direct dependencies, runtime imports, generated configuration, and Firebase service source. Complete repository/lockfile audit remains.
- [ ] Run formatting, static analysis, unit/widget tests, and release builds for Web and supported mobile platforms.

## Verification required before calling the app Supabase-only

- Search the complete repository for Firebase imports, symbols, project configuration, and runtime initialization.
- Confirm no Firebase package remains in the resolved dependency graph.
- Confirm login/logout and session restoration use Supabase Auth.
- Verify RLS with at least an unauthenticated user, a normal authenticated user, and an explicitly provisioned administrator.
- Verify every data module against the live Supabase schema.
- Run Flutter analyze, tests, and Web/Android builds (plus iOS/macOS/Windows builds where toolchains are available).

## Current status

This document records the approved target architecture and the verified starting point. It does not claim that the app has already been converted. The migration is in progress on the feature branch; the default branch remains untouched.
