# Taskly V3.7.0 — Calendar + Reminders + Recurring Tasks

- Calendar remains integrated with the task model.
- Task reminders now use Android local notifications.
- Reminder scheduling uses the device IANA timezone.
- Daily, Weekly, Monthly, Weekdays and Weekends recurrence are supported.
- Completing a recurring task creates the next occurrence and schedules its reminder.
- Existing task records remain compatible; tasks without an id receive one automatically.

## Test
flutter clean
flutter pub get
flutter run -d emulator-5554

## Release
flutter build apk --release --split-per-abi
