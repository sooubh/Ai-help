# CARE-AI Presentation README

## 1) One-Line Pitch
CARE-AI is an AI-powered parenting companion that helps families of children with developmental and physical challenges through personalized therapy guidance, real-time voice support, progress tracking, and doctor collaboration.

## 2) Problem Statement
Parents often struggle with:
- Inconsistent access to therapists
- Lack of structured daily plans at home
- Low visibility into measurable progress
- Stress during emergency or meltdown moments
- Difficulty coordinating with doctors in real time

## 3) Our Solution
CARE-AI combines:
- AI chat + real-time voice assistant
- Structured therapy modules and therapeutic games
- Daily plans and progress analytics
- Parent-doctor collaboration tools
- Offline-first caching with automatic sync

## 4) Target Users
- Parents and caregivers of children with disabilities
- Therapists, pediatric specialists, and developmental doctors

## 5) Key Features (Demo Highlights)
### Parent Experience
- Secure login with Email, Google, and Phone OTP
- Child profile onboarding (multi-child support)
- AI assistant chat with multimodal support (text, image, video context)
- Real-time voice assistant with floating global overlay
- Therapy modules library with timer-based session tracking
- Games hub with 9 therapeutic games
- Daily plan generation and completion tracking
- Progress dashboard with charts, streaks, and activity trends
- Wellness mood check-ins
- Emergency calming protocol screen
- Community posts and likes
- Achievements tracking

### Doctor Experience
- Doctor onboarding and dashboard
- Parent/child patient list
- Assign activities to child profiles
- Send guidance notes to families
- Review activity history and progress context

## 6) What Makes CARE-AI Different
- Real-time AI voice pipeline (low-latency conversational support)
- Unified parent + doctor workflow in one app
- Practical therapy execution, not only informational chat
- Offline-capable user experience with sync managers
- Built on production-grade Firebase services

## 7) Real-Time Voice Assistant (Technical Advantage)
- Uses Gemini Live over WebSocket
- Streams microphone PCM audio to AI and plays response audio in real time
- Supports interruption, session state handling, and in-app action tool calls
- Includes a persistent global floating voice overlay for cross-screen continuity

## 8) Core Technology Stack
- Flutter (single codebase for Android/iOS)
- Firebase Auth, Firestore, Storage, Cloud Messaging
- Firebase Cloud Functions (AI callables + auth triggers)
- Google Gemini models for text and voice intelligence
- Hive + SharedPreferences for local/offline persistence
- Provider for state management

## 9) Architecture Snapshot
- Feature-first modular Flutter structure
- Centralized service layer for Firebase, AI, voice, notifications, and cache
- Route-driven navigation with role-based onboarding checks
- Firestore as primary source of truth with selective local caching

## 10) Data & Security Approach
- Role-based data model (parent/doctor)
- Firestore rules integrated in project config
- Users read/write own profile trees
- Doctor and guidance-note flows separated by role checks
- Authentication required for sensitive operations

## 11) Project Scale (Current)
- 17+ feature modules in lib/features
- 10 service components in lib/services
- 14 domain models in lib/models
- 20+ named routes
- Parent and Doctor journeys both implemented

## 12) Cloud Functions
Implemented server-side endpoints include:
- chatWithAI (authenticated callable)
- generateDailyPlan (authenticated callable)
- onUserCreated / onUserDeleted auth triggers

## 13) Demo Flow (Recommended for Presentation)
1. Login as Parent
2. Open Home Dashboard and show recommendations
3. Open AI Chat and ask caregiving question
4. Launch Voice Assistant and show live voice response
5. Open Activities and complete one module
6. Open Games and play one game
7. Show Progress charts and streak updates
8. Show Daily Plan completion
9. Switch to Doctor flow (dashboard, assign plan, guidance note)

## 14) Impact Narrative
CARE-AI helps families move from reactive caregiving to structured, trackable, and collaborative support, while giving doctors better visibility and communication channels.

## 15) Future Roadmap
- Adaptive difficulty for activities and games
- Richer doctor analytics dashboards
- Expanded multilingual voice experiences
- Enhanced recommendation personalization
- Production CI/CD and app store rollout

## 16) Quick Closing Statement
CARE-AI is not just an assistant. It is a daily care system that combines AI intelligence, therapy structure, and clinical collaboration into one accessible mobile platform.
