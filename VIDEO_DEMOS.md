# 🎬 CARE-AI — Module Video Demos & References

> A comprehensive video guide for every module in the CARE-AI app.
> Each section contains a **module overview**, **AI video suggestions**, and curated **YouTube references**.

---

## Table of Contents

1. [Onboarding](#1-onboarding)
2. [Authentication](#2-authentication)
3. [Profile Setup](#3-profile-setup)
4. [Home / Dashboard](#4-home--dashboard)
5. [AI Chat](#5-ai-chat)
6. [Voice Assistant (App Agent)](#6-voice-assistant-app-agent)
7. [Daily Plan](#7-daily-plan)
8. [Activities & Modules Library](#8-activities--modules-library)
9. [Therapy Games Hub](#9-therapy-games-hub)
10. [Progress Tracking](#10-progress-tracking)
11. [Wellness](#11-wellness)
12. [Emergency / Meltdown Mode](#12-emergency--meltdown-mode)
13. [Doctor Dashboard & Reports](#13-doctor-dashboard--reports)
14. [Community](#14-community)
15. [Achievements](#15-achievements)
16. [Settings](#16-settings)
17. [Notifications](#17-notifications)
18. [About](#18-about)

---

## 1. Onboarding

### How It Works
The onboarding module introduces first-time users to CARE-AI through a series of interactive, swipeable screens. It highlights core features — AI parenting guidance, therapy activities, voice assistance, and doctor integration — before routing users to sign-up. Separate flows exist for **Parents** and **Doctors**.

### 🤖 AI Video Suggestion
> **Prompt for AI Video Generation:**
> *"Create a 30-second animated walkthrough showing a mobile app onboarding experience with 3 slides: a caring robot mascot waving, a parent with a child using the app, and a doctor interacting with the dashboard. Soft gradient backgrounds in purple and blue. Swipe transitions between slides."*

### 📺 YouTube References
| Video | Description |
|-------|-------------|
| [Mastering User Onboarding in Flutter](https://youtube.com) | Step-by-step guide to creating engaging onboarding screens with PageView and animations |
| [Instaflutter Walkthrough Onboarding Flow](https://youtube.com) | Open-source Flutter starter kit with a walkthrough onboarding flow |
| [Designing the Perfect Onboarding Flow (GetX + Firebase)](https://medium.com) | Article & video on creating onboarding with state management |

---

## 2. Authentication

### How It Works
Supports **Email/Password sign-up & login**, **Phone OTP verification**, and **Password Reset** via Firebase Auth. Users are automatically routed based on auth state — new users go to profile setup, returning users go straight to the dashboard.

### 🤖 AI Video Suggestion
> **Prompt for AI Video Generation:**
> *"Create a 45-second screen recording-style animation showing a login page with email field, password field, and sign-in button. Show the user typing, a loading spinner, and then a smooth transition to the home dashboard. Include Firebase logo watermark. Material Design style."*

### 📺 YouTube References
| Video | Description |
|-------|-------------|
| [Complete Firebase Authentication in Flutter - Email & Password](https://youtube.com) | Covers signup, login, forgot password, email verification, and keeping users logged in |
| [Flutter Firebase Authentication Tutorial - ALL Login Methods](https://youtube.com) | Deep dive into email/password, Google, Facebook, phone verification, and anonymous sign-in |
| [Firebase x Flutter Tutorial - Authentication Service Class](https://youtube.com) | Clean architecture approach to Firebase auth with a dedicated service class |
| [Google Sign-In in Flutter with Firebase](https://youtube.com) | Step-by-step Google Sign-In integration |

---

## 3. Profile Setup

### How It Works
After authentication, parents fill in their **child's profile** — name, age, conditions (e.g., ASD, ADHD), communication level, behavioral concerns, sensory issues, motor skill level, and therapy goals. Doctors fill in their **specialization and clinic details**. Data is stored in Firestore and used to personalize the entire app experience.

### 🤖 AI Video Suggestion
> **Prompt for AI Video Generation:**
> *"Animate a mobile form wizard with 4 steps: 'Child Name & Age', 'Conditions Selection (chips)', 'Communication Level (slider)', and 'Parent Goals (multi-select)'. Show smooth step transitions with a progress bar at the top. Soft, caring color palette."*

### 📺 YouTube References
| Video | Description |
|-------|-------------|
| [Handle User Profile in Flutter - Firebase Profile Management](https://youtube.com) | Covers Firestore integration for storing and retrieving user profile data |
| [The Ultimate Guide to Flutter User Profile Page with Firebase](https://google.com) | Comprehensive guide covering auth, Firestore, and Firebase Storage for profiles |
| [Profile & Settings with Firebase in Flutter](https://youtube.com) | Managing user data, updating profiles, and storing settings in Firestore |

---

## 4. Home / Dashboard

### How It Works
The main hub after login. Displays a personalized greeting, **daily activity recommendations** from Gemini AI, quick-access cards for Chat, Voice, Daily Plan, Games, Wellness, and Emergency. Shows real-time progress stats pulled from Firestore.

### 🤖 AI Video Suggestion
> **Prompt for AI Video Generation:**
> *"Create a 40-second animated demo of a health/wellness app dashboard. Show a greeting header ('Good morning, Sarah!'), horizontal scrollable recommendation cards, a circular progress indicator, and bottom navigation bar with 4 tabs. Use a purple/indigo gradient theme. Animate cards sliding in from the right."*

### 📺 YouTube References
| Video | Description |
|-------|-------------|
| [Flutter Health App UI Design](https://youtube.com) | Transforming a health app design into a functional Flutter dashboard |
| [Complete Fitness App in Flutter & Firebase](https://youtube.com) | Full fitness app with dashboard, progress tracking, and Firebase backend |
| [Flutter Tutorial In 2 Hours by a REAL Project](https://youtube.com) | Building a complete, polished Flutter UI from scratch |

---

## 5. AI Chat

### How It Works
Text-based chat powered by **Google Gemini (gemini-2.5-flash)**. Supports streaming responses, child-profile-aware context, non-diagnostic safety guardrails, and Firestore message persistence. The AI acts as an empathetic parenting companion — never prescribing treatments, always encouraging professional consultation.

### 🤖 AI Video Suggestion
> **Prompt for AI Video Generation:**
> *"Animate a chat interface where a user types 'My child had a meltdown today, what should I do?' and an AI response streams in word-by-word: 'Stay calm and ensure safety first. Try reducing sensory input…'. Show typing indicators, message bubbles, and a warm purple theme."*

### 📺 YouTube References
| Video | Description |
|-------|-------------|
| [Complete AI ChatBot Assistance In Flutter 2025](https://youtube.com) | Building an AI chatbot in Flutter with real-time streaming responses |
| [AI Chat Bot • Claude x Flutter Tutorial](https://youtube.com) | Creating an AI chatbot with API communication and chat UI management |
| [Build an AI Chatbot App with Flutter and OpenAI](https://djamware.com) | Cross-platform AI chatbot with clean chat interface and real-time handling |
| [Flutter AI Chatbot 2025 - Using GetX Controller](https://youtube.com) | State management approach for AI chatbot apps |

---

## 6. Voice Assistant (App Agent)

### How It Works
Full voice pipeline: **Microphone (STT) → Gemini AI → Speaker (TTS)**. Supports push-to-talk and continuous listening modes. Now runs **globally in the background** across all screens via a floating overlay bubble. Uses **Gemini Function Calling** to recognize navigation intents and autonomously switch screens (e.g., "Take me to the games hub").

### 🤖 AI Video Suggestion
> **Prompt for AI Video Generation:**
> *"Create a 60-second demo showing a floating mic button on a mobile app. User says 'Open emergency mode' — show a speech waveform animation, then the AI responds 'Opening emergency mode now', and the screen transitions to an emergency page. Show the floating overlay remaining visible throughout."*

### 📺 YouTube References
| Video | Description |
|-------|-------------|
| [Build a Flutter Voice Assistant App with ChatGPT & Dall-E](https://youtube.com) | Voice assistant with STT, TTS, and AI API integration in Flutter |
| [How to Build a Multilingual AI Voice Assistant in FlutterFlow](https://youtube.com) | Multilingual voice assistant with OpenAI Text-To-Speech |
| [How to Build Custom Siri AI Agents using Flutter](https://youtube.com) | Custom AI agents triggered by voice commands in Flutter |
| [Google Fonts & Siri Wave - Jarvis AI Voice Assistant](https://youtube.com) | Building a Jarvis-style voice UI with waveform animations |
| [Build an AI Assistant with Flutter (Stream SDK)](https://getstream.io) | Real-time AI assistant for iOS using Stream Flutter Chat SDK |
| [Challenge: Adding AI Voice in Flutter App in 10 Minutes](https://youtube.com) | Quick tutorial on adding TTS using `flutter_tts` |

---

## 7. Daily Plan

### How It Works
Displays a **structured daily therapy schedule** with timed activities (morning, afternoon, evening). Each plan item shows the activity name, duration, icon, and completion status. Plans can be AI-generated based on the child's profile or manually assigned by a doctor.

### 🤖 AI Video Suggestion
> **Prompt for AI Video Generation:**
> *"Animate a daily planner screen with three time blocks (Morning, Afternoon, Evening). Each block contains 2-3 activity cards with checkboxes: 'Sensory Play (15 min)', 'Speech Practice (10 min)'. Show a user tapping to check off an activity, triggering a confetti animation."*

### 📺 YouTube References
| Video | Description |
|-------|-------------|
| [Build a Real Daily Planner Android App with Flutter & Hive](https://fluttersensei.com) | Daily planner with local data storage using Hive |
| [Daily Tasks Planner - Flutter Framework (Part 6)](https://youtube.com) | Series on building a complete daily task planner UI |

---

## 8. Activities & Modules Library

### How It Works
A categorized browsable library of therapy activities and learning modules. Categories include Speech, Motor Skills, Sensory, Social Skills, and more. Each module has step-by-step instructions, estimated duration, and difficulty level. Activities are personalized based on the child's profile.

### 🤖 AI Video Suggestion
> **Prompt for AI Video Generation:**
> *"Show a grid of colorful activity cards in a mobile app: 'Bubble Popping (Sensory)', 'Story Time (Speech)', 'Block Stacking (Motor)'. User taps a card, and it expands into a detail view with step-by-step instructions and a 'Start Activity' button."*

### 📺 YouTube References
| Video | Description |
|-------|-------------|
| [Flutter Mental Wellness App (MindHaven)](https://youtube.com) | Wellness app with categorized activities: meditation, breathing, journaling |
| [Flutterbys Special Education & Therapy Center Walkthrough](https://youtube.com) | Real therapy center techniques adaptable to digital activities |

---

## 9. Therapy Games Hub

### How It Works
Six interactive therapy games designed for children with special needs: **Emotion Match**, **Color Sorting**, **Memory Cards**, **Pattern Sequence**, **Sound Recognition**, and **Breathing Buddy**. Each game targets specific developmental skills and adapts difficulty based on the child's abilities.

### 🤖 AI Video Suggestion
> **Prompt for AI Video Generation:**
> *"Animate a 'Games Hub' screen in a mobile app with 6 game cards in a 2x3 grid, each with a colorful icon and name. User taps 'Memory Cards' — transition to a game board with face-down cards that flip when tapped, revealing emoji faces. Show a match animation with sparkles."*

### 📺 YouTube References
| Video | Description |
|-------|-------------|
| [Flutter Casual Games Toolkit](https://flutter.dev) | Official Flutter resource for building casual games |
| [FlutterFlow Gamification Tutorial](https://youtube.com) | Building gamified experiences with engagement mechanics |
| [Chihuahua - Flutter Mental Health App (CBT)](https://youtube.com) | Mental health app with cognitive behavioral therapy features |
| [Smarty Flutter - Interactive Learning for Children](https://youtube.com) | Physical/digital learning toy teaching shapes, colors, and emotions |

---

## 10. Progress Tracking

### How It Works
Visual dashboard showing the child's progress over time. Displays **streak tracking**, activity completion rates, skill development charts, and milestone achievements. Data is pulled from Firestore event logs and rendered with interactive charts.

### 🤖 AI Video Suggestion
> **Prompt for AI Video Generation:**
> *"Animate a progress dashboard with: a line chart showing 'Weekly Activity Completion' trending upward, a circular progress ring at 72%, streak flame icon showing '14 days', and skill badges. Use smooth chart draw animations."*

### 📺 YouTube References
| Video | Description |
|-------|-------------|
| [Flutter Fitness App - Tracking Workouts & Progress](https://youtube.com) | Progress tracking with interactive graphs and charts |
| [Complete Fitness App in Flutter & Firebase - Progress Tracking](https://youtube.com) | Full progress visualization with Firebase backend |
| [Flutter Projects Series - Fitness Tracker App (GeeksforGeeks)](https://youtube.com) | Step-by-step fitness tracker with progress charts |

---

## 11. Wellness

### How It Works
Holistic wellness tracking module covering **mood logging**, **sleep tracking**, **stress levels**, and **self-care activities**. Provides AI-generated wellness insights and suggestions. Tracks trends over time with visual indicators.

### 🤖 AI Video Suggestion
> **Prompt for AI Video Generation:**
> *"Show a wellness screen with a mood selector (5 emoji faces from sad to happy), a sleep quality slider, and a stress level gauge. User taps the 'happy' emoji, sleeps 8 hours, low stress — show a 'Great Day!' summary card with animated confetti."*

### 📺 YouTube References
| Video | Description |
|-------|-------------|
| [Flutter Mental Wellness App (MindHaven)](https://youtube.com) | Mood tracking, gratitude journaling, guided meditation, and breathing exercises |
| [Building a Wellness App with Cross-Platform Magic (Feel Great)](https://medium.com) | Flutter wellness app with mood tracking, fitness, sleep analysis, and community |

---

## 12. Emergency / Meltdown Mode

### How It Works
Immediate access to **calming tools and crisis protocols** for meltdown situations. Features include a **breathing exercise** with animated guide, **sensory calming visuals**, quick access to **emergency contacts**, and step-by-step **de-escalation instructions**. Designed for one-tap access from the dashboard.

### 🤖 AI Video Suggestion
> **Prompt for AI Video Generation:**
> *"Animate a red 'Emergency' button being tapped, transitioning to a calm blue screen. Show a breathing circle expanding ('Breathe In...') and contracting ('Breathe Out...') with a 4-7-8 count. Display emergency contact cards at the bottom with call icons."*

### 📺 YouTube References
| Video | Description |
|-------|-------------|
| [Flutter SOS / Emergency App Tutorial](https://youtube.com) | Building a panic button app with location sharing and alerts |
| [Flutter Emergency App with Background Services](https://youtube.com) | SOS features with background service execution |
| [Flutter Safety App - Panic Button & Location Tracking](https://youtube.com) | Complete emergency app with GPS and automated SMS |

---

## 13. Doctor Dashboard & Reports

### How It Works
A dedicated interface for **healthcare professionals**. Doctors can view **assigned patients**, access their **activity logs and progress**, **assign custom therapy plans**, write **guidance notes**, and review **AI-generated developmental reports**. Data streams in real-time from Firestore.

### 🤖 AI Video Suggestion
> **Prompt for AI Video Generation:**
> *"Animate a doctor dashboard showing a patient list. Doctor taps a patient card — expanding into a detail view with progress charts, activity timeline, and a 'Write Note' floating action button. Doctor types a guidance note and taps 'Send'. Show a success notification."*

### 📺 YouTube References
| Video | Description |
|-------|-------------|
| [Complete Fitness App in Flutter & Firebase](https://youtube.com) | Admin-style dashboard with user management and data tracking |
| [Flutter Caregiver Application Demo](https://youtube.com) | Caregiver app tracking vitals and habits for kids and patients |
| [Profile & Settings with Firebase in Flutter Admin Panel](https://youtube.com) | Managing user data and settings in an admin context |

---

## 14. Community

### How It Works
A supportive **community space** where parents can connect, share experiences, and offer peer support. Features include **discussion threads**, **resource sharing**, and moderated content. Designed to reduce isolation for caregivers of children with special needs.

### 🤖 AI Video Suggestion
> **Prompt for AI Video Generation:**
> *"Show a community feed with user-generated posts: 'My son said his first word today! 🎉' with like/comment buttons. Animate a new post being composed and submitted, appearing at the top of the feed with a slide-down animation."*

### 📺 YouTube References
| Video | Description |
|-------|-------------|
| [Building a Wellness App - Community & Social Sharing](https://medium.com) | Implementing community features, social sharing, and in-app chat |
| [Flutter Chat App Tutorial with Firebase](https://youtube.com) | Real-time messaging with Firebase — applicable to community chat |

---

## 15. Achievements

### How It Works
**Gamification system** that rewards users for consistent engagement. Badges and achievements are unlocked for milestones like completing daily plans, maintaining streaks, finishing activities, and reaching skill goals. Celebratory animations encourage continued use.

### 🤖 AI Video Suggestion
> **Prompt for AI Video Generation:**
> *"Animate an achievements page with a grid of badge icons (some unlocked, some locked/greyed out). User completes an activity — a new badge unlocks with a golden glow animation and confetti burst. Badge title: '7-Day Streak Champion 🔥'."*

### 📺 YouTube References
| Video | Description |
|-------|-------------|
| [Flutter Gamification & Achievement System](https://youtube.com) | Implementing achievements, streaks, and time-limited challenges |
| [Flutter Casual Games Toolkit](https://flutter.dev) | Official resources for game development and gamified elements |
| [FlutterFlow Gamification for Engagement](https://youtube.com) | Building gamified experiences in Flutter apps |

---

## 16. Settings

### How It Works
User preferences including **theme toggle** (light/dark mode), **notification settings**, **profile editing**, **voice assistant preferences**, **language settings**, and **account management** (sign out, delete account).

### 🤖 AI Video Suggestion
> **Prompt for AI Video Generation:**
> *"Show a settings screen with toggle switches: 'Dark Mode' (toggle ON, screen transitions to dark), 'Notifications' (toggle with description), and sections for Account, Voice, and About. Smooth toggle animations throughout."*

### 📺 YouTube References
| Video | Description |
|-------|-------------|
| [Flutter Dark Mode / Light Mode Toggle Tutorial](https://youtube.com) | Implementing theme switching with Provider and SharedPreferences |
| [Profile & Settings with Firebase](https://youtube.com) | Managing settings and user preferences |

---

## 17. Notifications

### How It Works
**Push notifications** via Firebase Cloud Messaging (FCM). Supports daily activity reminders, inactivity nudges (scheduled when app is backgrounded), therapy session reminders, and doctor-assigned plan alerts. Handles foreground and background notification states.

### 🤖 AI Video Suggestion
> **Prompt for AI Video Generation:**
> *"Show a phone lock screen receiving a push notification: '🌟 Time for today's speech practice session!' User taps the notification, app opens directly to the Daily Plan screen. Then show an in-app notification banner sliding down."*

### 📺 YouTube References
| Video | Description |
|-------|-------------|
| [Flutter Firebase Push Notifications - Complete Guide](https://youtube.com) | Step-by-step FCM setup for Android and iOS |
| [Flutter Push Notifications Tutorial 2024](https://youtube.com) | Handling foreground, background, and terminated notification states |

---

## 18. About

### How It Works
Static informational screen showing **app version**, a brief description of CARE-AI's mission, **team information**, **terms of service**, **privacy policy**, and links to support resources. Clean, minimal design.

### 🤖 AI Video Suggestion
> **Prompt for AI Video Generation:**
> *"Animate an 'About' page with the CARE-AI logo at the top, animated version number '1.0.0', scrollable content including mission statement, team cards with small avatars, and tappable links for Terms, Privacy, and Support."*

### 📺 YouTube References
| Video | Description |
|-------|-------------|
| [Flutter About Page Best Practices](https://youtube.com) | Building clean About/Info screens with proper licensing |

---

## 🛠 Backend Services (Cross-Module)

### Gemini AI Service (`ai_service.dart`)
- Powers Chat, Voice Assistant, Daily Plan recommendations, and Doctor Reports
- **Reference:** [Build an AI Chatbot with Flutter and OpenAI](https://djamware.com)

### Firebase Service (`firebase_service.dart`)
- Authentication, Firestore CRUD, real-time event tracking, offline persistence
- **Reference:** [Flutter & Firebase Crash Course](https://youtube.com)

### TTS Service (`tts_service.dart`)
- Text-to-Speech for voice assistant responses
- **Reference:** [Adding AI Voice in Flutter in 10 Minutes](https://youtube.com)

### Notification Service (`notification_service.dart`)
- FCM integration, inactivity reminders, scheduled alerts
- **Reference:** [Flutter Push Notifications Complete Guide](https://youtube.com)

---

> 💡 **Tip:** To generate AI demo videos, use tools like **Synthesia**, **HeyGen**, **Runway ML**, **Pika Labs**, or **Google Vids** with the prompts provided above for each module.

> 📌 **Note:** YouTube links above are curated references. Search for the exact titles on YouTube for the most up-to-date versions of these tutorials.
