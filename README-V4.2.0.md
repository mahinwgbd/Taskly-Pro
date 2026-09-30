# Taskly V4.2.1 — Google Drive Manual Cloud Backup

## Highlights
- Google Sign-In / Drive connection retained.
- Manual **Backup Now** uploads a complete Taskly JSON backup to the Drive `appDataFolder`.
- Manual **Restore** downloads the cloud backup and restores Tasks, Notes, Profile, Settings, and profile photo.
- A local safety snapshot is created before cloud restore.
- Cloud backup is validated before restore.
- Invalid/corrupt cloud backup is rejected.
- No automatic background upload: cloud data is uploaded only when the user taps **Backup Now**.
- Existing local JSON backup/restore remains available.

## Google OAuth
Configure the Web OAuth client ID and Android OAuth client as documented in the existing Google OAuth setup flow. The Android client must match package `com.taskly.app` and the appropriate SHA-1.

## Test
```powershell
flutter clean
flutter pub get
flutter analyze
flutter run -d emulator-5554
```

Then:
1. Settings → Google Drive Backup
2. Connect Google Drive
3. Tap **Backup Now**
4. Make a small local change
5. Tap **Restore** and confirm the cloud backup is restored

## Release
```powershell
flutter build apk --release --split-per-abi
```
