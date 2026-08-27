# Publishing ACT Prep — App Store Connect walkthrough

Everything you need to take this project from Xcode to a live, paid listing on the App Store.
Work top to bottom; each part depends on the one before it.

**Copy-paste values are in code blocks.** Anything in `<angle brackets>` is a decision only you can make.

---

## Part 0 — Before you touch App Store Connect

| Item | Status | Notes |
|---|---|---|
| Apple Developer Program membership ($99/yr) | Required | <https://developer.apple.com/programs/enroll/> |
| Paid Applications Agreement signed | **Required for any paid app or subscription** | See Part 1 — subscriptions cannot be sold until this is active |
| Team ID | Already set | `WYS4LUJSP6` is configured in the project |
| Bundle ID | Already set | `Wuilmer.Ponte.ACT-prep` |
| App icon | Done | 1024px light, dark, and tinted variants are in the asset catalog |
| Screenshots | **You must add these** | See Part 7 — the only remaining blocker |

> **The single most common cause of "my subscription doesn't load in TestFlight/production"** is an
> unsigned Paid Applications Agreement or missing banking/tax details. Do Part 1 first, before anything else.

---

## Part 1 — Agreements, Tax, and Banking

1. Sign in at <https://appstoreconnect.apple.com> with your Apple Developer account.
2. Go to **Business** (previously "Agreements, Tax, and Banking").
3. Under **Agreements**, find **Paid Applications**. If status is not `Active`:
   - Click **Request**, read and accept the agreement.
4. Add a **Bank Account** (where Apple pays you) — this needs your account and routing details.
5. Complete **Tax Forms**. At minimum, the U.S. tax form; add others for regions you want to sell in.

Wait until **Paid Applications** shows `Active`. This can take anywhere from minutes to a couple of
days. **Your in-app purchases will not load in the app until it is active.**

---

## Part 2 — Register the Bundle ID

Usually Xcode does this automatically, but confirm it:

1. Go to <https://developer.apple.com/account/resources/identifiers/list>.
2. Look for `Wuilmer.Ponte.ACT-prep`. If it is missing:
   - Click **+** → **App IDs** → **App** → **Continue**.
   - Description: `ACT Prep`
   - Bundle ID: **Explicit** →
     ```
     Wuilmer.Ponte.ACT-prep
     ```
   - Capabilities: leave defaults. **In-App Purchase is enabled by default and cannot be unchecked** — that is correct.
   - **Continue** → **Register**.

> Because the app also ships as a Mac (Catalyst) app, no second bundle ID is needed —
> `DERIVE_MACCATALYST_PRODUCT_BUNDLE_IDENTIFIER` is set to `NO`, so the Mac build uses the same
> identifier and the same App Store listing.

---

## Part 3 — Create the app record

1. App Store Connect → **Apps** → **+** → **New App**.
2. Fill in:

   | Field | Value |
   |---|---|
   | Platforms | Check **iOS** *and* **macOS** |
   | Name | `ACT Prep: Exam Practice` |
   | Primary Language | `English (U.S.)` |
   | Bundle ID | `Wuilmer.Ponte.ACT-prep` |
   | SKU | `ACTPREP001` |
   | User Access | `Full Access` |

3. Click **Create**.

> **On the name:** App Store names max out at 30 characters. `ACT Prep: Exam Practice` is 23.
> Apple rejects names that imply an affiliation you don't have, so do **not** use names like
> "Official ACT Prep". If the name is taken, try `ACT Prep — Practice Tests`.

---

## Part 4 — Create the subscription products

This is the part with the most steps. Go to your app → **Monetization** → **Subscriptions**.

### 4.1 Create the subscription group

1. Click **Create** next to Subscription Groups.
2. **Reference Name** (internal only):
   ```
   ACT Prep Pro
   ```
3. Click **Create**.
4. Open the group → **Localizations** → add **English (U.S.)**:
   - Subscription Group Display Name:
     ```
     ACT Prep Pro
     ```

> Both plans go in **the same group**. That is what lets a subscriber switch between monthly and
> yearly without double-paying, and it is what the app's `StoreManager` expects.

### 4.2 Monthly subscription

Inside the group, click **Create** (subscription):

| Field | Value |
|---|---|
| Reference Name | `Pro Monthly` |
| Product ID | `actprep.pro.monthly` |

