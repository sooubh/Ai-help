# CARE-AI — Master Project Status & Reference

> **Last Updated**: February 27, 2026  
> **Version**: 1.0.0+1  
> **SDK**: Flutter / Dart ^3.7.0  
> **Backend**: Firebase (Auth, Firestore, Storage, FCM)  
> **AI**: Google Gemini (`google_generative_ai: ^0.4.6`)

---

## 1. APP OVERVIEW

**CARE-AI** — AI Parenting Companion for Children with Disabilities.

Assists parents/caregivers of children with ASD, ADHD, speech delays, cerebral palsy, Down syndrome, learning disabilities, and sensory processing issues. Provides AI-powered guidance, therapy activities, progress tracking, and emotional support.

**NOT a medical diagnostic tool** — safety disclaimers enforced throughout.

---

## 2. CURRENT OVERALL STATUS

| Area | Status | Notes |
|---|---|---|
| Project Foundation | ✅ COMPLETE | Firebase, theme, design system, env config |
| User Authentication | ✅ COMPLETE | Email, Google, Phone OTP, password reset, delete account |
| Onboarding & Profile | ✅ COMPLETE | Multi-step wizard, multi-child support |
| Smart Dashboard | ✅ COMPLETE | Hero card, quick actions, child selector, bottom nav |
| AI Chat (Gemini) | ✅ COMPLETE | Streaming, STT, TTS, markdown, safety guardrails |
| Therapy Modules Library | ✅ COMPLETE | Browse, detail, timer, bookmarks, activity logging |
| Progress Tracking | ✅ COMPLETE | Real-time Firestore, charts, milestones, weekly stats |
| Daily Plan | ✅ COMPLETE | Firestore save/load, activity status tracking |
| Emergency Mode | ✅ COMPLETE | Step-by-step calming guide, high-contrast UI |
| Games Hub | ✅ COMPLETE | Hub screen done, 6 interactive games built & integrated |
| Wellness / Mood | ✅ COMPLETE | Mood check-ins, history, Firestore persistence |
| Doctor Report | ✅ COMPLETE | Shareable report generation |
| Settings | ✅ COMPLETE | Theme toggle, voice settings, account management |
| Community | 🟡 PLACEHOLDER | Screen exists, no real functionality |
| Achievements | 🟡 PLACEHOLDER | Screen exists, no real functionality |
| About | ✅ COMPLETE | App info + safety disclaimer |
| Real-Time Data | ✅ COMPLETE | All screens use Firestore, offline persistence enabled |
| User Event Tracking | ✅ COMPLETE | UserEventModel, saveUserEvent method |
| Doctor App Stream | ✅ COMPLETE | Entire therapist portal with tabs, assignment, and notes |
| Cloud Functions | ❌ NOT STARTED | No server-side functions deployed |
| AI Recommendation Engine | ✅ COMPLETE | Dashboard generates & caches AI recommendations |
| Adaptive Difficulty | ❌ NOT STARTED | No auto-adjustment logic |
| Real-Time Voice Assistant | ✅ COMPLETE | Full-screen dual-mode (Push/Continuous) STT/TTS orchestrator using Gemini |
| Full Game Implementations | ✅ COMPLETE | All 6 therapy games implemented with scoring and tracking |
| FCM Notification Pipeline | ❌ NOT STARTED | Service initialized, no triggers wired |
| App Store Deployment | ❌ NOT STARTED | |

---

## 3. FILE STRUCTURE

