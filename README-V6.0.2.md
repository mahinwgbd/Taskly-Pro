# Taskly V6.0.2

This build upgrades the V6.0.1 project with Google Drive backup, a redesigned productivity progress ring, expanded Home/Profile identity details, and a Meet the Developer section.

## Google Drive backup

Taskly uses Google Sign-In and the Google Drive `appDataFolder` scope. The backup is a private `taskly_backup.json` file in the app's Drive data area. It contains tasks, notes, profile information and the selected profile photo.

The implementation uses the current Flutter Google Sign-In flow (authentication followed by authorization for the Drive scope) and the Google APIs bridge. The current Google Sign-In API requires initialization and explicit scope authorization for non-basic scopes.

### Required one-time Google Cloud configuration

1. Create or select a Google Cloud project.
2. Enable **Google Drive API**.
3. Create an **Android OAuth client** for package `com.interestinate.flutter_todolist` and add the SHA-1 fingerprints used by your debug/release builds.
4. Create a **Web application OAuth client** in the same project.
5. Use that Web client ID as Taskly's `serverClientId`.
6. Start the app with:

```powershell
flutter pub get
flutter run -d emulator-5554 --dart-define=TASKLY_GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

For an APK:

```powershell
flutter build apk --release --dart-define=TASKLY_GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

The OAuth client ID is intentionally not hard-coded into this source archive. The app will compile without it, but Google Drive connection will remain unavailable until the OAuth configuration is supplied.

## Backup behavior

- Connect Google Drive from **Settings → Google Drive Backup**.
- On first connection, Taskly compares local and Drive backup timestamps.
- If Drive has newer data, it restores the Drive backup locally.
- Otherwise, the current local workspace is uploaded.
- After connection, task/profile changes schedule an automatic sync.
- Manual **Sync now** is available from Settings.
- Uninstalling the app removes local data but does not remove the Drive backup. Reinstalling and connecting the same Google account can restore it.

## V6.0.2 UI

- Home progress ring now animates and has a dedicated 100% completion state.
- Motivational copy changes as progress reaches 10%, 20%, 30% ... 100%.
- Home/profile identity summary includes Name, Profession, Designation, Company/Institute, Blood group, Phone, Mail and Address when values are available.
- Settings includes **Meet the developer** with Mahin Mahbub Ullah's provided details and the existing profile image asset.


## Default data policy
Taskly starts with empty Tasks and Notes. No demo/test tasks or notes are seeded. V5 task/note SharedPreferences are not automatically migrated into V6.0.2.
