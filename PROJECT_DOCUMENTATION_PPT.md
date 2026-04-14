# CARE-AI — Full Deep-Scan Project Documentation (PPT Slide Outline)

## Slide 1 — Title Slide
### Subtitle: Project identity and release metadata
- **Project Name:** CARE-AI (`care_ai`)
- **One-line Description:** AI parenting companion for families supporting children with developmental and physical disabilities.
- **Primary Stack:** Flutter, Firebase, Gemini AI, Provider, Hive, WorkManager.
- **Version:** `1.0.0+1` (from `pubspec.yaml`)
- **Android Package ID:** `com.careai.care_ai`
- **Generated Date:** 2026-04-14

## Slide 2 — Executive Summary
### Subtitle: Product mission, user fit, and technical value
- **Problem solved:** Families need affordable, structured, always-available support for daily caregiving and therapy routines.
- **Target users:**
  - Parent/caregiver users (core end users)
  - Doctor/therapist users (clinical oversight users)
- **Core value proposition:**
  - Personalized AI guidance tied to child profile/context
  - Practical home activity execution and progress tracking
  - Parent-doctor collaboration in one app
- **Technical differentiation:**
  - Gemini text streaming + Gemini Live audio in one architecture
  - Context-enriched prompts from profile, wellness, plan, notes
  - Offline-aware caching and scheduled background reminder flows
- **Current stage:** In-development (feature-rich MVP+/beta state)
- **Key metrics orientation (from project docs):** DAU, retention, activity completion, engagement, satisfaction.

## Slide 3 — Complete Technology Stack
### Subtitle: Frameworks, SDKs, cloud, AI, tooling
- **Frontend Framework:** Flutter (Dart `^3.7.0`)
  - Role: Mobile UI and app logic for Android/iOS.
  - Why: Single codebase and rich widget system.
- **State/DI:** Provider
  - Role: App-level service injection and reactive theme/voice state.
  - Why: Lightweight, straightforward integration with Flutter widgets.
- **Backend/Cloud:** Firebase
  - Auth: Email/password, Google, phone OTP
  - Firestore: Core data model persistence and streams
  - Storage: Media upload and profile images
  - Functions: Auth triggers + secure callable AI operations
  - Messaging: FCM token/topic model
- **AI Stack:**
  - `google_generative_ai`: text assistant, streaming, recommendations
  - Gemini Live via WebSocket: real-time low-latency audio conversation
- **Audio/Voice:**
  - `record`, `flutter_sound`, `speech_to_text`, `flutter_tts`, `audioplayers`
- **Caching/Local:**
  - Hive + SharedPreferences
- **Notifications/Background:**
  - flutter_local_notifications + timezone + WorkManager
- **Security:**
  - encrypt + flutter_secure_storage for client-side field encryption
- **Functions Runtime:**
  - Node 18 + TypeScript + firebase-functions/admin + `@google/generative-ai`

## Slide 4 — System Architecture Overview
### Subtitle: Feature-first modular app with service orchestration
- **Architecture style:** Feature-first presentation + centralized services/repositories.
- **Layer breakdown:**
  - Presentation: `lib/features/**/presentation/*`
  - Core: constants/config/theme/utils
  - Models: typed DTO/domain entities
  - Services: Firebase, AI, notifications, voice, cache, encryption
  - Repository abstraction: cache-aware `SmartDataRepository`, encrypted `ChildRepository`
- **Data flow pattern:**
  - User Action → Screen Controller → Service/Repository → Firebase/Gemini → Mapped Model → UI Update
- **State flow:**
  - Global state via Provider (theme, voice session, services)
  - Local transient state via StatefulWidget + `setState`
- **Route flow:**
  - Auth stream gating at app root
  - Role-aware startup destination resolver
  - Named routes for feature navigation

## Slide 5 — Project File Structure
### Subtitle: Directory-level organization and responsibilities
- **Entry point:** `lib/main.dart`
- **Top-level source folders:**
  - `lib/core`: theme/constants/config/utilities/errors
  - `lib/models`: application data models
  - `lib/services`: integrations and business-side service logic
  - `lib/features`: screen modules by feature domain
  - `lib/widgets`: reusable UI controls
  - `lib/repositories`: data access abstraction (`child_repository.dart`)
- **Backend folder:** `functions/` TypeScript Firebase Functions project
- **Platform folders:** `android/`, `ios/`
- **Tests:** `test/` (widget + service/env scripts)

## Slide 6 — Core App Configuration
### Subtitle: Boot sequence, initialization, and app shell
- `main()` sequence:
  - Flutter binding init
  - dotenv load (if present)
  - global error handlers
  - local cache init (`LocalCacheService.initialize`)
  - Firebase init (`DefaultFirebaseOptions`)
  - Firestore offline persistence config
  - AI service init
  - voice service init
  - notification service init
  - WorkManager init + periodic schedules
  - theme load
  - `runApp` with multi-provider container
