# CARE-AI
AI parenting companion for families supporting children with developmental and physical disabilities.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)

![Firebase](https://img.shields.io/badge/Firebase-enabled-orange)

![Version](https://img.shields.io/badge/version-1.0.0-green)

![Status](https://img.shields.io/badge/status-In%20Development-yellow)

## 📖 About
CARE-AI is a Flutter mobile app for parents/caregivers and doctors/therapists to coordinate child support workflows. Parents can manage child profiles, run therapy activities and games, track progress, and use text/voice AI guidance. Doctors can review assigned patients, view activity history, assign plans, and send guidance notes. The app combines Firebase-backed data, local caching/offline support, scheduled reminders, and Gemini-powered assistance. It is focused on practical daily support, not medical diagnosis.

## ✨ Features

### 👤 Authentication
- Email/password sign up and login
- Google Sign-In
- Phone OTP login via Firebase Auth
- Password reset flow
- Parent/Doctor role-based onboarding and routing

### 🤖 AI Assistant
- Gemini text assistant (`gemini-2.5-flash`) with streaming responses
- Context-aware responses using child profile + cached user context
- In-chat tool calling for in-app navigation (`perform_app_action`)
- Image and video-assisted chat analysis (video keyframe extraction)
- Voice assistant via Gemini Live WebSocket audio model (`gemini-2.5-flash-native-audio-preview-12-2025`)
- AI-generated daily recommendations and therapy feedback

### 👨‍👩‍👧 Parenting / Child Features
- Parent onboarding and child profile setup/edit
- Multi-child switching on dashboard
- Therapy module library with search/filter/bookmarks
- Module detail and guided therapy activity flow
- Activity timer mode with step tracking
- Daily plan (auto-generated + manual CRUD by date)
- Emergency meltdown support flow with guided breathing
- Full profile view and JSON data export

### 🏥 Doctor / Therapy Workflows
- Doctor onboarding/profile
- Doctor dashboard with 4 tabs (home, requests, patients, profile)
- Patient list with search and detail view
- Assign therapy plans to child records
- Compose and send guidance notes
- Parent-facing doctor report generation screen

### 📊 Progress & Analytics
- Weekly stats (activities, minutes, streak)
- Skill progress breakdown
- Recent activity history
- Milestones list
- Weekly trend data
- Shareable progress/doctor reports (clipboard export)

### 🔔 Notifications
- Firebase Cloud Messaging setup and topic subscription
- Local daily reminder scheduling
- Streak warning notifications
- Inactivity reminders (2/5/7 day WorkManager jobs)
- Periodic progress update notifications (3-hour interval)

### 🎮 Activities & Games
- Games hub with 9 games:
  - Memory Match
  - Attention Focus
  - Drag & Sort
  - Emotion Quiz
  - Sound Match
  - Visual Tracker
  - Breathing Bubble
  - Shape Matcher
  - Sequence Memory
- Game sessions contribute to activity/progress tracking

### 👥 Community & Wellness
- Parent community forum (post + like)
- Curated community/support resource tabs
- Parent wellness screen (daily mood, affirmations, breathing exercise, self-care tips)

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State Management | Provider |
| Backend | Firebase Auth, Cloud Firestore, Firebase Storage, Firebase Cloud Messaging, Cloud Functions |
| AI | `google_generative_ai` (Gemini text + structured JSON tasks) |
| Live Voice AI | Gemini Live API over `web_socket_channel` |
| Voice | `flutter_tts`, `speech_to_text`, `record`, `flutter_sound`, `audioplayers` |
| Local Storage | Hive (`hive`, `hive_flutter`) + SharedPreferences |
| Notifications | `flutter_local_notifications` + WorkManager + FCM |
| Charts/Progress UI | `fl_chart`, `percent_indicator` |
| Media | `image_picker`, `video_player`, `chewie`, `video_thumbnail`, `cached_network_image` |
| Utilities | `flutter_dotenv`, `connectivity_plus`, `intl`, `uuid`, `url_launcher`, `crypto` |

## 📁 Project Structure

```text
lib/
├── main.dart
├── core/
│   ├── config/
│   ├── constants/
│   ├── data/
│   ├── errors/
│   ├── theme/
│   └── utils/
├── features/
│   ├── about/
│   ├── achievements/
│   ├── activities/
│   ├── auth/
│   ├── chat/
│   ├── community/
│   ├── daily_plan/
│   ├── doctor/
│   ├── emergency/
│   ├── games/
│   ├── home/
│   ├── onboarding/
│   ├── profile/
│   ├── progress/
│   ├── report/
│   ├── settings/
│   ├── voice/
│   └── wellness/
├── models/
├── services/
│   └── cache/
└── widgets/
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK compatible with Dart SDK constraint `^3.7.0`
- Dart SDK `^3.7.0`
- Firebase project configured
- Android Studio or VS Code

### Installation

```bash
# Clone the repo
git clone <repository-url>
cd Ai-help

# Install dependencies
flutter pub get

# Setup environment
# Create .env (see Environment Setup below)

# Run the app
flutter run
```

### Environment Setup

Create a `.env` file in the project root:

```env
GEMINI_API_KEY=your_api_key_here
```

### Firebase Setup
1. Create a Firebase project in Firebase Console.
2. Enable services used by the app:
   - Authentication (Email/Password, Google, Phone)
   - Cloud Firestore
   - Cloud Storage
   - Cloud Messaging
   - Cloud Functions
3. Place `google-services.json` in `android/app/`.
4. Run:
   ```bash
   flutterfire configure
   ```

## 📱 Screenshots

| Home | Chat | Profile |
|---|---|---|
| coming soon | coming soon | coming soon |

## 🔐 Permissions

| Permission | Reason |
|---|---|
| `INTERNET` | Firebase, Gemini API, general networking |
| `RECORD_AUDIO` | Voice assistant microphone input |
| `MODIFY_AUDIO_SETTINGS` | Real-time voice/audio session control |
| `FOREGROUND_SERVICE` | Long-running voice/notification operations |
| `FOREGROUND_SERVICE_MICROPHONE` | Foreground mic service on newer Android versions |
| `CAMERA` | Capture media/profile images |
| `READ_EXTERNAL_STORAGE` | Read selected media on older Android |
| `READ_MEDIA_IMAGES` | Read images from device media library |
| `READ_MEDIA_VIDEO` | Read videos for chat upload/analysis |
| `RECEIVE_BOOT_COMPLETED` | Restore scheduled notifications after reboot |
| `VIBRATE` | Notification vibration |
| `USE_EXACT_ALARM` | Precise local reminder timing |
| `SCHEDULE_EXACT_ALARM` | Scheduled exact alarms for reminders |
| `POST_NOTIFICATIONS` | Runtime notification permission (Android 13+) |
| `WAKE_LOCK` | Keep device awake for scheduled/background tasks |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | Improve WorkManager/notification reliability |

## 🧪 Testing

Current test status from repository files:
- Unit/integration-style tests present: **9 test cases** across `test/`
- Widget tests: present (`test/widget_test.dart`, 3 tests)
- Integration tests directory: not present

Run tests:
```bash
flutter test
flutter test --coverage
```


## 🐛 Known Issues

- [ ] Release signing artifacts are not fully configured in-repo (`android/key.properties` is absent; release signing depends on local setup).
- [ ] Account deletion only guarantees first-level subcollection cleanup; nested subcollections may remain (commented in `FirebaseService.deleteAccount`).
- [ ] Doctor request Accept/Decline actions in `doctor_requests_tab.dart` currently show snackbars and do not persist approval/decline updates.
- [ ] Voice assistant mute control in `voice_assistant_screen.dart` is UI-only; microphone chunk muting is not implemented in service logic.
- [ ] Placeholder TODO remains in Android config: `TODO: Specify your own unique Application ID`.

## 🗺 Roadmap

Based on current placeholders/incomplete behaviors:
- [ ] Wire doctor request decisions to backend (`respondToDoctorRequest`) in the requests tab UI.
- [ ] Implement true microphone mute path in `VoiceAssistantService`.
- [ ] Replace “opening soon” placeholders in About/Legal links with real destinations.
- [ ] Add complete release signing documentation and reproducible release setup files.
- [ ] Expand automated test coverage across feature screens/services.
- [ ] Add dedicated integration/e2e tests.

## 🤝 Contributing

1. Fork the repo
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m 'Add your feature'`
4. Push to the branch: `git push origin feature/your-feature`
5. Open a Pull Request

## 📄 License

This project is private and not licensed for public use.

## 👨‍💻 Developer

Built by **Sourabh Singh** (`git log` author metadata).

- GitHub: https://github.com/sooubh
- Contact: sourabh3527@gmail.com
