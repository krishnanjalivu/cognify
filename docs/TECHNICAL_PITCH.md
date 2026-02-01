# Cogniaware — Technical Pitch

## One-liner

**Cogniaware** is a **privacy-first, on-device** mobile app that monitors cognitive health through **passive gait analysis**, **typing rhythm**, and **voice exercises**, producing a single **Cogniaware Index** (0–100), trend charts, and downloadable reports—with **no raw sensor or audio data ever leaving the device**.

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| **Framework** | Flutter (Dart 3.x), cross-platform (iOS, Android) |
| **Sensors** | `sensors_plus` — accelerometer & gyroscope streams |
| **Storage** | SQLite via `sqflite` — local DB for trends & records |
| **Charts** | `fl_chart` — line charts, gauges, multi-metric views |
| **Reports** | `pdf` — on-device PDF + CSV export |
| **Notifications** | `flutter_local_notifications` — trend alerts, tips, reminders |
| **Voice** | `speech_to_text` — on-device transcription; audio discarded after use |
| **Preferences** | `shared_preferences` — data source toggle, notification settings |

**Optional (prepared, not wired):** TensorFlow Lite for ML-based index prediction; currently a **rule-based index** from gait/typing/voice features.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        PRESENTATION (Flutter UI)                  │
│  Dashboard │ Gait Screen │ Typing/Voice Exercises │ Reports │ Settings
└─────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                         SERVICES LAYER                            │
│  SensorService → GaitAnalysisService  (real-time step detection)  │
│  TypingExerciseService / VoiceExerciseService  (active tasks)     │
│  StorageService  (SQLite) │ ReportService (PDF/CSV)              │
│  NotificationsService │ PreferencesService │ DummyDataService     │
└─────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                         DATA LAYER                                │
│  Device sensors (accel/gyro) │ Local DB (cogniaware.db)           │
│  No cloud; no raw sensor/audio persistence                        │
└─────────────────────────────────────────────────────────────────┘
```

- **Single source of truth:** `CogniawareRecord` — timestamp, `cogniawareIndex`, optional `gaitMetrics`, `typingMetrics`, `voiceMetrics` (and sub-indices).
- **Dashboard** reads latest records from storage; in “live sensors” mode it refreshes periodically so new gait/typing/voice data appears without reopening the app.
- **Gait:** real-time stream → step detection & metrics → optionally persisted to DB when step count/interval conditions are met; UI can show dummy placeholder until first real data.

---

## Data Sources & Processing

### 1. Gait (passive, real-time)

- **Input:** Accelerometer (and gyroscope) via `sensors_plus`, streamed at device rate.
- **Processing:**  
  - **Step detection:** magnitude peaks above a rolling baseline, with debounce (min step interval ~300 ms) and a 30 s sliding window.  
  - **Metrics:** step count, cadence (steps/min), step-interval variability (std), gait symmetry, rhythm consistency, gyro stability.  
  - **Distance:** step count × fixed stride (e.g. 0.75 m).
- **Output:** `GaitMetrics` + **Gait Index** (0–100). Stored only as aggregated metrics in SQLite; raw accelerometer/gyro samples are **never** stored.
- **Modes:** App can run with **live sensors** (real device) or **dummy data** (for demos/QA without hardware).

### 2. Typing (active, on-device)

- **Input:** User types a short prompt; only **key-down timestamps** (ms) are used.
- **Processing:** Inter-key intervals → average dwell/flight time, variability, rhythm consistency → **Typing Index** (0–100).  
- **Privacy:** Keystroke **content** is never stored or transmitted; only timing features are saved in `CogniawareRecord`.

### 3. Voice (active, on-device)

- **Input:** User speaks a prompt; **speech_to_text** provides transcript on-device.
- **Processing:** Transcript → type-token ratio, lexical complexity, speech rhythm proxy → **Voice Index** (0–100).  
- **Privacy:** Audio is processed locally and **discarded**; only derived metrics are stored.

---

## Cogniaware Index (0–100)

- **Formula (current):** weighted combination of the three sub-indices, e.g.  
  **Cogniaware Index = 0.5 × Gait Index + 0.3 × Typing Index + 0.2 × Voice Index**, clamped to 0–100.
- **Gait Index** today is rule-based (cadence band, variability, symmetry, rhythm, gyro); the codebase has an **ML placeholder** (`CogniawareML`) for a future TFLite model that would consume the same gait features and output the index.
- **Interpretation:** Green (e.g. ≥70) = stable, Yellow (e.g. 45–70) = moderate, Orange (&lt;45) = increased variability; used in dashboard, reports, and notification logic.

---

## Storage & Privacy

- **Database:** Single SQLite DB (`cogniaware.db`) in app documents directory. Tables store only high-level records: `id`, `timestamp`, `cogniawareIndex`, optional JSON for gait/typing/voice **metrics** and sub-indices.
- **What we do not store:** Raw accelerometer/gyroscope samples, keystroke content, or audio. Only **derived metrics and indices** are persisted.
- **Export:** User can export **PDF + CSV** reports (index over time, gait/typing/voice summaries); generated on-device from stored records. User can also clear or delete all data from Settings.

---

## Notifications & Reports

- **Notifications:** Implemented with **flutter_local_notifications**. Uses **on-device** trend evaluation (e.g. index vs baseline) to trigger:  
  - Trend alerts (e.g. drop in index),  
  - Preventive tips (walking, exercises),  
  - Reminders (voice/typing tasks, configurable time).  
  All driven by local data; no server. User can toggle categories and reminder time in Settings.
- **Reports:** `ReportService` generates a PDF (summary, index table, risk bands) and a CSV from stored `CogniawareRecord` list (e.g. last N days). Files are written to a temp directory for sharing/saving.

---

## Extensibility & Roadmap (for pitch)

- **ML pipeline:** `CogniawareML` is structured to load a TFLite model from assets and run inference on gait (and later typing/voice) features; current implementation uses a rule-based index. Adding `tflite_flutter` and a trained model would allow data-driven index prediction without changing the rest of the app.
- **Data source toggle:** Users can switch between “live sensors” and “dummy data,” so the same code path supports both real deployment and demos.
- **Modular services:** Clear separation between sensors, analysis, storage, reports, and notifications makes it straightforward to add new modalities (e.g. another passive or active signal) and feed them into the same `CogniawareRecord` and dashboard.

---

## Key Technical Differentiators (pitch bullets)

1. **100% on-device** — No backend for health data; no raw sensor or audio ever leaves the device; ideal for privacy-sensitive and regulated environments.
2. **Multi-modal** — Combines passive (gait) and active (typing, voice) signals into one index and one UX (dashboard, trends, reports).
3. **Real-time gait** — Live accelerometer/gyro stream with peak-based step detection, cadence, symmetry, and variability; results can be written to local DB so the dashboard reflects “real-time” data as it’s produced.
4. **Privacy by design** — Typing: timing only; voice: transcript-derived metrics only, audio discarded; gait: only aggregated metrics stored.
5. **Offline-first** — Works fully offline; reports and notifications are generated locally from stored records.
6. **Demo-ready** — Dummy data and “Use live sensors” toggle allow consistent demos and testing without hardware, while the same app uses real sensors in production.
7. **Prepared for ML** — Gait (and optionally typing/voice) indices can be replaced or augmented by a TFLite model without changing the app architecture.

---

## Summary for Verbal Pitch

*“Cogniaware is a Flutter app that turns your phone into a cognitive health monitor. We use the accelerometer and gyroscope for passive gait analysis—step count, cadence, symmetry—and combine that with optional typing and voice exercises. Everything is processed on-device: we only store high-level metrics and a single Cogniaware Index from 0 to 100. No raw sensor or audio data is ever sent or stored. Users get a dashboard, trends, downloadable PDF/CSV reports, and local notifications for trend alerts and reminders. The stack is Flutter, SQLite, and local notifications; we have a clear path to add TensorFlow Lite for ML-based index prediction. It’s privacy-first, offline-first, and built so we can add new signals and keep one unified index and one codebase.”*