- **MaterialApp config:**
  - light/dark themes from `AppTheme`
  - global `navigatorKey`
  - global voice overlay via root `builder` stack
  - auth stream-gated startup home resolution

## Slide 7 — Authentication System
### Subtitle: Methods, routing, lifecycle, and safeguards
- **Supported auth methods:**
  - Email/password
  - Google sign-in
  - Phone OTP verification
  - Password reset email
- **Flow:**
  - Login/Signup
  - User profile role check (`parent` vs `doctor`)
  - Role-based onboarding completion check
  - Destination routing:
    - Parent with no child → parent onboarding
    - Parent with child → home
    - Doctor incomplete profile → doctor onboarding
    - Doctor complete profile → doctor dashboard
- **Session and signout:**
  - Firebase Auth state stream powers startup transitions
  - explicit `signOut` and `deleteAccount` methods

## Slide 8 — Database & Data Layer
### Subtitle: Firestore collections, cache tier, and encrypted fields
- **Primary DB:** Cloud Firestore
- **Key collection patterns:**
  - `users/{uid}` + nested children, chats, plans, logs, milestones, etc.
  - `community_posts`
  - `guidance_notes`
  - `doctor_requests`
  - `doctors`
  - backup/snapshot collections
- **Cache tier:** Hive boxes (`care_ai_data`, `care_ai_meta`, `care_ai_backup`)
- **Cache TTL policy:** per-key durations (e.g., dashboard 1h, context 10m)
- **Repository strategy:**
  - Return fresh cache when valid
  - Fetch remote on stale/miss
  - fallback to stale cache on failure
- **Sensitive field handling:**
  - `EncryptionService` encrypts/decrypts configured child/profile fields

## Slide 9 — Feature Breakdown
### Subtitle: End-user and doctor experiences
- **Parent flow features:**
  - onboarding/auth
  - child profile setup
  - dashboard recommendations
  - AI chat + voice assistant
  - daily plan management
  - therapy modules execution
  - progress and achievements
  - community/wellness/emergency tools
- **Doctor flow features:**
  - doctor onboarding/profile
  - dashboard stats
  - requests/patients tabs
  - patient detail timeline
  - assign plan and send guidance notes
- **Business rule examples:**
  - streak warning only after evening threshold
  - recommendation caching + fallback ranking
  - role mismatch protection on login

## Slide 10 — API & Backend Integration
### Subtitle: Network endpoints, callable functions, and data contracts
- **Cloud Function callables:**
  - `chatWithAI(prompt)` → `{ success, response }`
  - `generateDailyPlan(childId)` → `{ success, plan[] }`
- **Function triggers:**
  - `onUserCreated` initializes user profile document
  - `onUserDeleted` recursive delete of user subtree
- **Client integration wrapper:** `CloudFunctionsService`
- **Error handling pattern:** try/catch + nullable return + UI fallback messaging

## Slide 11 — AI / ML Integration
### Subtitle: Gemini text + recommendations + live voice
- **Text AI service (`AiService`):**
  - model: `gemini-2.5-flash`
  - system prompt guardrails: non-diagnostic support posture
  - streaming token responses
  - tool declaration for app navigation (`perform_app_action`)
  - multimodal image input parts
- **Therapy AI service (`TherapyAiService`):**
  - next-best module recommendations
  - post-completion feedback
  - weekly plan generation
  - skill-gap analysis
  - local fallback responses if AI unavailable
- **Live voice AI (`GeminiLiveService` + `VoiceAssistantService`):**
  - websocket bidi streaming
  - PCM upload/download
  - function call handling for navigation

## Slide 12 — State Management Deep Dive
### Subtitle: Global provider graph and local UI state patterns
- **Global Providers in app root:**
  - `ThemeProvider`
  - `AiService`
  - `VoiceAssistantService`
  - `FirebaseService`
  - `LocalCacheService`
  - `SmartDataRepository`
  - `SyncManager`
- **Local state approach:**
  - feature screens hold view state with `setState`
  - async loaders and refresh indicators per screen
- **Reactive streams used:**
  - auth state (`FirebaseAuth.instance.authStateChanges`)
  - chat/community/guidance notes streams
  - voice message/audio streams

## Slide 13 — UI/UX Architecture
### Subtitle: Theme tokens, component strategy, and interaction model
- **Design system:** central constants (`AppColors`, `AppGradients`, `AppShadows`, `AppAnimations`, `AppStrings`)
- **Theming:**
  - Material 3
  - explicit light and dark theme objects
  - persisted user preference in SharedPreferences
- **Reusable components:** `CustomButton`, `CustomTextField`, `LoadingIndicator`
- **Navigation patterns:**
  - bottom nav (parent and doctor shells)
  - named route pushes
  - modal sheets/dialogs for task flows
- **Motion/feedback:**
  - `flutter_animate` pervasive transitions
  - haptic feedback in key interaction points

