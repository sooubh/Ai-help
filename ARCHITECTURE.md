# 🏗️ CARE-AI Architecture & Technology Stack

## 🌟 Overview
**CARE-AI** is a premium Flutter-based AI Parenting Companion designed to support children with disabilities. This document provides a highly detailed breakdown of the internal architecture, data flows, and the comprehensive technology stack used in this project.

---

## 🏛️ Architectural Pattern: Feature-Driven Layered Clean Architecture

The project follows a **Feature-Driven** approach combined with **Domain Layering**. This ensures that each functional unit (like 'Voice Assistant' or 'Progress Tracking') is modular and independently maintainable.

### 🏢 1. Core Layer (`lib/core/`)
The foundational infrastructure shared across all features.
- **Config**: Secure handling of environment variables and API keys (Gemini API, Firebase).
- **Theme**: A centralized `ThemeProvider` managing Material 3 Design tokens, custom HSL color palettes, and global typography (Inter/Google Fonts).
- **Constants**: Centralized definitions for UI strings, asset paths, and visual tokens (gradients, shadows).
- **Utils**: Reusable logic for date formatting, validation, and platform-specific helpers.

### 🍱 2. Features Layer (`lib/features/`)
Each directory represents a specific business domain.
- **Auth**: Multi-role authentication flow (Parent/Doctor).
- **Activities**: Library of therapy modules and interactive activity timers.
- **Voice**: Real-time AI voice interaction system.
- **Chat**: Intelligent text-based AI assistance.
- **Progress**: Advanced data visualization of child development metrics.
- **Doctor**: Specialized interface for healthcare professionals to assign plans and review progress.

### 🛠️ 3. Service Layer (`lib/services/`)
Singleton-based infrastructure services that abstract complex external integrations.
- **`AiService`**: The gateway to Google Gemini. Optimized for streaming LLM responses to minimize latency.
- **`VoiceAssistantService`**: A complex orchestrator combining `Speech-to-Text` (STT), `AiService`, and `Text-to-Speech` (TTS) into a seamless circular pipeline.
- **`FirebaseService`**: A robust wrapper for Cloud Firestore, Auth, and Storage with unlimited offline persistence enabled.
- **`NotificationService`**: Intelligent reminder engine utilizing FCM for remote pushes and `flutter_local_notifications` for background retention.

### 📊 4. Data Layer (`lib/models/`)
Type-safe data representation.
- Models include built-in JSON/Map serialization logic, ensuring seamless synchronization between Firestore, local storage, and AI prompts.

---

## 🛠️ Technology Stack & Dependencies

### **Framework & Language**
- **Flutter SDK (^3.7.0)**: High-performance reactive framework.
- **Dart**: Strong-typed, asynchronous language with optimized GC.

### **Artificial Intelligence**
- **Google Generative AI (Gemini)**: State-of-the-art LLM for parenting guidance and activity recommendations.
- **Streaming API**: Used for real-time token delivery in voice/chat.

### **Backend Infrastructure (Firebase)**
- **Auth**: Secure user management.
- **Firestore**: Scalable NoSQL real-time database.
- **Storage**: Media and profile asset hosting.
- **Messaging (FCM)**: Push notification infrastructure.
- **Cloud Functions**: Serverless logic for cross-platform processing.

### **State & Navigation**
- **Provider**: Standardized state management for reactive UI updates and dependency injection.
- **Named Routes**: Centralized navigation system for complex screen hierarchies.

### **Hardware & Media**
- **`speech_to_text`**: High-accuracy local speech recognition.
- **`flutter_tts`**: High-quality natural language synthesis.
- **`connectivity_plus`**: Real-time monitoring of network health.
- **`image_picker`**: Seamless profile media management.

### **UI & Experience**
- **`flutter_animate`**: Premium micro-animations and transitions.
- **`fl_chart`**: Advanced data visualization for therapy progress.
- **`shimmer`**: Professional-grade loading state feedback.
- **`google_fonts`**: Modern, accessible typography.

---

## 🔄 Core Data Flows

### 🎙️ The Voice Pipeline
1. **Input**: `VoiceAssistantService` activates the microphone via STT.
2. **Analysis**: Recognized text is sent to `AiService`.
3. **Intelligence**: Gemini processes the text with specialized "Voice Mode Rules" (short, conversational).
4. **Streaming**: Response chunks are received via Streams.
5. **Synthesis**: `TtsService` converts chunks into human-like speech.
6. **Persistence**: The entire interaction is logged to Firebase for progress tracking.

### 📅 The Intelligent Recommendation Flow
1. **Trigger**: Dashboard loads child profile.
2. **Context**: `AiService` builds a prompt based on child age, conditions, and communication level.
3. **Generation**: Gemini generates a JSON-structured therapy plan.
4. **Parsing**: App converts JSON into `RecommendationModel` objects.
5. **Caching**: Results are saved to Firestore to reduce API costs and enable offline access.

---

## 🛡️ Stability & Quality
- **Error Handling**: Comprehensive try-catch blocks in service layers with user-facing error banners.
- **Linting**: 100% compliant with `flutter_lints` (Clean Analysis).
- **Environment**: Secure `.env` handling for API isolation.
- **Persistence**: Hybrid strategy using Firestore (cloud) and `SharedPreferences` (local preferences).

---
*Created by CARE-AI Engineering Team*
