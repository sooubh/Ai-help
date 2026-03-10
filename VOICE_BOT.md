# Voice Bot — How It Works

## Overview

The voice bot is a **real-time bidirectional voice assistant** powered by the **Gemini 2.5 Flash Native Audio** model. It streams raw microphone audio to Google's cloud over WebSocket, receives back synthesized audio, and plays it in real time — no intermediate text step.

---

## Files Involved

| File | Role |
|------|------|
| `lib/services/gemini_live_service.dart` | WebSocket client — sends mic audio, receives AI audio |
| `lib/services/voice_assistant_service.dart` | Central orchestrator (ChangeNotifier) |
| `lib/services/pcm_audio_player.dart` | Streams raw PCM audio chunks to device speaker |
| `lib/services/tts_service.dart` | flutter_tts wrapper (declared but **not used** in live pipeline) |
| `lib/models/voice_session_model.dart` | Session state model and enums |
| `lib/features/voice/presentation/voice_assistant_screen.dart` | Full-screen voice UI |
| `lib/features/voice/presentation/global_voice_overlay.dart` | Floating draggable pill overlay |

---

## Architecture

```
User Mic  (16 kHz PCM16 mono)
     │
     ▼
AudioRecorder  (record ^6.2.0)
     │  raw Uint8List chunks
     ▼
GeminiLiveService.sendAudioChunk()
     │
     │  WebSocket  ──────────────────────────────────────────────────────────────
     │  wss://generativelanguage.googleapis.com/ws/                             │
     │  google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent
     │
     ▼
Gemini 2.5 Flash Native Audio  (cloud)
     │
     │  WebSocket response  (base64 audio/pcm @ 24 kHz)
     ▼
GeminiLiveService.audioStream  (Uint8List broadcast stream)
     │
     ▼
PcmAudioPlayer  (flutter_sound ^9.2.13, sequential queue)
     │
     ▼
Device Speaker  (24 kHz PCM16 mono)

──────────────────────────────────────────────────────
VoiceAssistantService  (ChangeNotifier — orchestrates everything above)
     ├── manages VoiceSessionModel  (status, waveform data)
     ├── builds system prompt via ContextBuilderService
     └── handles Gemini function calls  (app navigation)

VoiceAssistantScreen   — full-screen modal UI
GlobalVoiceOverlay     — floating draggable pill (shown when session is active)
```

---

## Step-by-Step Flow

### 1. Starting a Session — `VoiceAssistantService.startLiveSession()`

1. Checks microphone permission via `AudioRecorder.hasPermission()`.
2. Calls `ContextBuilderService.buildFullContext()` to assemble a system prompt containing the child profile, recent activities, and therapy context.
3. Creates a new `VoiceSessionModel` with `status = VoiceStatus.listening`.
4. Calls `GeminiLiveService.connect(systemPrompt)` — opens the WebSocket and sends the setup message.
5. Subscribes to two streams:
   - `_audioSub` → `geminiLive.audioStream`: feeds raw PCM chunks to `PcmAudioPlayer`.
   - `_msgSub` → `geminiLive.messagesStream`: handles control events (see below).

### 2. WebSocket Setup — `GeminiLiveService.connect()`

Sends an initial JSON setup message:

```json
{
  "setup": {
    "model": "models/gemini-2.5-flash-native-audio-preview-12-2025",
    "generation_config": { "response_modalities": ["AUDIO"] },
    "system_instruction": { "parts": [{ "text": "<system prompt>" }] },
    "tools": [{ "function_declarations": [{ "name": "perform_app_action", ... }] }]
  }
}
```

### 3. Microphone Streaming — `VoiceAssistantService._startMicStreaming()`

- Triggered when a `setupComplete` message arrives from Gemini.
- Starts `AudioRecorder` in stream mode: **16 kHz, PCM16, mono**.
- Each chunk is passed to `GeminiLiveService.sendAudioChunk(bytes)`.
- `sendAudioChunk` base64-encodes the bytes and sends:

```json
{
  "realtime_input": {
    "media_chunks": [{ "data": "<base64>", "mime_type": "audio/pcm;rate=16000" }]
  }
}
```

- Simultaneously, `_updateWaveform(bytes)` decodes the PCM bytes to float amplitudes (keeps the last 20 samples) for the animated waveform in the UI.

### 4. Receiving AI Audio — `GeminiLiveService._onMessage()`

Each incoming WebSocket message is parsed as JSON:

- If the response contains `inlineData` with `mime_type: audio/pcm` → base64-decode → emit `Uint8List` on `audioStream`.
- All messages are also emitted on `messagesStream` for control handling.

### 5. Playing AI Audio — `PcmAudioPlayer`

- `start(sampleRate: 24000)` opens a `FlutterSoundPlayer` stream at **24 kHz PCM16 mono**, buffer 8192.
- Each chunk arrives via `addChunk(Uint8List)` → queued in `_feedQueue`.
- `_processQueue()` processes chunks sequentially with `feedUint8FromStream`, awaiting each one to prevent buffer corruption and audio glitches.

### 6. Control Events — `_msgSub` handler

| Gemini message | Action |
|----------------|--------|
| `setupComplete` | Call `_startMicStreaming()` |
| `turnComplete` | Stop `PcmAudioPlayer`, set status → `listening` |
| `interrupted` | Stop `PcmAudioPlayer` |
| `toolCall` with `perform_app_action` | Navigate to named route via `NavigatorState` |

### 7. Interrupting the AI — `interruptAI()`

1. Calls `PcmAudioPlayer.stop()` immediately.
2. Sends a text message to Gemini via `sendClientContent("Stop")`.
3. Sets status → `VoiceStatus.listening`.

### 8. Context Refresh

A `Timer.periodic` every **5 minutes** calls `sendClientContent(contextSummary)` to keep Gemini aware of the latest in-session activity without restarting the WebSocket.

### 9. Stopping the Session — `stopSession()`

1. Cancels `_audioSub` and `_msgSub`.
2. Stops `AudioRecorder`.
3. Stops `PcmAudioPlayer`.
4. Closes `GeminiLiveService` WebSocket.
5. Cancels context refresh timer.
6. Resets `VoiceSessionModel` to `status = VoiceStatus.idle`.

---

## Session States (`VoiceStatus`)

```
idle  ──startLiveSession()──►  listening
                                  │
                                  │  (Gemini processes speech)
                                  ▼
                              processing
                                  │
                                  │  (audio starts playing)
                                  ▼
                              speaking
                                  │
                          turnComplete / interruptAI()
                                  │
                                  ▼
                              listening  (continuous loop)
                                  │
                              stopSession()
                                  │
                                  ▼
                               idle
```

---

## UI Components

### `VoiceAssistantScreen` (full-screen modal)

Animates based on current `VoiceStatus`:

| Status | Visual |
|--------|--------|
| `listening` | Concentric pulsing rings, mic icon, amplitude scales with real mic input |
| `processing` | Rotating icon, no waveform |
| `speaking` | Outward pulse rings, 12-bar waveform using sine wave |

Controls:
- **Mute** — UI toggle only (does not stop mic streaming in current implementation).
- **End Call** — calls `stopSession()` and pops the screen.
- **Interrupt** — calls `interruptAI()`, only active during `speaking` status.

### `GlobalVoiceOverlay` (floating pill)

- Shown whenever `voiceService.isActive` is true (anywhere in the app).
- Draggable with boundary clamping to screen edges.
- Color-coded status dot:
  - Green → `listening`
  - Blue → `processing`
  - Primary color → `speaking`
  - Grey → connecting / idle
- Tap → navigates to `/voice-assistant`.
- Close button → calls `stopSession()`.

---

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `record` | ^6.2.0 | Microphone capture, PCM16 stream |
| `flutter_sound` | ^9.2.13 | Real-time PCM playback from stream |
| `web_socket_channel` | ^3.0.0 | WebSocket connection to Gemini Live API |
| `flutter_tts` | ^4.2.0 | Declared — **not used** in live pipeline |
| `speech_to_text` | ^7.3.0 | Declared — **not used** (Gemini does STT natively) |
| `audioplayers` | ^6.6.0 | Declared — **not used** in voice pipeline |
| `permission_handler` | ^12.0.1 | Microphone permission request |

> `flutter_tts` and `speech_to_text` are present in `pubspec.yaml` but the live voice pipeline bypasses them entirely — Gemini handles both speech recognition and voice synthesis natively over the WebSocket.

---

## Gemini API Details

- **Endpoint:** `wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=<API_KEY>`
- **Model:** `models/gemini-2.5-flash-native-audio-preview-12-2025`
- **Input audio:** PCM16, 16000 Hz, mono
- **Output audio:** PCM16, 24000 Hz, mono
- **Function tool declared:** `perform_app_action(action: string)` — used for in-app navigation triggered by AI
