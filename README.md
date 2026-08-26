# ACT Prep

A SwiftUI study app for the ACT, built for **iPhone, iPad, and Mac** (Mac Catalyst) from a single
target.

- **520 original practice questions** across English, Math, Reading, and Science, each with an
  explanation.
- **40 tutorials** covering Math and Science, with worked examples, key facts, and test-day tips.
- **15 mock exams**, each runnable in **Quick** (47 questions / 44 min) or **Full-Length**
  (171 questions / 2 hr 45 min, real ACT section timing) mode.
- **Auto-renewing subscription** (StoreKit 2) with a free tier.

All questions, passages, and tutorials are original material. ACT Prep is not affiliated with ACT, Inc.

## Requirements

| | |
|---|---|
| Xcode | 26.0 or later |
| iOS / iPadOS | 18.0 or later |
| macOS | 15.0 or later (Mac Catalyst) |
| Swift | 5.0 mode |

## Running it

Open `ACT prep.xcodeproj` and press **Run**. The scheme references
[`ACT prep/ACTprep.storekit`](ACT%20prep/ACTprep.storekit), so subscriptions work in the simulator
with test transactions — no App Store Connect setup needed for local development.

> Launching the built `.app` outside Xcode (via `simctl`, for example) does **not** attach the
> StoreKit configuration, so the paywall will show its "options unavailable" state. That is expected.

## Project layout

```
ACT prep/
├── ACT_prepApp.swift          App entry point
├── ContentView.swift          Five-tab shell (sidebar-adaptable on iPad/Mac)
├── ACTprep.storekit           Local StoreKit test configuration
├── PrivacyInfo.xcprivacy      Privacy manifest
├── Models/
│   ├── Models.swift           Subject, Question, Passage, QuestionBank, ACT scoring
│   ├── MockExam.swift         Exam definitions, modes, results
│   └── Tutorial.swift         Tutorial model, library, completion tracking
├── Engine/
│   ├── ExamSession.swift      Section timers, answers, scoring
│   ├── ProgressStore.swift    Persisted exam results & practice history
│   └── UserSettings.swift     Study plan, daily goal, streak
├── Store/
│   ├── StoreManager.swift     StoreKit 2 products, entitlements, gating
│   └── PaywallView.swift      Subscription paywall
├── Views/                     Home, Learn, Practice, Exam runner, Progress, Settings, Onboarding
└── Resources/
    ├── Questions/             520 questions + 41 passages (JSON)
    └── Tutorials/             40 tutorials (JSON)
```

## Content format

Questions and tutorials are plain JSON bundled with the app and decoded at launch by
`QuestionBank` and `TutorialLibrary`. To add content, append objects to the relevant file — no code
changes are required as long as the schema matches.

Validate the bundled content before committing:

```bash
python3 -c "
import json, glob, os
os.chdir('ACT prep/Resources')
qs = [q for f in glob.glob('Questions/*_questions.json') for q in json.load(open(f))]
ts = [t for f in glob.glob('Tutorials/*_tutorials.json') for t in json.load(open(f))]
assert all(len(q['choices']) == 4 and 0 <= q['correctIndex'] < 4 for q in qs)
print(len(qs), 'questions,', len(ts), 'tutorials')
"
```

## Subscription

Two auto-renewing products in one subscription group (`ACT Prep Pro`):

| Product ID | Plan |
|---|---|
| `actprep.pro.monthly` | Monthly |
| `actprep.pro.yearly` | Yearly (7-day free trial) |

Free tier, defined in `StoreManager`: 10 practice questions per subject, 2 tutorials per subject,
and Mock Exam 1.

See [`APPSTORE.md`](APPSTORE.md) for the full App Store Connect setup and submission walkthrough.

## Support & legal

Hosted from the [`act-prep-support`](https://github.com/chamowil/act-prep-support) repository:

- Support — <https://chamowil.github.io/act-prep-support/>
- Privacy Policy — <https://chamowil.github.io/act-prep-support/privacy.html>
- Terms of Use — <https://chamowil.github.io/act-prep-support/terms.html>

---

ACT® is a registered trademark of ACT, Inc. This app is an independent study aid and is not
affiliated with, endorsed by, or sponsored by ACT, Inc.