## Slide 14 — Monetization Architecture
### Subtitle: Revenue features status
- **Current implementation status:** no subscription, ads, IAP, or payment gateway logic detected.
- **Feature gates:** none tied to paid tier at code level.
- **Recommendation:** if monetization is planned, isolate entitlement logic in dedicated service before adding paywall UI.

## Slide 15 — Notifications & Real-Time Features
### Subtitle: Reminder system and live data behavior
- **Notification service capabilities:**
  - topic subscription
  - token persistence
  - daily reminders
  - streak warnings
  - inactivity reminders (2/5/7 day tasks)
  - periodic progress update background task
- **Realtime data:**
  - Firestore stream-backed chat/community/guidance notes
  - Gemini Live websocket turn-based audio streaming
- **Tap routing:** payload-to-route mapping with `navigatorKey`

## Slide 16 — Security Architecture
### Subtitle: Auth boundaries, rules, encryption, and permissions
- **Auth boundary:** Firebase Auth required for protected user data.
- **Firestore rules:** role and ownership helper functions with read/write constraints.
- **Client-side encryption:** AES encryption service for designated sensitive fields.
- **Permissions:**
  - mic/camera/media read
  - notification/alarm/battery optimization
  - platform usage strings in iOS plist
- **Secret management:**
  - app `.env` / dart-define for Gemini key
  - functions-side `process.env.GEMINI_API_KEY`

## Slide 17 — Performance Considerations
### Subtitle: Caching, streaming, and potential hotspots
- **Implemented performance patterns:**
  - Hive cached reads with TTL
  - repository consolidation to reduce repeated Firestore calls
  - chat message limits (50)
  - PCM queue-based playback to avoid feed overlap
  - noise floor gating for voice mic stream
- **Potential bottlenecks observed:**
  - large screens with extensive animation layers
  - mixed remote/cache operations on startup
  - heavy media operations (thumbnail/keyframe extraction) on UI flow

## Slide 18 — Testing & Code Quality
### Subtitle: Existing tests, linting baseline, and debt indicators
- **Test files present:** widget smoke + AI/env-related tests.
- **Linting config:** `flutter_lints` through `analysis_options.yaml`.
- **Notable technical debt signals:**
  - doctor requests accept/decline UI not persisted
  - iOS Firebase options not configured in generated options file
  - potential dependency drift/unused packages
  - encryption IV reuse design risk
- **CI/CD config:** no `.github` workflow files detected in repository snapshot.

## Slide 19 — Deployment & Release Pipeline
### Subtitle: Build configuration and packaging readiness
- **Android build config:**
  - namespace/appId: `com.careai.care_ai`
  - Java/Kotlin target 17
  - release signing from `key.properties` if present; debug signing fallback
- **iOS config:**
  - AppDelegate includes background task registration and local notif dispatch
  - iOS Firebase options currently unsupported by `firebase_options.dart` generation
- **Functions deployment scripts:**
  - `npm run build`, `npm run serve`, `npm run deploy`

## Slide 20 — Known Issues & Improvement Roadmap
### Subtitle: Observed gaps and immediate priorities
- **Known issues from scan:**
  - Doctor request decisions currently snackbar-only (no backend mutation call in tab action handlers).
  - iOS Firebase platform config missing in generated `DefaultFirebaseOptions`.
  - Some dependencies appear present without in-app usage paths.
  - TODO comment remains in Android gradle about unique application id.
- **Suggested roadmap:**
  - Complete doctor request approval state persistence.
  - Harden Firestore rules on community post update semantics.
  - Improve encryption mode/IV handling.
  - Expand integration and flow-level tests.

## Slide 21 — Glossary of Technical Terms
### Subtitle: Definitions and project-specific usage
- **Provider:** Flutter dependency/state package used for injecting app services globally.
- **Firestore:** NoSQL cloud database used as system-of-record for users, children, logs, notes, and posts.
- **Cloud Function Callable:** Backend function invoked directly from app SDK; used for secured AI calls.
- **Gemini Model:** Google generative AI model for text and structured outputs.
- **Gemini Live:** Real-time websocket interface for low-latency voice conversation.
- **WorkManager:** Background task scheduler used for periodic and delayed reminders.
- **Hive:** Local key-value store used for cached API/data snapshots.
- **TTL:** Time-to-live validity window for cached entries.
- **AES Encryption:** Symmetric cipher used by app for client-side field encryption of sensitive values.
- **FCM:** Firebase Cloud Messaging used for push notification token/topics.

## Slide 22 — Appendix
### Subtitle: Consolidated references
- **Dependency list:** see `pubspec.yaml` and `functions/package.json`.
- **Functions inventory:**
  - `chatWithAI`, `generateDailyPlan`
  - `onUserCreated`, `onUserDeleted`
- **Core model files:** all files in `lib/models/`.
- **Environment/config keys:**
  - `GEMINI_API_KEY` (app)
  - `GEMINI_API_KEY` (functions environment)
- **Primary app routes:** defined in `lib/main.dart` under `routes`.

