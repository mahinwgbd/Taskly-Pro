# Taskly V3.1.7

## This release
- Dark mode readability overhaul: primary text now follows the active Material color scheme.
- Stronger section/card outlines across Home, Tasks, Notes, Focus spaces, and Settings.
- FAB is visually lowered into a dedicated bottom-nav cradle so it does not cover Notes or Settings.
- Google Drive setup UX improved with a Web OAuth Client ID setup sheet and clearer configuration errors.
- Version: 3.1.7+22

## Google Drive / Google Sign-In
The Flutter `google_sign_in` 7.x API requires Android OAuth configuration. When `google-services.json` is not used, Taskly must receive the **Web application OAuth client ID** as `serverClientId`.

### Option A — build-time configuration
```powershell
flutter run -d emulator-5554 --dart-define=TASKLY_GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
flutter build apk --debug --dart-define=TASKLY_GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

### Option B — in-app configuration
Open **Settings → Google Drive Backup → Google OAuth Setup**, paste the Web application OAuth client ID, save it, then fully restart Taskly.

### Google Cloud requirements
1. Create an Android OAuth client for package `com.interestinate.flutter_todolist`.
2. Add the SHA-1 of the certificate used to sign the debug APK.
3. Create a Web application OAuth client and use that client ID as Taskly's `serverClientId`.
4. Ensure the OAuth consent screen is configured and the Google Drive API is enabled.

For a debug build, the SHA-1 can be obtained from the Android Gradle signing report:
```powershell
cd android
.\gradlew signingReport
```

The Google Web client ID is not a password or secret, but the OAuth client configuration must match the Android package name and signing certificate.
