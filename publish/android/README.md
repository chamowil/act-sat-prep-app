# Android: Google Play Console

| What you need | Where it is |
|---|---|
| App bundle (`.aab`) | Attached to this repo's GitHub Release (`app-release.aab`), or build it: `flutter build appbundle --release` |
| Listing text and answers to policy forms | `metadata/*.txt` |
| Hi-res icon 512x512 | `graphics/icon-512.png` |
| Feature graphic 1024x500 | `graphics/feature-graphic-1024x500.png` |
| Phone screenshots | `screenshots/` |

## Upload

1. Play Console > your app > Testing > **Internal testing** > Create release > upload `app-release.aab`. Accept Play App Signing.
2. Create the subscriptions listed in `metadata/play_console_answers.txt`.
3. Fill in the store listing from `metadata/` and the App content forms.

**Signing:** the bundle is signed with an *upload key* that is **not** in this repository (it must stay secret).
A rebuild on another computer needs `android/key.properties` and `android/app/upload-keystore.jks`, or you can create a new upload
key in Play Console (Setup > App signing > Request upload key reset).

See `../../PUBLISHING.md` section 3 for the full walkthrough.
