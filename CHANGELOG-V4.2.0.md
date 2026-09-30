# Taskly V4.2.1

## Google Drive Manual Cloud Backup
- Added explicit Backup Now action.
- Added explicit Restore action.
- Cloud backup uses Taskly's portable JSON backup format.
- Cloud file is stored in Drive appDataFolder as `taskly_backup_v4_2.json`.
- Added cloud backup validation before restore.
- Added local pre-restore safety snapshot.
- Added cloud backup timestamp tracking.
- Added manual-mode messaging to avoid silent uploads or overwrites.
- Preserved V4.1 local Backup & Restore.

## Architecture
Automatic cloud synchronization is intentionally disabled in V4.2. Conflict resolution and automatic synchronization are reserved for a later release after the manual backup/restore path is validated.
