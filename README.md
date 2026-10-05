# ACT & SAT Prep

A Flutter study app for the **ACT** and the **SAT**, for iOS, iPadOS, and Android from one codebase.

- **1,466 original practice questions** — 1,040 ACT (English, Math, Reading, Science) and 426 SAT (Reading & Writing, Math)
- **48 tutorials**, **245 flashcards** (spaced repetition), a 60-entry ACT quick reference
- **ACT Writing**: guides, 12 prompts, a 40-minute autosaving editor, 6 scored sample essays
- **21 mock exams** (15 ACT, 6 SAT) in Quick and Full-Length modes, plus a diagnostic
- Score estimate, topic heatmap, streaks, badges, question of the day, on-screen scratchpad
- Free tier plus a Pro subscription (`in_app_purchase`: StoreKit on iOS, Play Billing on Android)

All content is original; the app is not affiliated with ACT, Inc. or the College Board.

## Run

```bash
flutter pub get
flutter run                          # any device
flutter run --dart-define=DEMO_DATA=sat   # seeded demo data, for screenshots (act | sat)
flutter test                         # content validation + UI smoke tests
```

Requires Flutter 3.47+ (Dart 3.13). Subscriptions only work in builds installed from TestFlight or a Play testing track.

## Layout

```
lib/
  config.dart        product IDs, URLs, free-tier limits (keep in sync with the stores)
  data/content.dart  loads every JSON asset, builds mock-exam question sets
  models/            Subject/ExamType (scoring, section timing), Question, study content, exam results
  state/             settings, progress + flashcard scheduler, exam session, store (subscriptions)
  ui/                screens and widgets
assets/act, assets/sat   question, tutorial, flashcard, writing JSON
tools/               generators for SAT content (see below)
store_assets/        Google Play graphics and App Store screenshots
legacy_swiftui/      the original SwiftUI ACT-only app, kept for reference
```

## Content

Question JSON shape: `id, subject, topic, difficulty, prompt, choices[4], correctIndex, explanation`, plus optional
`passageId` (ACT) or `stimulus` (SAT Reading & Writing). `flutter test` fails on any malformed question.

SAT content is built by scripts: `python3 tools/gen_sat_math.py` (answers computed from parameters),
`python3 tools/build_sat_rw.py` (from the hand-written items in `tools/sat_rw_part*.py`), and
`python3 tools/build_sat_study.py` (flashcards and tutorials).

## Publishing

See [PUBLISHING.md](PUBLISHING.md) (Google Play Console and App Store Connect) and
[STORE_LISTING.md](STORE_LISTING.md) (copy-paste listing text).
