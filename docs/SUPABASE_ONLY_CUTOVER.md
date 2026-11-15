# Supabase-only backend cutover

## Decision

The application backend is Supabase only. Firebase is not an accepted runtime, authentication provider, database, storage provider, or fallback.

Target services:
- Supabase Auth for sign-in and sessions.
- Supabase Postgres + Row Level Security for application records and authorization.
- Supabase Realtime for live updates when implemented.
- Supabase Storage for uploaded files and images when needed.
- Supabase Edge Functions only for trusted server-side operations that must not run with client privileges.

## Current repository state

The active Flutter code on `feature/supabase-admin-handover` has been converted to Supabase-only runtime use:

- `main.dart` initializes Supabase at startup.
- `AppProvider` uses Supabase Auth sessions, role RPCs, and Supabase-backed data methods.
- The login screen uses Supabase email/password authentication.
- Firebase dependencies, Firebase imports, Firebase service/config source files, and Firebase platform configuration files are absent from the active project tree.
- The public Supabase publishable key and project URL are build-time defaults and can be overridden with `SUPABASE_URL` and `SUPABASE_ANON_KEY`. No service-role key is shipped.
- Main operational tables store JSONB `data` alongside selected normalized SQL columns.
- Device forms support USB keyboard-wedge input and camera scanning through `mobile_scanner`.
- Google Sheets export is disabled; Excel import/export remains available.
- The account `baselformobile@gmail.com` is explicitly assigned `primary_admin` in the connected Supabase project.

## Verification state

- [x] Supabase startup and email/password auth integration in the Flutter source.
- [x] Firebase direct dependencies and runtime source removed from the active project.
- [x] RLS policies and trusted role RPCs applied to the connected Supabase project.
- [x] Administrator role RPC tested for the assigned Auth UID.
- [x] Unassigned-user RLS test confirms no role/admin rights and no protected rows visible.
- [x] Flutter static analysis passed in CI after updating `file_picker` and its API usage.
- [x] Unit/widget tests passed in CI after the same update.
- [x] Latest CI run #175 completed Flutter static analysis, unit/widget tests, and the Web release build successfully.
- [ ] Android APK release build and artifact upload are still running/pending in CI; do not distribute an APK until the artifact exists.
- [ ] Real interactive login and end-to-end CRUD test in a browser and physical Android device.
- [ ] USB scanner and camera scanning require physical-device/browser testing.
- [ ] Realtime subscriptions are not implemented.
- [x] The independent network-switch/ports register is connected to the Flutter provider/UI. Switch records and port records are read from Supabase; saves use an atomic SECURITY INVOKER RPC and respect RLS.
- [ ] Google Sheets export requires separate Google OAuth configuration.
- [ ] Production Android signing requires a private upload keystore and secure CI secrets; the current release build configuration uses the debug signing key for CI/testing.
- [ ] Administrator handover to a different Supabase project has not been executed; target project and new administrator account must be verified first.

## Cutover rules

1. Do not initialize Firebase in any application entry point.
2. Do not import Firebase packages from application code.
3. Do not keep Firebase as a fallback or dual-write backend.
4. Use Supabase Auth user/session types throughout the application.
5. Keep authorization in Postgres/RLS and trusted server-side code. A client-side email list, user-editable metadata, or client-supplied role flag is never proof of administrator privileges.
6. Never ship a Supabase service-role/secret key in Web, Android, iOS, or desktop builds. Client apps use the publishable key and rely on RLS.
7. Preserve the existing UI and domain models while replacing the data/auth layer in coherent, testable stages.
8. Do not automatically assign a different Auth user as system administrator. Initial or replacement administrator assignment requires an explicit owner decision and a trusted server-side operation.
9. Do not merge this work into the default branch without the repository owner's approval.

## Current status

The Supabase-only source refactor, initial database access controls, and switch/port workflow are in place on the feature branch. CI run #175 has passed static analysis, unit/widget tests, and the Web release build; Android release APK compilation and artifact upload are still pending. The project is not yet a fully production-published application: real interactive sign-in/CRUD checks, USB/camera acceptance testing, production Android signing, and administrator handover to a verified target Supabase project remain outstanding. The default branch remains untouched.