```
lib/
├── main.dart                                    # Entry point, Firebase init, providers, routing
├── firebase_options.dart                        # Auto-generated Firebase config
│
├── core/
│   ├── config/
│   │   └── env_config.dart                      # GEMINI_API_KEY from .env
│   ├── constants/
│   │   ├── app_animations.dart                  # Animation durations & curves
│   │   ├── app_colors.dart                      # Color palette
│   │   ├── app_gradients.dart                   # Gradient definitions
│   │   ├── app_shadows.dart                     # BoxShadow presets
│   │   └── app_strings.dart                     # Static strings
│   ├── theme/
│   │   ├── app_theme.dart                       # Light & dark ThemeData
│   │   └── theme_provider.dart                  # ChangeNotifier for theme switching
│   └── utils/
│       └── validators.dart                      # Email, password, name validation
│
├── models/                                      # 7 data models
│   ├── user_model.dart                          # UserModel (email, displayName, role, fcmToken, etc.)
│   ├── child_profile_model.dart                 # ChildProfileModel (name, age, conditions[], goals[], etc.)
│   ├── chat_message_model.dart                  # ChatMessageModel (role, content, timestamp)
│   ├── therapy_module_model.dart                # TherapyModuleModel (title, instructions, difficulty, etc.)
│   ├── activity_log_model.dart                  # ActivityLogModel (moduleId, duration, completedAt, etc.)
│   ├── user_event_model.dart                    # UserEventModel (eventType, screen, metadata, timestamp)
│   └── recommendation_model.dart                # RecommendationModel (AI daily recommendations)
│
├── services/                                    # 4 services
│   ├── firebase_service.dart                    # Auth + Firestore CRUD (31 methods, 624 lines)
│   ├── ai_service.dart                          # Gemini AI (chat, streaming, recommendations, 242 lines)
│   ├── tts_service.dart                         # Text-to-speech wrapper
│   └── notification_service.dart                # FCM initialization
│
├── features/                                    # 15 feature modules
│   ├── about/presentation/
│   │   └── about_screen.dart
│   ├── achievements/presentation/
│   │   └── achievements_screen.dart
│   ├── activities/presentation/
│   │   ├── modules_library_screen.dart          # Browse therapy modules
│   │   ├── module_detail_screen.dart            # Full module instructions
│   │   └── activity_timer_screen.dart           # Session timer
│   ├── auth/presentation/
│   │   ├── login_screen.dart                    # Email + Google + Phone login
│   │   ├── signup_screen.dart                   # Registration
│   │   ├── password_reset_screen.dart           # Email reset
│   │   └── phone_otp_screen.dart                # Phone OTP flow
│   ├── chat/presentation/
│   │   └── chat_screen.dart                     # AI chat (684 lines)
│   ├── community/presentation/
│   │   └── community_screen.dart                # Placeholder
│   ├── daily_plan/presentation/
│   │   └── daily_plan_screen.dart               # Daily schedule
│   ├── emergency/presentation/
│   │   └── emergency_screen.dart                # Meltdown mode
│   ├── games/presentation/
│   │   └── games_hub_screen.dart                # Game selection hub
│   ├── home/presentation/
│   │   └── home_screen.dart                     # Dashboard (961 lines)
│   ├── onboarding/presentation/
│   │   └── onboarding_screen.dart               # App intro carousel
│   ├── profile/presentation/
│   │   └── profile_setup_screen.dart            # Child profile wizard
│   ├── progress/presentation/
│   │   └── progress_screen.dart                 # Progress charts (622 lines)
│   ├── report/presentation/
│   │   └── doctor_report_screen.dart            # Shareable report
│   ├── settings/presentation/
│   │   └── settings_screen.dart                 # App settings
│   └── wellness/presentation/
│       └── wellness_screen.dart                 # Mood & wellness
│
└── widgets/                                     # 3 shared widgets
    ├── custom_button.dart
    ├── custom_text_field.dart
    └── loading_indicator.dart
```

**Other project files:**
```
├── .env                          # GEMINI_API_KEY
├── pubspec.yaml                  # Dependencies (v1.0.0+1)
├── firebase.json                 # Firebase hosting/functions config
├── analysis_options.yaml         # Dart linting rules
├── doc/
│   ├── prd.md                    # Product Requirements Document
│   ├── care_ai_prd_and_features.md  # Feature specifications
│   ├── development_plan.md       # Full development plan (1307 lines)
│   └── techstack.md              # Technology stack details
├── assets/
│   ├── images/
│   ├── icons/
│   └── animations/
└── android/                      # Android platform code
```

---

## 4. NAMED ROUTES (19 total)

