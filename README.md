# CARE-AI 💙🤖

**CARE-AI — AI Parenting Companion for Children with Disabilities**

CARE-AI is a comprehensive Flutter mobile application designed to support parents of children with disabilities. It serves as an intelligent companion, providing real-time AI-driven assistance, daily planning, therapeutic games, and direct integration with healthcare professionals to ensure the best care for children.

---

## ✨ Features

*   **🗣️ Real-Time Voice Assistant Chatbot:** Interactive AI assistant supporting both voice (Speech-to-Text & Text-to-Speech) and text interactions.
*   **📊 Real-Time Data Sync & Offline Support:** Seamless data synchronization via Firebase Firestore, ensuring data availability even offline.
*   **👨‍⚕️ Doctor Stream Integration:** Direct communication channel and reporting system linking parents with pediatricians and therapists.
*   **📅 Daily Plan & Dashboard:** Personalized daily activity scheduling and tracking.
*   **🚨 Emergency Meltdown Mode:** Quick access to calming strategies and immediate interventions during challenging moments.
*   **🎮 Games Hub:** Curated therapeutic and developmental games designed for children with disabilities.
*   **🔐 Secure Authentication & Profiles:** Robust user authentication and detailed child profile management.

---

## 🛠️ Tech Stack

*   **Framework:** [Flutter](https://flutter.dev/) (Dart)
*   **Backend & Cloud Services:** [Firebase](https://firebase.google.com/) (Authentication, Cloud Firestore, Storage, Cloud Messaging, Functions)
*   **AI Engine:** [Google Generative AI (Gemini)](https://ai.google.dev/)
*   **State Management:** Provider
*   **Key Packages:**
    *   `flutter_tts` & `speech_to_text` (Voice capabilities)
    *   `fl_chart` (Data visualization)
    *   `flutter_animate` (UI animations)

---

## 🏗️ Project Structure

The project follows a feature-first architecture for better scalability and maintenance:

*   `lib/core/` - Core utilities, themes, constants, and shared configurations.
*   `lib/features/` - Independent functional modules (e.g., Auth, Dashboard, Voice Chat, Doctor Stream, Games).
*   `lib/models/` - Data models and entities.
*   `lib/services/` - External service integrations (Firebase, AI, TTS/STT).
*   `lib/widgets/` - Reusable UI components.

---

## 🚀 Getting Started

### Prerequisites

*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (^3.7.0)
*   Dart SDK
*   Android Studio / Xcode (for emulation and building)

### Installation

1.  **Clone the repository**
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

### Environment Setup

1.  **Firebase:** Ensure your Flutter app is linked to a Firebase project using FlutterFire CLI.
2.  **Environment Variables:** Create a `.env` file in the root directory and add required API keys (e.g., Gemini API key).
    ```env
    GEMINI_API_KEY=your_api_key_here
    ```

### Run the App

Execute the following command to run the app on a connected device or emulator:

```bash
flutter run
```

---

## 📄 Documentation

For further configuration and setup regarding notifications and deeper AI integrations, please refer to the internal documentation and inline code comments.
