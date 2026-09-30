# Taskly V4.1.0 — Backup & Restore

## Added
- JSON workspace backup/export.
- JSON backup import/restore.
- Tasks and notes included with stable IDs and normalized serialization.
- Profile fields included.
- Profile photo included as Base64 when the local photo exists.
- Theme, language, notification and onboarding preferences included.
- Restore confirmation dialog to prevent accidental replacement.
- Automatic workspace reload after restore.
- Backup & Restore entry added to Settings.
- Version bumped to 4.1.0+41.

## Safety
- Imported tasks/notes are validated through the existing model serializers.
- Duplicate IDs and invalid records are skipped.
- Backup format has its own version field for future migrations.
