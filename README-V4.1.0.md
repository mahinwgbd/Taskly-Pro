# Taskly V4.1.0

Taskly V4.1 adds portable local backup and restore.

### Export
Settings → Backup & Restore → Export backup

The JSON backup contains:
- Tasks
- Notes
- Profile data
- Profile photo (when available)
- Theme/language/notification/onboarding settings

### Restore
Settings → Backup & Restore → Restore backup

Restore asks for confirmation and reloads the workspace after import.

### Build
```powershell
flutter clean
flutter pub get
flutter analyze
flutter build apk --release --split-per-abi
```