| Route | Screen | Status |
|---|---|---|
| `/onboarding` | OnboardingScreen | ✅ |
| `/login` | LoginScreen | ✅ |
| `/signup` | SignupScreen | ✅ |
| `/password-reset` | PasswordResetScreen | ✅ |
| `/phone-otp` | PhoneOtpScreen | ✅ |
| `/profile-setup` | ProfileSetupScreen | ✅ |
| `/home` | HomeScreen (Dashboard) | ✅ |
| `/chat` | ChatScreen | ✅ |
| `/activities` | ModulesLibraryScreen | ✅ |
| `/progress` | ProgressScreen | ✅ |
| `/settings` | SettingsScreen | ✅ |
| `/daily-plan` | DailyPlanScreen | ✅ |
| `/emergency` | EmergencyScreen | ✅ |
| `/games` | GamesHubScreen | 🟡 Hub only |
| `/wellness` | WellnessScreen | ✅ |
| `/doctor-report` | DoctorReportScreen | ✅ |
| `/about` | AboutScreen | ✅ |
| `/community` | CommunityScreen | 🟡 Placeholder |
| `/achievements` | AchievementsScreen | 🟡 Placeholder |

---

## 5. FIREBASE SERVICE METHODS (31 total)

### Authentication (6)
| Method | Purpose |
|---|---|
| `signUp(email, password, {displayName})` | Email/password registration + Firestore user doc |
| `signIn(email, password)` | Email/password login |
| `signInWithGoogle()` | Google Sign-In flow |
| `resetPassword(email)` | Send password reset email |
| `signOut()` | Sign out (+ Google sign out) |
| `deleteAccount()` | Delete account + all Firestore data |

### User & Child Profiles (5)
| Method | Purpose |
|---|---|
| `getUserProfile()` | Get current user's profile data |
| `updateUserProfile(fields)` | Update user profile fields |
| `saveChildProfile(profile)` | Save/update child profile |
| `getChildProfiles()` | Get all children for current user |
| `getChildProfile([childId])` | Get single child profile |

### Chat (2)
| Method | Purpose |
|---|---|
| `getChatMessages([childId])` | Stream chat messages (real-time) |
| `sendChatMessage(message, [childId])` | Save chat message to Firestore |

### Bookmarks (3)
| Method | Purpose |
|---|---|
| `bookmarkActivity(activityId)` | Bookmark a therapy activity |
| `unbookmarkActivity(activityId)` | Remove bookmark |
| `getBookmarkedIds()` | Get all bookmarked IDs |

### Activity, Progress & Recommendations (7)
| Method | Purpose |
|---|---|
| `logActivity(log)` | Log completed activity session |
| `getActivityLogs({limit})` | Get recent activity logs |
| `getWeeklyStats()` | Total activities, minutes, streak |
| `getSkillProgress()` | Skill progress by category |
| `getDailyActivityCounts()` | Activity counts for last 7 days |
| `getDailyRecommendations(childId)` | Fetch cached personalized AI recommendations |
| `saveRecommendations(childId, recs)` | Save generated recommendations to Firestore |

### Daily Plan (2)
| Method | Purpose |
|---|---|
| `saveDailyPlan(date, activities)` | Save today's plan |
| `getDailyPlan(date)` | Get plan for a given date |

### Milestones (2)
| Method | Purpose |
|---|---|
| `saveMilestone(milestone)` | Save a milestone |
| `getMilestones()` | Get all milestones |

### Wellness (2)
| Method | Purpose |
|---|---|
| `saveMoodCheckIn(mood, note)` | Save mood check-in |
| `getMoodHistory({limit})` | Get mood history |

### Events (1)
| Method | Purpose |
|---|---|
| `saveUserEvent(event)` | Track user interaction event |

---

## 6. AI SERVICE CAPABILITIES

| Method | Purpose |
|---|---|
| `initialize()` | Init Gemini model with system prompt |
| `startChatSession({childProfile})` | Start context-aware chat session |
| `getResponse(message)` | Send message, get full response |
| `getStreamingResponse(message)` | Stream response token-by-token |
| `getRecommendations(profile)` | Generate personalized recommendations |
| `dispose()` | Cleanup resources |

**Safety**: Non-diagnostic guardrails in system prompt. Fallback responses when API unavailable.

---

## 7. DATA MODELS

