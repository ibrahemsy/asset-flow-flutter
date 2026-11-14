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

The current application is not yet Supabase-only:
- `main.dart` initializes Firebase unconditionally and only initializes Supabase when a local backend flag enables it.
- `AppProvider` subscribes to Firebase Auth and Firestore streams and calls `FirebaseService` for its CRUD operations.
- The provider exposes `firebase_auth.User` as its current-user type.
- `LoginScreen` calls Google sign-in through the Firebase-backed provider.
- `SupabaseService` exists, but it is not the provider's active data/auth implementation.
- `pubspec.yaml` still includes Firebase Core, Firebase Auth, Cloud Firestore, and Google Sign-In packages.
- `BackendConfig` stores a local administrator email allow-list. This must not be used as an authorization source.

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

- [ ] Replace backend configuration with required Supabase URL and publishable key configuration; fail fast when missing.
- [ ] Initialize Supabase once at application startup; remove Firebase initialization.
- [ ] Refactor AppProvider to Supabase Auth state and Supabase-backed repositories; remove Firebase user types.
- [ ] Replace Google/Firebase login with Supabase Auth. Email/password is the baseline; Google OAuth is optional and must be configured in Supabase Auth before enabling its UI.
- [ ] Move devices, custody cards, movements, maintenance tickets, phone directory, telecom networks, audit logs, pending requests, and switch records to the existing Supabase schema.
- [ ] Replace Firestore streams with Supabase queries and Realtime subscriptions.
- [ ] Implement role and approval rules in database policies/RPC/Edge Functions, then test both allowed and denied operations.
- [ ] Migrate any required legacy records only after identifying and validating their source; do not silently discard data.
- [ ] Remove Firebase packages, imports, generated configuration, and Firebase-specific assets after the codebase is free of Firebase references.
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
