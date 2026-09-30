# Taskly V6.1.3

V6.1.3 is a productivity-focused upgrade built on the V6.0.2 empty-defaults base.

## Task upgrades
- Subtasks with completion progress
- Smart Views: All, Today, Overdue, High Priority
- Focus Mode with a 25-minute Pomodoro timer
- Productivity streak in Insights
- Achievement level in Insights
- Existing priority, category, repeat, reminder, calendar and search features retained
- Subtasks are included in local persistence and Google Drive backup

## Notes upgrade
Notes are now a first-class workspace section rather than plain strings.

- Dedicated Notes tab
- New/Edit note editor
- Title + body
- Tags
- Pin/unpin
- Six note color choices
- Checklist items with inline completion
- Created/updated timestamps
- Grid/List view
- Search title, body and tags
- Pinned-only filter
- Delete notes
- Notes are included in Google Drive backup
- Old V6 string notes are migrated automatically when present

## Empty defaults
New installs remain empty: no demo tasks and no demo notes are created.

## Google Drive
The existing private appDataFolder sync remains in place. Google OAuth credentials still need to be configured by the app owner using the existing dart-define setup.

## Run
```powershell
flutter pub get
flutter analyze
flutter run -d emulator-5554 --dart-define=TASKLY_GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```
