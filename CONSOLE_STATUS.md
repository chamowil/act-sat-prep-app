# Store console status (as of 5 Oct 2026)

Both consoles were filled in from `publish/`. Items marked **YOU** need your credentials or a decision.

## Google Play Console: app "ACT & SAT Prep" (`com.wuilmer.actsatprep`)

Done:
- App created (App, Free), declarations accepted.
- Main store listing: short + full description, 512 icon, feature graphic, 5 phone screenshots (draft saved).
- App content: privacy policy, ads (none), sign-in details (no restrictions), content rating (IARC questionnaire submitted), target audience 13+,
  data safety (no data collected), advertising ID (no), government apps (no), financial features (none), health (none).
- Store settings: category Education, contact email and website.

**YOU** to do:
1. Upload `app-release.aab` (Desktop copy: `~/Desktop/ACT-SAT-Prep-android.aab`) to Testing > Internal testing. The file is 53 MB, over the automation upload limit.
2. After the first upload: Monetize > Subscriptions, create `actprep.pro.monthly` and `actprep.pro.yearly` (see `publish/android/metadata/play_console_answers.txt`).
3. Tablet screenshots (7" / 10") if Play asks for them; the iPad images are 4:3 and do not fit Play's 16:9 / 9:16 rule.
4. Personal accounts: closed test with 12 testers for 14 days before production access.

## App Store Connect: app "ACT & SAT Prep" (Apple ID 6819400930, bundle `Wuilmer.Ponte.ACT-SAT-prep`)

Done:
- Bundle ID registered; app record created (iOS, SKU ACTSATPREP001, English U.S.).
- Version 1.0: promo text, description, keywords, support + marketing URLs, copyright, 5 iPhone + 3 iPad screenshots, manual release selected.
- App Information: subtitle, categories (Education / Reference), content rights (no third-party content), age rating (4+).
- App Privacy: privacy policy URL and "Data Not Collected" answered.
- Pricing: Free, all 175 countries.
- Subscription group "ACT Prep Pro"; **Pro Yearly** (`actprep.pro.yearly`) with price $99.99 (all countries) and English display name/description.

**YOU** to do:
1. App Privacy page: click **Publish**.
2. App Review block: it requires a **phone number** before it will save. Re-enter the contact (Wuilmer Ponte, chamowil@outlook.com) and paste the notes from `publish/apple/metadata/review_notes.txt`; leave "Sign-in required" off.
3. Create **Pro Monthly** (`actprep.pro.monthly`, 1 month, $19.99, display name "Pro Monthly", description "Unlock all ACT and SAT content. Billed monthly.").
4. Pro Yearly: add the introductory offer (Free, 1 week, all countries) and a review screenshot of the paywall; set group ranking (Yearly above Monthly).
5. Upload the build: sign into Xcode, then double-click `~/Desktop/ACT-SAT-Prep.xcarchive` > Distribute App > App Store Connect. Then attach it to version 1.0 and add both subscriptions to the submission.
6. In Chrome, a "Leave site?" dialog may be open on the original App Store Connect tab; choose Leave to dismiss it.
7. Submit for review when ready.