Then on the product page:

1. **Subscription Duration**: `1 Month`
2. **Subscription Prices** → **Add Subscription Price** → United States → **$19.99** → Next → confirm
   the auto-generated worldwide prices → **Done**.
3. **Localizations** → **English (U.S.)**:
   - Display Name:
     ```
     Pro Monthly
     ```
   - Description:
     ```
     Full access to all 1,040 practice questions, 40 tutorials, and 15 mock exams. Billed monthly.
     ```
4. **Review Information** → upload a screenshot of your paywall (see Part 7) and leave review notes blank.

### 4.3 Yearly subscription

Click **Create** again in the same group:

| Field | Value |
|---|---|
| Reference Name | `Pro Yearly` |
| Product ID | `actprep.pro.yearly` |

1. **Subscription Duration**: `1 Year`
2. **Subscription Prices** → United States → **$99.99** → confirm worldwide prices → **Done**.
3. **Localizations** → **English (U.S.)**:
   - Display Name:
     ```
     Pro Yearly
     ```
   - Description:
     ```
     Full access to all 1,040 practice questions, 40 tutorials, and 15 mock exams. Billed yearly.
     ```
4. **Review Information** → upload the same paywall screenshot.

### 4.4 Add the free trial (yearly only)

The app's paywall shows a "Start Free Trial" button when an introductory offer exists, so create one:

1. Open **Pro Yearly** → **Subscription Prices** section → **Introductory Offers** → **Create Introductory Offer**.
2. Countries: **Select All**.
3. Start date: today. End date: **No End Date**.
4. Type: **Free**
5. Duration: **1 Week**
6. **Confirm**.

### 4.5 Set the ranking

Back on the group page, set **Subscription Ranking** (the upgrade/downgrade order):

| Level | Subscription |
|---|---|
| 1 (highest) | Pro Yearly |
| 2 | Pro Monthly |

This makes yearly an *upgrade* from monthly, so switching takes effect immediately with a prorated refund.

### 4.6 Verify against the code

These IDs are hardcoded in `ACT prep/Store/StoreManager.swift`. They must match **exactly** —
a typo means products silently fail to load:

```swift
static let monthlyID = "actprep.pro.monthly"
static let yearlyID  = "actprep.pro.yearly"
```

---

## Part 5 — App Information and Pricing

### 5.1 App Information (left sidebar)

| Field | Value |
|---|---|
| Subtitle | `Practice tests & tutorials` |
| Category (Primary) | `Education` |
| Category (Secondary) | `Reference` |
| Content Rights | Check **"contains, shows, or accesses third-party content"** → **No** |
| Age Rating | Complete the questionnaire — answer **None** to everything. Result should be **4+** |

### 5.2 Pricing and Availability

- **Price**: `Free` — the app itself is free; revenue comes from the subscriptions.
- **Availability**: All countries and regions (or narrow it if you prefer).

---

## Part 6 — App icon (done)

`ACT prep/Assets.xcassets/AppIcon.appiconset` contains three 1024×1024 PNGs — the light icon plus
the dark and tinted variants iOS 18+ uses on the Home Screen. All are full-bleed squares with no
alpha channel and no baked-in rounded corners, which is what Apple requires; the system applies the
mask and the corner radius itself.

To change the artwork later, replace `AppIcon-1024.png` and regenerate the two variants. Keep the
design visually distinct from official ACT, Inc. branding to avoid a Guideline 5.2.1 rejection.

---

## Part 7 — Screenshots

Required sizes (Apple accepts one set per device family and scales down):

| Platform | Required size | How to capture |
|---|---|---|
| iPhone 6.9" | 1320 × 2868 | iPhone 17 Pro Max simulator |
| iPad 13" | 2064 × 2752 | iPad Pro 13-inch (M5) simulator |
| macOS | 2880 × 1800 | Mac app window |

Capture with the simulator running and `Cmd+S` (saves to Desktop), or:

```bash
xcrun simctl io booted screenshot ~/Desktop/shot.png
```

**Suggested five screenshots**, in this order — they map to the app's strongest screens:

1. **Home** — daily goal, streak, target score
2. **Tutorials grid** — the icon grid, showing breadth
3. **A tutorial detail** — worked example with the solution revealed
4. **A practice question** — with the green correct-answer feedback
5. **Exam results** — the big composite score

