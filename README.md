# CARE-AI

**AI-Powered Parenting Companion for Children with Disabilities**

CARE-AI is a full-stack Flutter mobile application that empowers parents of children with disabilities through AI-driven guidance, real-time voice assistance, therapeutic activities, game-based learning, and direct integration with healthcare professionals.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Data Models](#data-models)
- [Services](#services)
- [Screens & UI](#screens--ui)
- [Firebase Setup](#firebase-setup)
- [AI Integration](#ai-integration)
- [Caching & Offline Support](#caching--offline-support)
- [Notifications](#notifications)
- [Getting Started](#getting-started)
- [Environment Configuration](#environment-configuration)
- [Running & Building](#running--building)
- [Cloud Functions](#cloud-functions)
- [Contributing](#contributing)

---

## Overview

CARE-AI serves two primary user roles:

- **Parents** — manage child profiles, track progress, run therapy activities and games, consult an AI assistant (text and voice), receive doctor guidance, and follow AI-generated daily plans.
- **Doctors / Therapists** — view assigned patient profiles and activity logs, compose guidance notes, assign therapy plans, and manage connection requests.

The app works fully offline for cached data and syncs seamlessly when connectivity is restored.

---

## Features

### Parent Experience

| Feature | Description |
|---|---|
| AI Text Chat | Streaming Markdown responses from Gemini 2.5 Flash with multimodal image/video support and in-chat app navigation |
| Real-Time Voice Assistant | Live bidirectional PCM audio streaming to Gemini Live API; waveform visualization; global persistent overlay |
| Therapy Activity Library | 30 expert-approved modules across 8 skill categories; step-by-step guided sessions with timer and completion tracking |
| Games Hub | 9 therapeutic games targeting memory, attention, emotional recognition, breathing, and more |
| Daily Plan | AI-generated or manual daily schedule with per-task completion tracking |
| Progress Dashboard | Weekly stats, skill-category charts, 7-day activity history, streak counter |
| Mood & Wellness Tracking | Daily mood check-ins with 14-day trending |
| Emergency Mode | 5-step meltdown calming protocol with guided breathing exercise |
| Community Forum | Real-time posts, likes, and parent community sharing |
| Achievements | Badge system tracking milestones and activity streaks |
| Doctor Integration | Receive guidance notes from assigned therapists; connect/disconnect doctors |
| Multi-Child Support | Manage multiple child profiles under one parent account |
| Notifications | Daily activity reminders, streak warnings, and inactivity nudges |

### Doctor Experience

| Feature | Description |
|---|---|
| Patient Management | View all assigned parents and their children with full profile detail |
| Activity Log Review | Inspect completed therapy sessions, games, and activity history per child |
| Guidance Notes | Compose and send notes directly to the parent's home dashboard |
| Plan Assignment | Assign custom therapy plans to specific children |
| Connection Requests | Review, approve, or decline parent connection requests |
| Doctor Profile | Manage specialization, clinic info, bio, and profile photo |

---

## Tech Stack

### Frontend

| Technology | Version | Purpose |
|---|---|---|
| Flutter | ^3.7.0 | Cross-platform UI framework (Android & iOS) |
| Dart | SDK bundled | Programming language |
| Provider | ^6.1.2 | State management (ChangeNotifier + MultiProvider) |
| Google Fonts (Poppins) | via `google_fonts` | Typography |
| flutter_animate | ^4.5.2 | Declarative UI animations |
| fl_chart | ^0.70.2 | Progress and stats charts |
| shimmer | ^3.0.0 | Loading skeleton effects |
| cached_network_image | ^3.4.1 | Network image caching |
| flutter_markdown | ^0.7.7+1 | Render AI Markdown responses |

### Backend & Cloud

| Technology | Version | Purpose |
|---|---|---|
| Firebase Authentication | latest | Email/password, Google OAuth, phone OTP |
| Cloud Firestore | latest | Primary NoSQL database with offline persistence |
| Firebase Storage | latest | User file uploads (images, videos) |
| Firebase Cloud Messaging | latest | Push notifications |
| Firebase Cloud Functions | ^4.7.0 | Server-side AI calls (`chatWithAI`, `generateDailyPlan`) |
| Firebase Realtime Database | latest | Supplementary real-time data |

### AI

| Technology | Model | Purpose |
|---|---|---|
| Google Generative AI SDK | `gemini-2.5-flash` | Text chat, recommendations, therapy planning |
| Gemini Live API (WebSocket) | `gemini-2.5-flash-native-audio-preview-12-2025` | Real-time bidirectional voice |
| Cloud Functions AI | `gemini-1.5-flash` | Server-side plan generation and chat fallback |

### Audio

| Package | Version | Purpose |
|---|---|---|
| record | ^6.2.0 | PCM16 microphone capture at 16 kHz |
| flutter_sound | ^9.2.13 | Real-time PCM audio playback (Gemini Live responses) |
| audioplayers | ^6.6.0 | General audio playback |
| flutter_tts | ^4.2.0 | Text-to-Speech (en-US, rate 0.45) |
| speech_to_text | ^7.3.0 | On-device Speech-to-Text |

### Storage & Utilities

| Package | Version | Purpose |
|---|---|---|
| Hive + hive_flutter | ^2.2.3 / ^1.1.0 | Local key-value cache (3 boxes) |
| shared_preferences | ^2.3.4 | Theme and notification preferences |
| flutter_dotenv | ^6.0.0 | `.env` file loading at runtime |
| web_socket_channel | ^3.0.0 | Raw WebSocket for Gemini Live |
| connectivity_plus | ^6.1.1 | Online/offline detection |
| permission_handler | ^12.0.1 | Microphone and camera permissions |
| workmanager | ^0.9.0+3 | Background sync tasks |
| uuid | ^4.5.1 | UUID generation |
| intl | ^0.20.2 | Date/time formatting |
| image_picker | ^1.1.2 | Gallery and camera media selection |
| video_player + chewie | ^2.8.7 / ^1.8.1 | In-app video playback |
| url_launcher | ^6.3.1 | Open external links |
| crypto | ^3.0.7 | Data hashing |

---

## Architecture

### Design Pattern

**Feature-First Architecture** — the codebase is organized by feature module rather than by layer. Each feature contains its own `presentation/` directory with screens and widgets. Shared infrastructure lives in `core/`, shared services live in `services/`, and shared models live in `models/`.

```
lib/
├── core/          Shared infrastructure (theme, constants, utils, errors)
├── features/      Feature modules (each with presentation/ subdirectory)
├── models/        Data transfer and domain models
├── services/      Business logic, Firebase, AI, audio, cache
└── widgets/       Reusable global UI components
```

### State Management

Provider with a `MultiProvider` tree at the application root:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider<ThemeProvider>,      // persisted theme
    Provider<AiService>,                         // Gemini text AI
    ChangeNotifierProvider<VoiceAssistantService>, // voice session state
    Provider<FirebaseService>,                   // all Firebase ops
    Provider<LocalCacheService>,                 // Hive cache
    Provider<SmartDataRepository>,               // cache-first data layer
    Provider<SyncManager>,                       // background sync
  ],
)
```

### Application Startup Sequence

```
main() async
 ├── WidgetsFlutterBinding.ensureInitialized()
 ├── dotenv.load(".env")
 ├── Global error handlers (FlutterError, PlatformDispatcher)
 ├── LocalCacheService.initialize()        → open Hive boxes
 ├── Firebase.initializeApp(...)
 ├── Firestore offline persistence enabled (unlimited cache)
 ├── EnvConfig.validate()                  → warn on missing API key
 ├── AiService().initialize()              → create Gemini model + tools
 ├── VoiceAssistantService().initialize()  → mic permission + connectivity
 ├── NotificationService().init()          → FCM + local notifications
 ├── ThemeProvider().loadTheme()           → restore from SharedPreferences
 └── runApp(MultiProvider(...))
```

### Auth Routing

```
StreamBuilder<User?>(FirebaseAuth.authStateChanges)
  ├── (waiting)      → SplashScreen
  ├── (authenticated) → _checkProfileCompletion()
  │     ├── role=parent, profile complete  → /home
  │     ├── role=parent, no profile        → /parent-onboarding
  │     ├── role=doctor, profile complete  → /doctor-dashboard
  │     └── role=doctor, no profile        → /doctor-onboarding
  └── (not signed in) → OnboardingScreen
```

---

## Project Structure

```
d:\project 2\Ai-help\
├── .env                              # Environment variables (GEMINI_API_KEY)
├── pubspec.yaml                      # Flutter dependencies & asset declarations
├── firebase.json                     # Firebase project config (project: ai-help-7)
├── analysis_options.yaml             # Dart linting rules
│
├── lib/
│   ├── main.dart                     # App entry point
│   ├── firebase_options.dart         # Auto-generated Firebase config
│   │
│   ├── core/
│   │   ├── config/
│   │   │   └── env_config.dart       # .env variable access + validation
│   │   ├── constants/
│   │   │   ├── app_animations.dart   # Duration & curve constants
│   │   │   ├── app_colors.dart       # Full color palette (light + dark)
│   │   │   ├── app_gradients.dart    # Gradient definitions
│   │   │   ├── app_shadows.dart      # BoxShadow definitions
│   │   │   └── app_strings.dart      # UI strings, condition lists, labels
│   │   ├── data/
│   │   │   └── therapy_modules_registry.dart  # 30 static therapy modules
│   │   ├── errors/
│   │   │   └── app_exceptions.dart   # Custom exception hierarchy
│   │   ├── theme/
│   │   │   ├── app_theme.dart        # Material 3 light & dark ThemeData
│   │   │   └── theme_provider.dart   # ChangeNotifier for theme switching
│   │   └── utils/
│   │       ├── app_logger.dart       # Structured logging utility
│   │       ├── ui_helpers.dart       # Snackbar, dialog, toast helpers
│   │       └── validators.dart       # Email, password, age validators
│   │
│   ├── features/
│   │   ├── about/presentation/
│   │   │   └── about_screen.dart
│   │   ├── achievements/presentation/
│   │   │   └── achievements_screen.dart
│   │   ├── activities/presentation/
│   │   │   ├── activity_timer_screen.dart
│   │   │   ├── module_detail_screen.dart
│   │   │   ├── modules_library_screen.dart
│   │   │   └── therapy_activity_screen.dart
│   │   ├── auth/presentation/
│   │   │   ├── login_screen.dart
│   │   │   ├── password_reset_screen.dart
│   │   │   ├── phone_otp_screen.dart
│   │   │   └── signup_screen.dart
│   │   ├── chat/presentation/
│   │   │   ├── chat_screen.dart
│   │   │   └── widgets/media_picker_bottom_sheet.dart
│   │   ├── community/presentation/
│   │   │   └── community_screen.dart
│   │   ├── daily_plan/presentation/
│   │   │   └── daily_plan_screen.dart
│   │   ├── doctor/presentation/
│   │   │   ├── assign_plan_screen.dart
│   │   │   ├── compose_guidance_note_screen.dart
│   │   │   ├── doctor_dashboard_screen.dart
│   │   │   ├── doctor_home_tab.dart
│   │   │   ├── doctor_patients_tab.dart
│   │   │   ├── doctor_profile_tab.dart
│   │   │   ├── doctor_requests_tab.dart
│   │   │   ├── patient_detail_screen.dart
│   │   │   └── role_selection_screen.dart
│   │   ├── emergency/presentation/
│   │   │   └── emergency_screen.dart
│   │   ├── games/presentation/
│   │   │   ├── attention_game_screen.dart
│   │   │   ├── breathing_bubble_game_screen.dart
│   │   │   ├── drag_sort_game_screen.dart
│   │   │   ├── emotion_quiz_game_screen.dart
│   │   │   ├── games_hub_screen.dart
│   │   │   ├── memory_match_game_screen.dart
│   │   │   ├── sequence_memory_game_screen.dart
│   │   │   ├── shape_matcher_game_screen.dart
│   │   │   ├── sound_match_game_screen.dart
│   │   │   └── visual_tracker_game_screen.dart
│   │   ├── home/presentation/
│   │   │   └── home_screen.dart
│   │   ├── onboarding/presentation/
│   │   │   ├── doctor_onboarding_screen.dart
│   │   │   ├── onboarding_screen.dart
│   │   │   └── parent_onboarding_screen.dart
│   │   ├── profile/presentation/
│   │   │   ├── full_profile_screen.dart
│   │   │   └── profile_setup_screen.dart
│   │   ├── progress/presentation/
│   │   │   └── progress_screen.dart
│   │   ├── report/presentation/
│   │   │   └── doctor_report_screen.dart
│   │   ├── settings/presentation/
│   │   │   └── settings_screen.dart
│   │   ├── voice/presentation/
│   │   │   ├── global_voice_overlay.dart
│   │   │   └── voice_assistant_screen.dart
│   │   └── wellness/presentation/
│   │       └── wellness_screen.dart
│   │
│   ├── models/
│   │   ├── achievement_model.dart
│   │   ├── activity_log_model.dart
│   │   ├── chat_message_model.dart
│   │   ├── child_profile_model.dart
│   │   ├── doctor_model.dart
│   │   ├── game_session_model.dart
│   │   ├── guidance_note_model.dart
│   │   ├── post_model.dart
│   │   ├── recommendation_model.dart
│   │   ├── therapy_module_model.dart
│   │   ├── therapy_session_model.dart
│   │   ├── user_event_model.dart
│   │   ├── user_model.dart
│   │   └── voice_session_model.dart
│   │
│   ├── services/
│   │   ├── ai_service.dart
│   │   ├── cloud_functions_service.dart
│   │   ├── context_builder_service.dart
│   │   ├── firebase_service.dart
│   │   ├── gemini_live_service.dart
│   │   ├── notification_service.dart
│   │   ├── pcm_audio_player.dart
│   │   ├── permission_service.dart
│   │   ├── therapy_ai_service.dart
│   │   ├── tts_service.dart
│   │   ├── voice_assistant_service.dart
│   │   └── cache/
│   │       ├── local_cache_service.dart
│   │       ├── smart_data_repository.dart
│   │       └── sync_manager.dart
│   │
│   └── widgets/
│       ├── custom_button.dart
│       ├── custom_text_field.dart
│       └── loading_indicator.dart
│
├── functions/                        # Firebase Cloud Functions
│   ├── package.json
│   ├── tsconfig.json
│   └── src/
│       ├── index.ts                  # Function exports
│       ├── callables/ai.ts           # chatWithAI & generateDailyPlan
│       └── triggers/auth.ts          # onUserCreated & onUserDeleted
│
├── assets/
│   ├── images/
│   ├── icons/
│   └── animations/
│
├── android/                          # Android platform project
│   └── app/src/main/kotlin/com/careai/care_ai/MainActivity.kt
│
└── ios/                              # iOS platform project
```

---

## Data Models

### UserModel — `lib/models/user_model.dart`

Represents an authenticated app user (parent or doctor).

| Field | Type | Description |
|---|---|---|
| `uid` | `String` | Firebase Auth UID |
| `email` | `String` | User email address |
| `displayName` | `String` | Full name |
| `role` | `String` | `"parent"` or `"doctor"` |
| `photoUrl` | `String?` | Profile photo URL |
| `fcmToken` | `String?` | Firebase Cloud Messaging token |
| `createdAt` | `DateTime` | Account creation timestamp |
| `lastLoginAt` | `DateTime` | Last login timestamp |

**Firestore path:** `users/{uid}`

---

### ChildProfileModel — `lib/models/child_profile_model.dart`

Detailed profile for a child managed by a parent.

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Unique profile ID |
| `name` | `String` | Child's full name |
| `age` | `int` | Age in years |
| `gender` | `String` | Child's gender |
| `conditions` | `List<String>` | Diagnosed conditions (ASD, ADHD, CP, Down Syndrome, etc.) |
| `communicationLevel` | `String` | Communication ability level |
| `behavioralConcerns` | `List<String>` | Specific behavioral flags |
| `sensoryIssues` | `List<String>` | Sensory sensitivities |
| `motorSkillLevel` | `String` | Fine/gross motor skill assessment |
| `learningAbilities` | `List<String>` | Learning strengths |
| `parentGoals` | `List<String>` | Goals set by parent |
| `currentTherapyStatus` | `String` | Active, completed, not started |
| `medicalNotes` | `String?` | Free-text medical context |
| `relationship` | `String` | Parent's relationship to child |
| `photoUrl` | `String?` | Child's photo URL |
| `completedModuleIds` | `List<String>` | IDs of completed therapy modules |
| `createdAt` | `DateTime` | Profile creation timestamp |
| `updatedAt` | `DateTime` | Last update timestamp |

**Firestore path:** `users/{uid}/children/{childId}`

---

### DoctorModel — `lib/models/doctor_model.dart`

Professional profile for a doctor/therapist user.

| Field | Type | Description |
|---|---|---|
| `id` | `String` | User UID |
| `name` | `String` | Doctor's full name |
| `email` | `String` | Contact email |
| `specialization` | `String` | Medical specialization |
| `clinicName` | `String` | Clinic or hospital name |
| `photoUrl` | `String?` | Profile photo URL |
| `phone` | `String?` | Contact phone |
| `bio` | `String?` | Professional biography |
| `assignedPatientIds` | `List<String>` | Connected parent UIDs |

**Firestore path:** `users/{uid}` (role = `"doctor"`)

---

### ChatMessageModel — `lib/models/chat_message_model.dart`

A single message in the AI text chat.

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Message UUID |
| `message` | `String` | Text content |
| `sender` | `String` | `"user"` or `"ai"` |
| `timestamp` | `DateTime` | Message timestamp |
| `imagePath` | `String?` | Attached image URL or local path |

**Firestore path:** `users/{uid}/chats/{messageId}`

---

### ActivityLogModel — `lib/models/activity_log_model.dart`

Record of a completed therapy activity or game session.

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Log UUID |
| `activityId` | `String` | ID of the activity or game |
| `activityTitle` | `String` | Display name |
| `category` | `String` | Skill category |
| `durationSeconds` | `int` | Time spent in seconds |
| `stepsCompleted` | `int` | Number of steps completed |
| `completedAt` | `DateTime` | Completion timestamp |

**Firestore path:** `users/{uid}/activity_logs/{logId}`

---

### TherapyModuleModel — `lib/models/therapy_module_model.dart`

A therapy activity module from the static library.

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Module identifier |
| `title` | `String` | Activity title |
| `objective` | `String` | Learning objective |
| `conditionTypes` | `List<String>` | Target conditions |
| `ageRange` | `String` | Recommended age range |
| `skillCategory` | `String` | Skill domain |
| `difficultyLevel` | `int` | 1 (easiest) to 5 (hardest) |
| `materials` | `List<String>` | Required materials |
| `instructions` | `List<String>` | Step-by-step instructions |
| `durationMinutes` | `int` | Estimated duration |
| `safetyNotes` | `String?` | Safety considerations |
| `expectedOutcomes` | `List<String>` | Measurable outcomes |
| `targetSkills` | `List<String>` | Skills this module trains |
| `prerequisites` | `List<String>` | Module IDs to complete first |
| `activityType` | `String` | Activity format |
| `iconName` | `String` | Icon identifier |
| `mediaUrls` | `List<String>` | Supporting media |
| `isExpertApproved` | `bool` | Expert review flag |
| `createdBy` | `String` | Author identifier |
| `adaptiveDifficultyEnabled` | `bool` | Whether AI can adjust difficulty |

**Source:** `lib/core/data/therapy_modules_registry.dart` (30 static modules)

---

### TherapySessionModel — `lib/models/therapy_session_model.dart`

Performance record from a completed therapy module session.

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Session UUID |
| `moduleId` | `String` | Completed module ID |
| `moduleTitle` | `String` | Module display name |
| `skillCategory` | `String` | Skill domain |
| `difficultyLevel` | `int` | Module difficulty |
| `score` | `int` | Points earned |
| `maxScore` | `int` | Maximum possible points |
| `accuracyPercent` | `double` | Accuracy percentage |
| `timeSpentSeconds` | `int` | Session duration |
| `stepsCompleted` | `int` | Steps finished |
| `totalSteps` | `int` | Total steps in module |
| `engagementRating` | `int` | Parent-rated engagement (1-5) |
| `aiFeedback` | `String?` | AI-generated feedback text |
| `nextRecommendedModuleIds` | `List<String>` | AI-suggested next modules |
| `performanceMetrics` | `Map<String, dynamic>` | Additional metrics |
| `completedAt` | `DateTime` | Completion timestamp |

**Firestore path:** `users/{uid}/therapy_sessions/{sessionId}`

---

### GameSessionModel — `lib/models/game_session_model.dart`

Performance record from a completed therapeutic game.

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Session UUID |
| `gameType` | `String` | Game identifier |
| `skillCategory` | `String` | Targeted skill |
| `difficultyLevel` | `int` | Difficulty at time of play |
| `score` | `int` | Final score |
| `maxScore` | `int` | Maximum score |
| `totalMoves` | `int` | Number of moves/interactions |
| `durationSeconds` | `int` | Time in game |
| `completedAt` | `DateTime` | Completion timestamp |
| `additionalMetrics` | `Map<String, dynamic>` | Game-specific data |

**Firestore path:** `users/{uid}/game_sessions/{sessionId}`

---

### GuidanceNoteModel — `lib/models/guidance_note_model.dart`

A note composed by a doctor and sent to a parent's home screen.

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Note UUID |
| `doctorId` | `String` | Sending doctor's UID |
| `doctorName` | `String` | Doctor's display name |
| `childId` | `String` | Target child profile ID |
| `title` | `String` | Note title |
| `content` | `String` | Note body text |
| `createdAt` | `DateTime` | Creation timestamp |
| `isRead` | `bool` | Parent read status |

**Firestore path:** `guidance_notes/{noteId}`

---

### RecommendationModel — `lib/models/recommendation_model.dart`

An AI-generated daily activity recommendation.

| Field | Type | Description |
|---|---|---|
| `id` | `String` | UUID |
| `title` | `String` | Recommended activity title |
| `duration` | `String` | Suggested duration |
| `objective` | `String` | Activity objective |
| `reason` | `String` | Why this was recommended |
| `createdAt` | `DateTime` | Generation timestamp |
| `expiresAt` | `DateTime` | Expiry (next midnight) |

---

### PostModel — `lib/models/post_model.dart`

A community forum post.

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Post ID |
| `authorId` | `String` | Author UID |
| `authorName` | `String` | Display name |
| `content` | `String` | Post body |
| `likes` | `List<String>` | UIDs who liked this post |
| `createdAt` | `DateTime` | Post timestamp |

**Firestore path:** `community_posts/{postId}`

---

### AchievementModel — `lib/models/achievement_model.dart`

A user achievement badge.

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Achievement identifier |
| `title` | `String` | Display title |
| `description` | `String` | Achievement description |
| `iconData` | `IconData` | Badge icon |
| `isUnlocked` | `bool` | Whether earned |
| `unlockedAt` | `DateTime?` | When earned |

**Firestore path:** `users/{uid}/achievements/{achievementId}`

---

### VoiceSessionModel — `lib/models/voice_session_model.dart`

Ephemeral in-memory voice session state (not persisted).

| Field | Type | Description |
|---|---|---|
| `sessionId` | `String` | Session UUID |
| `mode` | `String` | `"continuous"` or `"pushToTalk"` |
| `status` | `String` | `idle`, `listening`, `processing`, `speaking`, `paused`, `error` |
| `startedAt` | `DateTime` | Session start time |
| `lastActivityAt` | `DateTime` | Last audio activity |
| `messageCount` | `int` | Total exchanges in session |
| `errorMessage` | `String?` | Last error if in error state |

---

### UserEventModel — `lib/models/user_event_model.dart`

Analytics event for in-app tracking.

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Event UUID |
| `eventType` | `String` | Event category |
| `screenName` | `String` | Source screen |
| `metadata` | `Map<String, dynamic>` | Additional event data |
| `timestamp` | `DateTime` | Event timestamp |

**Firestore path:** `users/{uid}/events/{eventId}`

---

## Services

### AiService — `lib/services/ai_service.dart`

Manages all Gemini text-based AI interactions.

- **Model:** `gemini-2.5-flash` via `google_generative_ai` SDK
- **Function Tools:** `perform_app_action` — allows AI to trigger in-app navigation
- **Safety Settings:** MEDIUM threshold for harassment, hate speech, dangerous content; HIGH for sexually explicit
- **System Prompt:** CARE-AI persona with child-profile context, formatting rules, navigation tool declaration
- **Streaming:** Uses `generateContentStream` for live Markdown rendering
- **Multimodal:** Accepts inline image data (base64) in messages

Key methods:
```dart
Future<void> initialize()
Stream<String> sendMessage(String message, {List<Content>? history, String? imagePath})
Future<List<RecommendationModel>> generateRecommendations(ChildProfileModel child)
```

---

### FirebaseService — `lib/services/firebase_service.dart`

Centralized service (~1000+ lines) for all Firebase operations. Includes in-memory caching for frequently accessed data.

**Authentication:**
- `signInWithEmail`, `signUpWithEmail`
- `signInWithGoogle`
- `signInWithPhone`, `verifyPhoneOtp`
- `sendPasswordReset`
- `deleteAccount` (cascades all user data)

**Profile Management:**
- `createUserProfile`, `getUserProfile`, `updateUserProfile`
- `createChildProfile`, `getChildProfiles`, `updateChildProfile`, `deleteChildProfile`
- `uploadProfilePhoto` (Firebase Storage, 5MB limit)

**Activity & Sessions:**
- `logActivity` — saves `ActivityLogModel`
- `saveTherapySession` — saves `TherapySessionModel`
- `saveGameSession` — saves `GameSessionModel` and `ActivityLogModel`

**Stats & Progress:**
- `getWeeklyStats` — activity count, minutes, streak
- `getSkillProgress` — skill-category breakdown
- `getDailyActivityCounts` — 7-day bar chart data

**Chat:**
- `saveChatMessage`, `getChatHistory`

**Daily Plan:**
- `saveDailyPlan`, `getDailyPlan`

**Doctor Features:**
- `sendGuidanceNote`, `getGuidanceNotes`
- `createDoctorRequest`, `getDoctorRequests`, `updateRequestStatus`
- `getAllParentUsers`, `getChildrenForParent`
- `assignPlanToChild`, `getActivityLogsForChild`

**Community:**
- `getCommunityPosts`, `createPost`, `toggleLikePost`

**Wellness:**
- `saveMoodCheckin`, `getMoodHistory`

**Achievements:**
- `getAchievements`, `unlockAchievement`

---

### GeminiLiveService — `lib/services/gemini_live_service.dart`

Raw WebSocket client for the Gemini Live API.

- **WebSocket URL:** `wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key={API_KEY}`
- **Model:** `gemini-2.5-flash-native-audio-preview-12-2025`
- **Input:** PCM16 audio at 16 kHz, base64-encoded as `audio/pcm;rate=16000`
- **Output:** PCM audio at 24 kHz via base64 `inlineData`
- **Messages handled:** `setupComplete`, `turnComplete`, `interrupted`, `toolCall`

Key methods:
```dart
Future<void> connect(String systemInstruction)
Future<void> sendAudioChunk(Uint8List pcmData)
Future<void> sendTextMessage(String text)
Stream<Uint8List> get audioStream
Stream<String> get toolCallStream
Future<void> disconnect()
```

---

### VoiceAssistantService — `lib/services/voice_assistant_service.dart`

ChangeNotifier that orchestrates the complete voice session lifecycle.

- Opens microphone at 16 kHz PCM16 via `record`
- Streams audio chunks to `GeminiLiveService`
- Receives PCM audio responses and routes to `PcmAudioPlayer`
- Tracks `VoiceSessionModel` state (idle → listening → processing → speaking)
- Exposes waveform amplitude stream for UI visualization
- Context refreshed every 5 minutes via `ContextBuilderService`
- Handles `perform_app_action` tool calls for voice-commanded navigation
- Stops session automatically when offline

Key methods:
```dart
Future<void> initialize()
Future<void> startSession()
Future<void> stopSession()
Future<void> pauseListening()
Future<void> resumeListening()
Stream<double> get amplitudeStream
VoiceSessionModel? get currentSession
```

---

### PcmAudioPlayer — `lib/services/pcm_audio_player.dart`

Queue-based sequential PCM audio playback using `flutter_sound`.

- Plays 24 kHz PCM audio chunks received from Gemini Live
- Queues chunks to prevent buffer overlap and audio stuttering
- Handles start/stop/flush for session boundaries

---

### TherapyAiService — `lib/services/therapy_ai_service.dart`

Gemini-powered therapy intelligence layer.

- **Next Module Recommendations:** Analyzes completed modules and child profile to suggest the best next activity
- **Post-Session Feedback:** Generates personalized feedback after a therapy session
- **Difficulty Adjustment:** Suggests difficulty changes based on performance patterns
- **Weekly Plan Generation:** Creates a full 7-day therapy activity schedule
- **Skill-Gap Analysis:** Identifies under-trained skill categories

Uses JSON response mode for structured output.

---

### ContextBuilderService — `lib/services/context_builder_service.dart`

Builds the rich context string injected into voice AI sessions.

Includes:
- Child profile (name, age, conditions, communication level, goals)
- Recent mood history (last 7 entries)
- Today's daily plan
- Weekly activity stats (count, minutes, streak)
- Latest guidance note from therapist

Cached for 10 minutes to avoid redundant Firebase reads.

---

### LocalCacheService — `lib/services/cache/local_cache_service.dart`

Hive-backed local cache with TTL management.

**Hive Boxes:**
- `care_ai_data` — primary cache data
- `care_ai_meta` — expiry timestamps per key
- `care_ai_backup` — backup snapshot

**Cache Keys and TTLs:**

| Cache Key | TTL | Contents |
|---|---|---|
| `user_profile` | 24 hours | UserModel |
| `children_list` | 6 hours | List of ChildProfileModel |
| `weekly_stats` | 1 hour | Activity count, minutes, streak |
| `skill_progress` | 2 hours | Skill-category breakdown |
| `daily_activity_counts` | 2 hours | 7-day activity counts |
| `mood_history` | 6 hours | Last 14 mood entries |
| `guidance_notes` | 30 minutes | Latest doctor notes |
| `recommendations` | Until midnight | AI daily recommendations |
| `daily_plan` | 1 hour | Today's plan |
| `activity_logs` | 30 minutes | Recent activity logs |
| `therapy_sessions` | 1 hour | Therapy session history |
| `community_posts` | 5 minutes | Latest 50 community posts |
| `bookmarks` | 2 hours | Bookmarked module IDs |
| `voice_context` | 10 minutes | Pre-built voice AI context string |

Key methods:
```dart
Future<T?> get<T>(String key)
Future<void> set(String key, dynamic value, {Duration? ttl})
Future<bool> isExpired(String key)
Future<void> invalidate(String key)
Future<void> backup()
Future<void> restore()
```

---

### SmartDataRepository — `lib/services/cache/smart_data_repository.dart`

Cache-first data access layer sitting in front of `FirebaseService`.

- Returns cached data immediately when available and fresh
- Fetches from Firebase on cache miss or expiry
- Returns stale cached data when offline
- Computes derived stats (weekly stats, skill progress, daily counts) locally from raw activity logs when possible

---

### SyncManager — `lib/services/cache/sync_manager.dart`

Background synchronization coordinator.

- **Hourly sync:** Refresh all cache keys from Firebase
- **6-hourly backup:** Write Hive cache snapshot to `care_ai_backup` box
- **24-hourly snapshot:** Push daily user data summary to Firestore `user_daily_snapshots/{uid}/{date}`
- **Connectivity-triggered:** Runs a full sync whenever the device comes back online (after being offline)

---

### NotificationService — `lib/services/notification_service.dart`

Singleton managing both FCM push and local notifications.

**FCM topics subscribed:**
- `daily_reminders`
- `progress_updates`

**Local notifications scheduled:**
- Daily reminder at configurable time (default 9:00 AM)
- Streak warning when streak is at risk
- Inactivity reminders at 2, 5, and 7 days after app goes to background (`WorkManager` background tasks)

---

### TtsService — `lib/services/tts_service.dart`

`flutter_tts` wrapper for reading AI text responses aloud.

- Language: `en-US`
- Speech rate: `0.45` (slower for clarity)
- Used as a fallback when Gemini Live audio is unavailable

---

### CloudFunctionsService — `lib/services/cloud_functions_service.dart`

Calls Firebase Cloud Functions for server-side AI operations.

```dart
Future<String> chatWithAI(String message, List<Map> history)
Future<Map<String, dynamic>> generateDailyPlan(Map childProfile)
```

---

### PermissionService — `lib/services/permission_service.dart`

Wraps `permission_handler` to request:
- Microphone permission (required for voice assistant)
- Camera permission (required for profile photo and media upload)

---

## Screens & UI

### Authentication Screens (4)

| Screen | Route | Description |
|---|---|---|
| `LoginScreen` | `/login` | Email/password and Google sign-in |
| `SignupScreen` | `/signup` | New account creation with role selection |
| `PasswordResetScreen` | `/password-reset` | Email-based password recovery |
| `PhoneOtpScreen` | `/phone-otp` | Phone number with OTP verification |

---

### Onboarding (3)

| Screen | Route | Description |
|---|---|---|
| `OnboardingScreen` | `/onboarding` | 3-slide animated introduction (new users) |
| `ParentOnboardingScreen` | `/parent-onboarding` | Child profile creation wizard |
| `DoctorOnboardingScreen` | `/doctor-onboarding` | Doctor credentials setup |

---

### Parent Home (5 tabs via `HomeScreen`)

| Tab | Description |
|---|---|
| Home | Dashboard: greeting, weekly stats, skill progress, AI recommendations, today's plan, guidance notes, quick actions |
| Chat | AI text chat with streaming responses, image/video upload, Markdown rendering |
| Activities | Therapy module library with filters; module detail and guided session runner |
| Progress | Weekly stats, 7-day bar chart, skill-category breakdown, session history |
| Profile | Child profile view, multi-child switcher, settings, account management |

---

### Voice Assistant (2)

| Screen | Description |
|---|---|
| `VoiceAssistantScreen` | Full-screen voice session UI with waveform, session status, controls |
| `GlobalVoiceOverlay` | Draggable pill overlay persisting across all screens during active session |

---

### Activities (4)

| Screen | Description |
|---|---|
| `ModulesLibraryScreen` | Searchable/filterable grid of 30 therapy modules |
| `ModuleDetailScreen` | Full module detail: objectives, materials, instructions, outcomes |
| `TherapyActivityScreen` | Guided step-by-step session runner |
| `ActivityTimerScreen` | Countdown timer for timed activity segments |

---

### Games Hub (10)

| Screen | Skill Focus |
|---|---|
| `GamesHubScreen` | 2-column grid launcher |
| `MemoryMatchGameScreen` | Working memory |
| `AttentionGameScreen` | Sustained attention |
| `DragSortGameScreen` | Categorization and sorting |
| `EmotionQuizGameScreen` | Emotional recognition |
| `SoundMatchGameScreen` | Auditory processing |
| `VisualTrackerGameScreen` | Visual tracking |
| `BreathingBubbleGameScreen` | Breathing regulation and calm |
| `ShapeMatcherGameScreen` | Shape recognition |
| `SequenceMemoryGameScreen` | Sequence recall |

---

### Doctor Portal (9 screens)

| Screen | Description |
|---|---|
| `DoctorDashboardScreen` | 4-tab root for doctor experience |
| `DoctorHomeTab` | Summary stats and recent activity |
| `DoctorRequestsTab` | Pending/approved/declined connection requests |
| `DoctorPatientsTab` | All connected parent/child pairs |
| `DoctorProfileTab` | Manage specialization, bio, photo |
| `PatientDetailScreen` | Child profile and full activity log |
| `AssignPlanScreen` | Create and assign therapy plan to child |
| `ComposeGuidanceNoteScreen` | Write and send a guidance note to parent |
| `RoleSelectionScreen` | First-time role choice (parent or doctor) |

---

### Supporting Screens

| Screen | Description |
|---|---|
| `DailyPlanScreen` | Day's activity schedule with completion checkboxes |
| `WellnessScreen` | Mood check-in and 14-day mood trend |
| `EmergencyScreen` | 5-step meltdown calming protocol + breathing exercise |
| `CommunityScreen` | Real-time parent community posts and likes |
| `AchievementsScreen` | Badge gallery with unlock status |
| `SettingsScreen` | Theme, notifications, and account settings |
| `AboutScreen` | App version, credits, support links |
| `DoctorReportScreen` | Generated progress report for doctor review |
| `FullProfileScreen` | Detailed child profile view with edit access |
| `ProfileSetupScreen` | Edit child profile fields |

---

### Reusable Widgets (`lib/widgets/`)

| Widget | Description |
|---|---|
| `CustomButton` | Full-width 56px elevated button with loading state, optional icon, configurable colors |
| `CustomTextField` | Styled text input with error state and prefix/suffix icons |
| `LoadingIndicator` | Centered `CircularProgressIndicator` with optional label |

---

## Firebase Setup

### Project Configuration

- **Project ID:** `ai-help-7`
- **Android App ID:** `1:886951217174:android:0aa5a4566dd3dfbc730d37`
- **Package name:** `com.careai.care_ai`

### Firestore Collections

```
users/
  {uid}/
    children/{childId}
    chats/{messageId}
    activity_logs/{logId}
    daily_plans/{date}
    milestones/{milestoneId}
    mood_checkins/{checkinId}
    game_sessions/{sessionId}
    therapy_sessions/{sessionId}
    events/{eventId}
    bookmarks/{bookmarkId}
    achievements/{achievementId}

community_posts/{postId}
guidance_notes/{noteId}
doctor_requests/{requestId}
user_backups/{uid}
user_daily_snapshots/{uid}/{date}
```

### Required Firebase Products

Enable the following in your Firebase console:

- Authentication (Email/Password, Google, Phone)
- Cloud Firestore
- Firebase Storage
- Cloud Messaging
- Cloud Functions (Blaze plan required)
- Realtime Database (optional)

### Firestore Security Rules

Ensure your Firestore rules allow:
- Users to read/write their own `users/{uid}` documents and subcollections
- Authenticated users to read/write `community_posts`
- Doctors to write `guidance_notes`
- Parents to read `guidance_notes` where `childId` matches their children

---

## AI Integration

### Text Chat (Gemini 2.5 Flash)

The `AiService` uses the `google_generative_ai` SDK. Each chat session is initialized with:

1. A **system prompt** establishing the CARE-AI persona, safety rules, response formatting, and tool declaration
2. The child's profile context
3. Complete conversation history from Firestore

**Function Tool — `perform_app_action`:**

The AI can trigger in-app navigation by calling this tool:

```json
{
  "name": "perform_app_action",
  "description": "Navigate or launch a feature in the app",
  "parameters": {
    "action": "navigate",
    "target": "games_hub | daily_plan | progress | voice_assistant | ..."
  }
}
```

**Safety thresholds:**

| Category | Threshold |
|---|---|
| Harassment | MEDIUM_AND_ABOVE |
| Hate Speech | MEDIUM_AND_ABOVE |
| Dangerous Content | MEDIUM_AND_ABOVE |
| Sexually Explicit | HIGH |

---

### Voice Assistant (Gemini Live API)

The voice assistant uses a raw WebSocket to the Gemini Live API for true bidirectional real-time audio.

**Flow:**

```
Microphone (PCM16 @ 16kHz)
  └── record package → raw PCM bytes
        └── GeminiLiveService.sendAudioChunk() → base64-encode → WebSocket
              └── Gemini Live API (model: gemini-2.5-flash-native-audio-preview)
                    └── PCM audio response (24kHz) → base64 inlineData
                          └── PcmAudioPlayer → flutter_sound → speaker
```

**Context injection:** Before starting a session, `ContextBuilderService` builds a rich text prompt containing:
- Child name, age, conditions, communication level, therapy goals
- Last 7 mood entries
- Today's daily plan tasks
- Weekly activity stats
- Latest guidance note from therapist

This context is sent as the WebSocket setup instruction.

**Voice-commanded navigation:** When the AI calls the `perform_app_action` tool during a voice session, the `VoiceAssistantService` handles it and calls `Navigator.pushNamed(...)` to navigate the app.

---

### TherapyAiService (Gemini 2.5 Flash with JSON mode)

Uses Gemini with `responseMimeType: 'application/json'` for structured therapy recommendations:

- Analyzes session performance metrics against child profile
- Returns structured JSON with module IDs, reasons, and priority scores
- Used to power the "Next Best Module" recommendation engine

---

## Caching & Offline Support

### Three-Layer Cache Architecture

```
UI Request
  │
  ▼
SmartDataRepository          (cache-first access layer)
  │
  ├── Hit + Fresh  ─────────────────────► Return cached data immediately
  │
  ├── Miss or Expired ─────► FirebaseService ──► Update cache ──► Return data
  │
  └── Offline + Stale ──────────────────► Return stale data (never show blank)
```

### Hive Boxes

| Box Name | Contents |
|---|---|
| `care_ai_data` | Serialized JSON for all cached objects |
| `care_ai_meta` | ISO-8601 expiry timestamps (one per cache key) |
| `care_ai_backup` | Periodic backup snapshot of `care_ai_data` |

### SyncManager Operations

| Trigger | Action |
|---|---|
| Hourly timer | Refresh all 14 cache keys from Firebase |
| 6-hour timer | Backup `care_ai_data` to `care_ai_backup` box |
| 24-hour timer | Push daily stats snapshot to Firestore |
| Network restored | Full cache refresh (all keys) |
| App resumed | Selective refresh (weekly stats, guidance notes, daily plan) |

---

## Notifications

### FCM Push Notifications

Topics automatically subscribed on login:
- `daily_reminders` — daily activity reminder
- `progress_updates` — milestone and progress alerts

FCM token is stored in `users/{uid}.fcmToken` and refreshed on each login.

### Local Notifications

| Notification | Trigger | Default Time |
|---|---|---|
| Daily Reminder | Scheduled daily | 9:00 AM |
| Streak Warning | Detected streak risk | Immediate |
| Inactivity (2 days) | `WorkManager` task | 2 days after last session |
| Inactivity (5 days) | `WorkManager` task | 5 days after last session |
| Inactivity (7 days) | `WorkManager` task | 7 days after last session |

Notification time can be changed in Settings. The toggle and time are persisted via `SharedPreferences`.

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ^3.7.0
- Dart SDK (bundled with Flutter)
- Android Studio (for Android emulation and builds)
- Xcode (for iOS builds; macOS only)
- Node.js 18+ and npm (for Cloud Functions)
- [Firebase CLI](https://firebase.google.com/docs/cli) (`npm install -g firebase-tools`)
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli) (`dart pub global activate flutterfire_cli`)

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd ai-help
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Install Cloud Functions dependencies:**
   ```bash
   cd functions
   npm install
   cd ..
   ```

---

## Environment Configuration

### 1. Firebase Setup

Link the app to your Firebase project:

```bash
flutterfire configure --project=<your-firebase-project-id>
```

This regenerates `lib/firebase_options.dart` for your project.

### 2. Environment Variables

Create a `.env` file in the project root:

```env
GEMINI_API_KEY=your_gemini_api_key_here
```

The `.env` file is declared as an asset in `pubspec.yaml` and loaded at runtime via `flutter_dotenv`.

Alternatively, inject the key at build time:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

### 3. Cloud Functions Environment

The Cloud Functions use the same Gemini key. Set it via Firebase environment config:

```bash
firebase functions:config:set gemini.api_key="your_gemini_api_key_here"
```

Or use the Firebase Console → Project Settings → Environment variables (2nd gen functions).

---

## Running & Building

### Run in development

```bash
flutter run
```

### Run with explicit API key (no .env file)

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

### Build Android APK

```bash
flutter build apk --release
```

### Build Android App Bundle (Play Store)

```bash
flutter build appbundle --release
```

### Build iOS (macOS required)

```bash
flutter build ios --release
```

### Run code generation (Hive adapters)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Cloud Functions

Cloud Functions are in `functions/src/` (TypeScript, Node.js 18).

### Functions

#### `chatWithAI` (callable)

Server-side Gemini chat using `gemini-1.5-flash`. Called by `CloudFunctionsService` as a fallback or for server-enforced safety.

**Request:**
```json
{
  "message": "string",
  "history": [{ "role": "user|model", "parts": [{ "text": "string" }] }]
}
```

**Response:**
```json
{ "response": "string" }
```

#### `generateDailyPlan` (callable)

Generates a structured daily therapy plan for a child using `gemini-1.5-flash`.

**Request:**
```json
{
  "childProfile": { "name": "...", "age": 7, "conditions": [...], ... }
}
```

**Response:**
```json
{
  "plan": [
    { "time": "09:00", "activity": "...", "duration": "20 min", "goal": "..." }
  ]
}
```

#### `onUserCreated` (Auth trigger)

Fires when a new user signs up. Creates a default Firestore document at `users/{uid}` with initial fields.

#### `onUserDeleted` (Auth trigger)

Fires when a user account is deleted. Cascades deletion of all Firestore subcollections (children, chats, activity logs, etc.).

### Deploy Cloud Functions

```bash
cd functions
npm run build
firebase deploy --only functions
```

### Local emulation

```bash
firebase emulators:start --only functions
```

---

## Theme & Design System

### Color System (`lib/core/constants/app_colors.dart`)

| Token | Default | Usage |
|---|---|---|
| `primary` | Indigo-blue | Primary actions, CTA buttons |
| `secondary` | Coral | Secondary actions, highlights |
| `accent` | Teal | Success states, progress |
| `gold` | Amber | Achievements, streaks |
| `purple` | Violet | Voice assistant states |
| `doctorBlue` | Light blue | Doctor portal UI |
| `emergency` | Red | Emergency mode, alerts |
| `chatUser` | Light indigo | User chat bubbles |
| `chatAi` | Surface | AI chat bubbles |

Both light and dark variants are defined for all semantic tokens.

### Typography

Poppins via `google_fonts` — applied globally through `AppTheme` to all Material 3 text styles.

### Animation Constants (`lib/core/constants/app_animations.dart`)

| Constant | Value | Usage |
|---|---|---|
| `fast` | 150ms | Button presses, micro-interactions |
| `medium` | 300ms | Screen transitions, expanding panels |
| `slow` | 600ms | Page transitions, modal entries |
| `verySlow` | 1200ms | Onboarding, splash animations |

---

## Contributing

1. Fork the repository.
2. Create a feature branch from `main`.
3. Follow the feature-first directory structure (`lib/features/<feature>/presentation/`).
4. Use `Provider` for any new state that must be shared across widgets.
5. Add new data models under `lib/models/` with `fromMap`/`toMap` serialization methods.
6. Write new Firebase operations in `FirebaseService` or through `SmartDataRepository` for cached access.
7. Name all routes consistently and declare them in the `CareAiApp` routes map.
8. Run `flutter analyze` before submitting a PR.

---

## License

This project is proprietary. All rights reserved.