### UserModel
`email`, `displayName`, `role`, `photoUrl`, `fcmToken`, `createdAt`, `lastLoginAt`

### ChildProfileModel
`id`, `name`, `age`, `gender`, `conditions[]`, `communicationLevel`, `behavioralConcerns[]`, `sensoryIssues[]`, `motorSkillLevel`, `learningAbilities[]`, `parentGoals[]`, `currentTherapyStatus`, `createdAt`, `updatedAt`

### ChatMessageModel
`id`, `role` (user/assistant), `content`, `timestamp`, `voiceUsed`

### TherapyModuleModel
`id`, `title`, `objective`, `conditionTypes[]`, `ageRange`, `skillCategory`, `difficultyLevel`, `materials[]`, `instructions[]`, `duration`, `safetyNotes`, `expectedOutcomes`, `createdBy`, `isExpertApproved`, `mediaUrls[]`

### ActivityLogModel
`id`, `moduleId`, `moduleName`, `category`, `duration`, `completedAt`, `notes`

### UserEventModel
`id`, `eventType`, `screen`, `metadata`, `timestamp`

### RecommendationModel
`id`, `title`, `duration`, `objective`, `reason`, `createdAt`, `expiresAt`

---

## 8. FIRESTORE SCHEMA (Current)

```
users/{uid}
├── email, displayName, role, photoUrl, fcmToken, createdAt, lastLoginAt
├── children/{childId}
│   ├── name, age, gender, conditions[], communicationLevel, ...
│   ├── chats/{chatId}/messages/{msgId}
│   ├── bookmarks/{bookmarkId}
│   ├── activityLogs/{logId}
│   ├── dailyPlans/{date}
│   ├── milestones/{milestoneId}
│   ├── recommendations/daily/items[]
│   └── moodCheckIns/{checkInId}
├── events/{eventId}
└── (future: settings/, wellness/, game_sessions/)
```

---

## 9. DEPENDENCIES (pubspec.yaml)

```yaml
# Firebase
firebase_core: ^3.12.1
firebase_auth: ^5.5.1
cloud_firestore: ^5.6.5
firebase_storage: ^12.4.4
firebase_messaging: ^15.2.4
google_sign_in: ^6.2.2

# AI
google_generative_ai: ^0.4.6

# State Management
provider: ^6.1.2

# Voice
flutter_tts: ^4.2.0
speech_to_text: ^7.3.0

# UI / Design
google_fonts: ^6.2.1
flutter_animate: ^4.5.2
shimmer: ^3.0.0
cached_network_image: ^3.4.1
fl_chart: ^0.70.2
percent_indicator: ^4.2.3
smooth_page_indicator: ^1.2.0+3

# Utilities
intl: ^0.20.2
uuid: ^4.5.1
url_launcher: ^6.3.1
shared_preferences: ^2.3.4
connectivity_plus: ^6.1.1
image_picker: ^1.1.2
flutter_markdown: ^0.7.6
flutter_dotenv: ^6.0.0
cupertino_icons: ^1.0.8
```

---

## 10. APP FLOW

```
App Launch
  → Firebase Init + Offline Persistence Enabled
  → .env Loaded (GEMINI_API_KEY)
  → AiService & NotificationService initialized
  → ThemeProvider loaded

Auth Check (StreamBuilder on authStateChanges)
  ├── Loading → Splash Screen (animated)
  ├── Not signed in → Onboarding → Login/Signup
  └── Signed in → Home Dashboard

Home Dashboard (bottom nav: Dashboard | Activities | Chat | Progress | Settings)
  ├── Dashboard Tab
  │   ├── Greeting + child selector
  │   ├── Hero card
  │   ├── Quick actions → Chat, Activities, Progress, Games, Daily Plan, Wellness, etc.
  │   ├── Recommendations section
  │   └── Emergency FAB → Emergency Screen
  ├── Activities Tab → Modules Library → Module Detail → Activity Timer
  ├── Chat Tab → AI Chat (Gemini streaming)
  ├── Progress Tab → Stats, skills, history, milestones, trends
  └── Settings Tab → Theme, voice, account, about
```

---

## 11. WHAT NEEDS TO BE BUILT NEXT

### 🔴 HIGH PRIORITY