You need at least 1 per size; 3–5 converts better.

---

## Part 8 — Store listing copy

Paste these into the **iOS App** → **1.0 Prepare for Submission** page.

### Promotional Text (170 char max, editable without review)

```
Start free with 10 questions per subject. Unlock 1,040 questions, 40 Math and Science tutorials, and 15 timed mock exams on iPhone, iPad, and Mac.
```

### Description

```
Prepare for the ACT with a study plan that fits your schedule — on iPhone, iPad, and Mac.

ACT Prep combines targeted practice, clear tutorials, and realistic timed exams so you always know what to study next.

WHAT'S INSIDE

• 1,040 practice questions across English, Math, Reading, and Science — every one with a written explanation
• 40 tutorials covering Math and Science, each with worked examples, key facts, and test-day tips
• 15 mock exams, each available in two formats

TWO WAYS TO TAKE A MOCK EXAM

Quick — 47 questions in 44 minutes. A condensed run through all four sections when you only have a lunch break.

Full-Length — 171 questions in 2 hours 45 minutes, following real ACT section structure and timing. Build the stamina the real test demands.

BUILT FOR REAL STUDYING

• Set a target score and a daily practice goal when you first open the app
• Keep a streak going with short daily sessions
• Add your test date for a countdown on the home screen
• Track accuracy by subject and watch your composite score trend upward
• Filter practice by topic to drill exactly what you're getting wrong
• Jump between questions during an exam with the question grid, just like the real test interface

ONE SUBSCRIPTION, ALL YOUR DEVICES

Study on your iPhone between classes, review tutorials on iPad, and take full-length exams on your Mac. Your subscription works everywhere you're signed in with the same Apple Account.

START FREE

Try 10 practice questions in each subject, 2 tutorials per subject, and the first mock exam at no cost. Subscribe when you're ready for everything.

ACT Prep is an independent study app. It is not affiliated with, endorsed by, or sponsored by ACT, Inc. ACT is a registered trademark of ACT, Inc. All questions, passages, and tutorials in this app are original practice material.
```

### Keywords (100 char max, comma-separated, no spaces after commas)

```
ACT,test prep,exam,practice test,college,SAT,study,tutor,math,science,english,reading,mock exam
```

### Support URL

```
https://chamowil.github.io/act-prep-support/
```

### Marketing URL (optional)

```
https://chamowil.github.io/act-prep-support/
```

### Privacy Policy URL

```
https://chamowil.github.io/act-prep-support/privacy.html
```

### License Agreement (EULA)

App Store Connect → **App Information** → **License Agreement**. Either keep Apple's standard EULA,
or choose **Custom** and paste the contents of
<https://chamowil.github.io/act-prep-support/terms.html>.

---

## Part 9 — App Privacy

App Store Connect → your app → **App Privacy** → **Get Started**.

Because the app stores everything locally and has no analytics or network calls of its own:

1. "Do you or your third-party partners collect data from this app?" → **No, we do not collect data from this app**
2. Confirm and **Publish**.

This matches [`ACT prep/PrivacyInfo.xcprivacy`](ACT%20prep/PrivacyInfo.xcprivacy), which declares no
tracking and no collected data types.

> If you later add analytics, crash reporting, or ads, you **must** come back and update this, and
> update the privacy manifest and privacy policy too.

---

## Part 10 — Archive and upload

1. In Xcode, select the scheme **ACT prep**.
2. Bump the build number if you're re-uploading — every upload needs a unique
   `CURRENT_PROJECT_VERSION`.

### iOS build

3. Destination: **Any iOS Device (arm64)**.
4. **Product → Archive**.
5. When Organizer opens: **Distribute App** → **App Store Connect** → **Upload** → keep the defaults
   → **Upload**.

### macOS build

6. Destination: **My Mac (Mac Catalyst)**.
7. **Product → Archive** → **Distribute App** → **App Store Connect** → **Upload**.

Processing takes 15–60 minutes. You'll get an email when each build is ready.

> **If it fails on "missing compliance"**, see Part 11.

---

## Part 11 — Export compliance

When the build appears, App Store Connect asks about encryption. The app uses only HTTPS via
Apple's own frameworks, so:

- "Does your app use encryption?" → **Yes** (HTTPS counts)
- "Does it qualify for exemptions?" → **Yes** (standard encryption only)

