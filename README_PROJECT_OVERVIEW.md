# CARE-AI Project Overview README

This document provides a technical and product overview of the full CARE-AI app based on the current codebase.

## A) Product Overview
CARE-AI is a Flutter + Firebase mobile platform for parents and doctors supporting children with developmental or physical challenges.

Primary outcomes:
- Personalized support through AI
- Better daily therapy execution at home
- Measurable progress tracking
- Better parent-doctor communication

## B) User Roles and Journeys
### Parent Journey
- Authenticate (Email/Google/Phone)
- Complete onboarding and child profile setup
- Access dashboard and recommendations
- Use AI chat or live voice support
- Run modules/games and log outcomes
- Track progress and daily goals
- Receive doctor guidance notes

### Doctor Journey
- Authenticate and complete doctor profile
- Access doctor dashboard tabs
- Browse patient list and detail views
- Assign activities to child profiles
- Send guidance notes
- Review request and patient context

## C) App Modules (Code-Verified)
Feature directories in lib/features:
- about
- achievements
- activities
- auth
- chat
- community
- daily_plan
- doctor
- emergency
- games
- home
- onboarding
- profile
- progress
- report
- settings
- voice
- wellness

## D) Notable Screens and Flows
- Onboarding, login, signup, password reset, phone OTP
- Parent onboarding and doctor onboarding
- Home dashboard
- Chat screen (AI + media support)
- Voice assistant screen + global overlay
- Modules library + module detail + timer/session completion
- Games hub + therapeutic game screens
- Progress and wellness tracking
- Doctor dashboard + patient detail + assign plan + compose note

## E) Services Layer (Code-Verified)
Service components in lib/services:
- ai_service.dart
- firebase_service.dart
- notification_service.dart
- voice_assistant_service.dart
- gemini_live_service.dart
- therapy_ai_service.dart
- tts_service.dart
- context_builder_service.dart
- cache/smart_data_repository.dart
- cache/sync_manager.dart
- cache/local_cache_service.dart

Responsibilities:
- Authentication and Firestore CRUD
- AI text generation and recommendations
- Real-time voice session orchestration
- Local + push notification setup
- Offline cache and sync workflows

## F) Data Layer
Models in lib/models include:
- user, child profile, chat message
- activity log, therapy session, game session
- recommendation, guidance note, doctor profile
- post, achievement, user event, voice session

## G) Firebase and Cloud
Configured Firebase products:
- Authentication
- Cloud Firestore
- Cloud Storage
- Cloud Messaging
- Cloud Functions

Cloud Functions source:
- functions/src/callables/ai.ts
- functions/src/triggers/auth.ts

Implemented endpoints/triggers:
- chatWithAI callable
- generateDailyPlan callable
- onUserCreated trigger
- onUserDeleted trigger

## H) AI Capabilities
- Text AI assistant for parent guidance
- Cached recommendations
- Daily plan generation support
- Live voice interaction through Gemini Live WebSocket pipeline

Voice stack summary:
- Mic capture and stream upload
- Real-time model responses as audio chunks
- Streaming PCM playback
- Session states, interrupts, and navigation tool events

## I) Navigation
Main app routes are registered in lib/main.dart and include:
- auth, onboarding, home, chat, activities, progress, settings
- daily-plan, emergency, games, wellness, report, about
- community, achievements, voice-assistant
- doctor dashboard and doctor action routes

## J) Security and Access
- Firestore security rules configured via firebase.json
- rules file: firestore.rules
- Authenticated access and role-dependent data boundaries are enforced in rules design

## K) Testing Snapshot
Current test directory includes:
- AI service initialization/completion tests
- environment tests
- Firebase AI tests
- widget smoke test

## L) Build and Runtime Highlights
- Flutter app entry: lib/main.dart
- Theme and provider setup at app root
- Workmanager background callback present
- Notification integration with foreground/background handling
- Firestore offline persistence enabled

## M) Suggested Presentation Structure
Use this order for a strong technical demo:
1. Problem and target users
2. Parent workflow demo
3. Doctor workflow demo
4. AI chat and voice showcase
5. Progress analytics and impact metrics
6. Technical architecture and cloud security
7. Roadmap and scale potential

## N) Current Strengths
- Broad feature coverage across parent + doctor use cases
- Strong Firebase integration and modular services
- Advanced live voice assistant implementation
- Practical offline-first architecture patterns

## O) Expansion Opportunities
- More granular role-based rule hardening
- More automated tests per feature module
- Production observability and release pipelines
- Personalization and adaptive difficulty loops

## P) Fast Start Commands
Flutter app:
- flutter pub get
- flutter run

Cloud Functions:
- cd functions
- npm install
- npm run build
- npm run serve

---
If you want, this file can be converted into a judge-facing version with a one-page executive summary and scoring-aligned language for hackathons or incubator pitches.
