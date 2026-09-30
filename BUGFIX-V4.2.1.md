# Taskly V4.2.1 — Dark Notes + Notifications Fix

## Fixed

1. Dark mode Quick Notes cards no longer use the light pastel card background. They now use a dedicated dark surface while retaining readable text and purple accents.
2. Dark mode Notes list cards use the same dark surface.
3. Settings > Notifications now controls the actual notification scheduler, not only a saved preference.
4. Turning notifications OFF cancels all scheduled notifications.
5. Turning notifications ON requests Android notification permission, checks exact-alarm access, and re-syncs saved task reminders.
6. Task reminder scheduling now respects the notification preference before scheduling.
7. Android exact-alarm permission is requested only when needed.
8. Existing POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED and SCHEDULE_EXACT_ALARM manifest entries/boot receivers are retained.

## Version

4.2.1+42