To skip this prompt on every future upload, add this to your target's Info settings in Xcode:

| Key | Value |
|---|---|
| `ITSAppUsesNonExemptEncryption` | `NO` |

---

## Part 12 — Test with TestFlight first

Do not submit blind. Install the real build and verify the purchase flow end to end:

1. App Store Connect → **TestFlight** → your build → add yourself under **Internal Testing**.
2. Install via the TestFlight app.
3. **Create a Sandbox tester** if you haven't: **Users and Access** → **Sandbox** → **Testers** → **+**.
   Use an email address that is *not* an existing Apple Account.
4. On your device: **Settings → Developer → Sandbox Apple Account** → sign in with the sandbox tester.
5. In the app, open the paywall and confirm:
   - [ ] Both plans load with the correct prices ($19.99 / $99.99)
   - [ ] The yearly plan shows the free-trial wording and a "Save %" badge
   - [ ] Purchasing unlocks tutorials, questions 11+, and mock exams 2–15
   - [ ] **Restore Purchases** works after deleting and reinstalling the app
   - [ ] **Settings → Manage Subscription** opens the system sheet

> Sandbox subscriptions renew on an accelerated clock (1 month ≈ 5 minutes) and auto-cancel after
> 6 renewals. That is expected.

---

## Part 13 — Submit for review

1. Go to **1.0 Prepare for Submission**.
2. Attach the processed build (**Build** section → **+**).
3. Under **In-App Purchases and Subscriptions**, **add both subscriptions to the submission**.
   *First-time subscriptions must be submitted with the app binary or they will not be reviewed.*
4. **App Review Information**:
   - Sign-in required: **No** (the app has no account system)
   - Notes:
     ```
     ACT Prep is an independent study app for the ACT college entrance exam. It is not affiliated
     with ACT, Inc., and this is disclosed in the app description, the Terms of Use, and the support
     site. All questions, passages, and tutorials are original material written for this app.

     No account or login is required. To review the subscription:
     Open the Settings tab and tap "Upgrade to Pro", or open any locked tutorial or mock exam.

     Free tier available without purchase: the diagnostic test, a daily question, 10 practice
     questions per subject, 2 tutorials per subject, the English flashcard decks, and Mock Exam 1.
     ```
5. **Version Release**: `Automatically release this version` (or hold it if you want to coordinate a launch).
6. **Add for Review** → **Submit**.

Review typically takes 24–48 hours.

---

## Common rejection reasons for this specific app

| Reason | How to avoid it |
|---|---|
| **Guideline 3.1.2 — subscription info missing** | Already handled: the paywall states billing terms and links Privacy Policy + Terms. Don't remove that footer. |
| **Guideline 5.2.1 — implied affiliation** | Never imply this is official ACT material. The disclaimer must stay in the description, app, and support site. |
| **Guideline 2.1 — IAP not submitted** | Add both subscriptions to the *first* submission (Part 13, step 3). |
| **Guideline 4.2 — minimum functionality** | Not a risk here; there's substantial content. |
| **Missing/incorrect privacy answers** | Part 9 must match the privacy manifest. Keep them in sync. |
| **Metadata rejection — screenshots** | Use real screenshots of the running app, not marketing mockups with invented UI. |

---

## After launch

- **Prices** can be changed any time in **Monetization → Subscriptions** without a new build.
- **Promotional Text** can be updated without review.
- **New questions or tutorials** are just JSON edits in `ACT prep/Resources/` plus a new build.
- Watch **Analytics → Metrics** for conversion rate and churn on the paywall.

---

## Related files

| File | Purpose |
|---|---|
| [`ACT prep/Store/StoreManager.swift`](ACT%20prep/Store/StoreManager.swift) | Product IDs, entitlement checks, free-tier limits |
| [`ACT prep/Store/PaywallView.swift`](ACT%20prep/Store/PaywallView.swift) | Paywall UI and required subscription disclosures |
| [`ACT prep/ACTprep.storekit`](ACT%20prep/ACTprep.storekit) | Local test configuration — mirrors what you create in Part 4 |
| [`ACT prep/PrivacyInfo.xcprivacy`](ACT%20prep/PrivacyInfo.xcprivacy) | Privacy manifest — must match Part 9 |
