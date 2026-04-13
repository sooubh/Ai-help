# CARE-AI App Stability & Enhancement TODO

## Stability / Bug Prevention
- [ ] Add a global timeout + retry UI for all startup network calls (profile, children, doctor profile) to avoid indefinite splash states.
- [ ] Add Firebase auth stream debounce/throttle protection to avoid duplicate route resolution on quick auth state changes.
- [ ] Add defensive null-safe parsing for all Firestore model deserialization paths and return typed error states instead of throwing.
- [ ] Introduce Crashlytics/Sentry breadcrumbs around startup, notifications, and lifecycle transitions to isolate crash sources faster.

## Loading Performance
- [ ] Lazy-load non-critical services after first frame (voice overlay setup, background sync warm-up) to reduce startup latency.
- [ ] Cache frequently used profile and dashboard documents with stale-while-revalidate strategy for instant first paint.
- [ ] Add performance traces around app launch, auth gating, and home screen data hydration.

## Navigation Reliability
- [ ] Centralize route guards in a dedicated navigation coordinator to prevent divergent logic between named routes and startup resolution.
- [ ] Add argument validation helpers for complex routes (patient detail / assign plan / compose note) and show graceful fallback screens when args are invalid.
- [ ] Add deep-link and notification payload route tests to ensure all payload variants map to valid in-app destinations.

## Test Coverage
- [ ] Add widget tests for authenticated startup for: parent with child, parent without child, doctor complete profile, doctor incomplete profile, and null profile.
- [ ] Add integration test for app lifecycle transitions (pause/resume) validating inactivity reminders and sync triggers.
- [ ] Add regression test ensuring startup never remains on splash beyond timeout without user feedback.

## UX Improvements
- [ ] Add explicit retry button in startup fallback UI with diagnostics details for easier support troubleshooting.
- [ ] Add offline mode indicator when profile resolution falls back to cache-only mode.
