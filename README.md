# Cogniaware

Cogniaware is a Flutter mobile app for **cognitive health monitoring** via passive gait analysis, optional typing metrics, and active voice exercises. It provides **alerts**, **preventive suggestions**, and **downloadable reports**. All processing is **on-device** and **privacy-first**.

## Features

### Passive Gait / Step Analysis
- Accelerometer and gyroscope for walking patterns (step count, cadence, step interval variability, gait symmetry, rhythm consistency, gyroscope stability)
- **Gait Index** feeding into the **Cogniaware Index** (0–100)
- Line charts, trend graphs, gauges, and gyro stability chart on the dashboard

### Typing Metrics (Optional / Passive)
- Dwell time and flight time during in-app typing (no content recorded)
- Variability and rhythm patterns; typing index and trends in line charts

### Voice Metrics (Active)
- Placeholder for scheduled voice tasks (Type-Token Ratio, complexity, speech rhythm)
- Audio processed on-device and discarded; user consent for active tasks

### Cogniaware Index & Reports
- Combined Gait + Typing + Voice index (0–100)
- Longitudinal trends: 7-day, 30-day, 90-day charts
- **Downloadable PDF and CSV** reports: index over time, step/gait, typing, voice, deviations from baseline

### Notifications & Preventive Alerts
- **Trend alerts** when gait, typing, or Cogniaware Index deviates from baseline (on-device evaluation)
- **Preventive / improvement tips**: walking, cognitive exercises, voice exercises (non-alarming, motivational)
- **Reminders** for active tasks (voice exercises, typing tasks)
- Color-coded by risk: green = stable, yellow = moderate, orange = increased variability
- **flutter_local_notifications** for local, on-device notifications

### Dashboard & UI
- Tabbed panels: **Combined | Gait | Typing | Voice** (index gauge, trend charts, gyro chart, multi-metric breakdown)
- Streaks (days in stable zone), baseline deviation indicator
- Bottom navigation: **Dashboard**, **Gait** (detailed metrics), **Reports**, **Alerts** (Notifications), **Settings**
- Minimalistic, calm color palette and clean typography

### Privacy & Security
- All data processing on-device; typing timing only (no content); voice processed locally, audio discarded
- Notifications generated from on-device trend evaluation; user consent for active tasks

## Project structure

```
lib/
├── main.dart
├── app_theme.dart
├── models/
│   ├── gait_metrics.dart
│   ├── cogniaware_record.dart
│   ├── typing_metrics.dart
│   └── voice_metrics.dart
├── services/
│   ├── sensor_service.dart
│   ├── gait_analysis_service.dart
│   ├── storage_service.dart
│   ├── dummy_data_service.dart
│   ├── report_service.dart
│   └── notifications_service.dart
├── ml/
│   └── cogniaware_ml.dart
├── widgets/
│   ├── cogniaware_gauge.dart
│   ├── trend_chart.dart
│   ├── risk_indicator.dart
│   ├── cadence_rhythm_chart.dart
│   ├── gyro_chart.dart
│   ├── multi_metric_chart.dart
│   ├── streaks_indicator.dart
│   ├── baseline_indicator.dart
│   └── placeholder_card.dart
└── screens/
    ├── main_shell.dart
    ├── dashboard_screen.dart
    ├── gait_metrics_screen.dart
    ├── reports_screen.dart
    ├── notifications_screen.dart
    └── settings_screen.dart
```

## Dependencies

- **sensors_plus** – accelerometer and gyroscope
- **fl_chart** – graphs and trends
- **sqflite**, **path_provider**, **path** – local storage
- **pdf** – report export
- **flutter_local_notifications** – trend alerts, preventive tips, reminders
- **speech_to_text** (optional, commented) – active voice tasks
- **tflite_flutter** (optional, commented) – ML placeholders

## Running the app

```bash
flutter pub get
flutter run
```

Use a physical device for sensors; the app can run with **dummy data** (seeded on first launch) for testing without hardware.

## Deliverables

- Main dashboard with Cogniaware Index and Gait / Typing / Voice panels
- Trend charts over 7 / 30 / 90 days; secondary screens for detailed metrics
- Downloadable cognitive health report (PDF + CSV)
- Notifications module: trend alerts, preventive tips, voice/typing reminders
- ML placeholders for Gait, Typing, Voice; local storage for processed features
- Clean, modular, well-commented code for expansion