#### A. Therapy Games (6 individual games)
✅ Built all 6 interactive therapy games (Memory Match, Attention, Sound Recognition, Drag & Drop, Visual Tracking, Emotion Quiz) and wired them to store activity stats via Firebase.

#### B. Community Screen
✅ Built out fully natively with Tabs for a Real-Time Parent Forum (driven by `community_posts` collection) and curated static support web resources.

#### C. Achievements Screen
✅ Fully functional Gamification Dashboard driving Badges (streaks, minutes, diverse activity categories) directly from tracked `ActivityLogModel` records retrieved from Firestore.

#### D. Cloud Functions Backend
✅ Built out the TypeScript Node.js backend. Features secure HTTPS Callables for Gemini API querying (`chatWithAI`, `generateDailyPlan`) and core Background Event Triggers (`onUserCreated`, `onUserDeleted`). Hooked up `generateDailyPlan` back into the main `DailyPlanScreen` interface.

### 🟡 MEDIUM PRIORITY

#### F. Doctor App Stream
Entirely separate set of features nested inside the same app using Role-Based Access Control (RBAC):
- Doctor authentication & registration
- Doctor dashboard with patient list
- Child analysis view (progress, behavior, concerns)
- Therapy plan assignment
- Parent guidance notes

**Files to create (doctor features):**
- `lib/features/doctor/presentation/doctor_dashboard_screen.dart`
- `lib/features/doctor/presentation/patient_detail_screen.dart`
- `lib/features/doctor/presentation/assign_plan_screen.dart`
- `lib/features/doctor/presentation/compose_guidance_note.dart`
- `lib/models/doctor_model.dart`

#### G. Adaptive Difficulty System
Auto-adjust activity/game difficulty based on performance:
- 3 consecutive successes → increase level
- 3 consecutive struggles → decrease level
- Store difficulty state per child per skill

#### H. Full Notification Pipeline
FCM is initialized but no triggers are wired:
- Daily plan ready (morning)
- Activity reminders
- Doctor note received
- Weekly progress report
- Encouraging messages

#### I. Gemini Live Voice Conversation
Current: basic STT + TTS. Need: real-time streaming voice via Gemini Live.

### 🟢 LOWER PRIORITY

#### J. Image & Video Analysis
- Gemini Vision for analyzing child activity photos
- Video behavioral analysis

#### K. Multilingual Support
- Currently English only
- Add Hindi, Marathi via Gemini + i18n

#### L. Data Export (GDPR)
- User data download

#### M. School Collaboration Tools
- Share progress with teachers

#### N. Offline Enhancements
- Cache therapy modules
- Emergency content fully offline

---

## 12. CONFIGURATION

### Environment Variables (.env)
```
GEMINI_API_KEY=<your-key>
```

### Firebase Project
- **Auth Providers**: Email/Password, Phone, Google
- **Firestore**: Offline persistence enabled, unlimited cache
- **Config Files**: `google-services.json` (Android), `firebase_options.dart`

### Theme
- Light & Dark mode via `ThemeProvider`
- Saved to `SharedPreferences`
- System UI: transparent status bar

---

## 13. DEVELOPMENT HISTORY

| Date | Phase | Work Done |
|---|---|---|
| Feb 10, 2026 | Setup | Firebase security rules, black screen fix |
| Feb 13, 2026 | Design | Dual theme implementation (light + dark) |
| Feb 17, 2026 | Phase 1-2 | Initial MVP — auth, chat, dashboard, profile, core services |
| Feb 26, 2026 | Phase 3 | Daily Plan, Emergency Mode, Games Hub screens built |
| Feb 26-27, 2026 | Data | Real-Time Data Overhaul + Therapy Games Implementation |
| Feb 27, 2026 | Phase 3.5 | AI Recommendation Engine (Gemini structured output + Firestore caching) |

---

## 14. KNOWN ISSUES / NOTES

1. **Doctor App**: Entire stream (7 features) is not started
2. **Notifications**: FCM service is initialized but no notification triggers are set up
3. **No automated tests**: Only default Flutter test file exists

---

*This file is the source of truth for the CARE-AI project. Update it as features are completed or modified.*
