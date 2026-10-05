# Apple: App Store Connect

| What you need | Where it is |
|---|---|
| App binary | Built on your Mac (it needs your Apple signing), see "Which file do I load in Xcode?" below |
| Listing text, keywords, review notes, subscriptions | `metadata/*.txt` (copy each file into the matching App Store Connect field) |
| iPhone 6.9" screenshots (1320x2868) | `screenshots/iphone-6.9/` |
| iPad 13" screenshots (2064x2752) | `screenshots/ipad-13/` |
| App icon | Already inside the app (`ios/Runner/Assets.xcassets/AppIcon.appiconset`); source art `assets/icon/icon.png` |
| Privacy manifest | `ios/Runner/PrivacyInfo.xcprivacy` (bundled automatically) |

## Which file do I load in Xcode?

You do **not** open the Flutter project in Xcode to publish. You load the built **archive**:

1. In Xcode: Settings > Accounts > **+** > Apple ID, and sign in with the account that owns team `WYS4LUJSP6`.
2. In Terminal, in the repo folder: `flutter build ipa --release`. This creates
   **`build/ios/archive/Runner.xcarchive`**. (A copy may already be on your Desktop as `ACT-SAT-Prep.xcarchive`.)
3. **Double-click `Runner.xcarchive`** (or `ACT-SAT-Prep.xcarchive`). Xcode opens the **Organizer** with the archive.
4. Click **Distribute App > App Store Connect > Distribute/Upload**, accept the automatic signing options, and finish.
5. After 15 to 60 minutes the build appears in App Store Connect under TestFlight / the app version.

If you ever need to edit the project in Xcode, open **`ios/Runner.xcworkspace`** (the `.xcworkspace`, not `.xcodeproj`).

Alternative: after step 1 and 2, `build/ios/ipa/*.ipa` is created; upload that file with the free **Transporter** app.

See `../../PUBLISHING.md` section 4 for the App Store Connect setup (agreements, subscriptions, review).
