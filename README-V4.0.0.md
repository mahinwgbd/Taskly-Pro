# Taskly V4.0.0 — Production Polish

## Stability and performance release

### Included
- Version bumped to 4.0.0+40.
- Stable task IDs are now preserved by `TodoItem.copyWith`.
- Centralized task JSON serialization/deserialization.
- Workspace schema version marker (`4`).
- Last-known-good task/note snapshots are retained locally before writes.
- Safer workspace loading with malformed-data protection and duplicate-ID filtering.
- Reminder reconciliation on cold start and app resume.
- Notification initialization is non-fatal.
- Exact Android reminders gracefully fall back to inexact idle-aware scheduling when exact-alarm access is unavailable.
- Existing Calendar, Notes, Tags, Pin, Archive/Trash, Note-to-Task, recurring tasks and localization remain intact.

## Validation
Run on the development machine:

```powershell
flutter clean
flutter pub get
flutter analyze
flutter run -d emulator-5554
```

For release APKs:

```powershell
flutter build apk --release --split-per-abi
```
