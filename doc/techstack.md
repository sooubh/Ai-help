1. Overview

CARE-AI is a cross-platform mobile application built using Flutter, powered by cloud services and advanced multimodal AI. The system provides personalized therapy guidance, interactive activities, progress tracking, and expert supervision.

The platform uses Google’s Gemini models, including the Gemini Live model for real-time conversational AI.

2. Frontend (Mobile Application)
Framework

Flutter (Dart) — Cross-platform Android & iOS development

Single codebase, fast UI rendering, ideal for rapid prototyping

Key Capabilities

Real-time chat interface

Voice interaction UI

Interactive games

Progress dashboards

Accessibility-focused design

Suggested Flutter Packages

Firebase integration packages

Audio recording & playback

Speech-to-text plugins

Text-to-speech plugins

State management (Provider / Riverpod / Bloc)

Local storage (Hive / SharedPreferences)

3. Backend & Cloud Infrastructure
Platform

Firebase

Services Used
🔐 Firebase Authentication

Email/password login

Phone OTP login

Google Sign-In

☁️ Cloud Firestore

Stores:

User accounts

Child profiles

Therapy modules

Progress logs

Doctor notes

Chat metadata

⚙️ Cloud Functions

Secure AI API communication

Data processing

Scheduled tasks

Recommendation logic

📁 Cloud Storage

Images

Videos

Documents

Activity media

🔔 Firebase Cloud Messaging (Optional)

Reminders

Alerts

Progress notifications

4. AI Layer — Google Gemini Models

CARE-AI uses multimodal AI to understand text, voice, images, and video.

5. Live Conversational AI
Model
⭐ Gemini Live Model
Purpose

Real-time interactive conversation with parents.

Capabilities

Low-latency streaming responses

Natural conversational flow

Context-aware dialogue

Emotional support responses

Parenting guidance

Activity explanations

6. Live Voice Conversation
Voice Input

Real-time speech recognition

Multilingual support

Accessible for low-literacy users

Voice Output

Natural AI voice responses

Adjustable speed

Hands-free interaction

Gemini Live enables near real-time voice-based conversation when integrated with audio pipelines.

7. Image Processing & Analysis
Model

Gemini Image / Vision Models

Use Cases

Analyze photos of child activities

Recognize objects used in therapy

Provide context-aware suggestions

Assist experts with visual observations

8. Video Processing & Behavioral Analysis
Primary Option

Gemini Video Understanding Models

Use Cases

Analyze child behavior during tasks

Estimate engagement level

Assist doctors in remote evaluation

Generate summaries from short clips

FREE Alternative Video Processing Methods

If direct video AI is limited:

✅ Frame Extraction + Image Analysis (Recommended)

Extract key frames from video

Analyze frames using image model

Combine results

Tools:

FFmpeg

Mobile media libraries

✅ On-Device Analysis

Basic detection such as:

Motion tracking

Face presence detection

Activity duration measurement

✅ Open-Source Tools

FFmpeg (video processing)

OpenCV (optional advanced use)

9. AI Recommendation Engine

Hybrid system combining:

Expert-designed modules database

AI personalization

User feedback

Doctor inputs

AI Functions

Suggest best modules

Adjust difficulty

Generate daily plans

Detect concerns

Provide encouragement

Summarize progress

10. Data & Progress Analytics

System tracks:

Activity completion

Game performance

Behavioral logs

Engagement levels

Therapy outcomes

AI continuously analyzes data to improve recommendations.

11. Security & Privacy

Encrypted communication (HTTPS)

Secure authentication

Role-based access (parent / doctor)

Child data protection practices

User-controlled data permissions

12. Offline Capability (Optional)

Basic features available offline:

Cached modules

Saved activities

Limited guidance

Sync occurs when internet is available.

13. Scalability

Architecture supports:

Large user base

Real-time updates

Integration with institutions

Deployment across regions

14. Development Tools

Flutter SDK

Android Studio / VS Code

Firebase Console

Git version control

15. Rationale for Technology Choices

This stack was selected because it is:

✅ Rapid to develop
✅ Cost-effective (free tiers available)
✅ Highly scalable
✅ Supports multimodal AI
✅ Suitable for accessibility-focused applications
✅ Ideal for AI for Social Good initiatives