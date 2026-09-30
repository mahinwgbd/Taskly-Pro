# Taskly Pro 2.3 — Security + Encryption + App Lock

## Included
- App Lock with lifecycle-aware locking when Taskly leaves the foreground.
- Biometric unlock through Android device authentication.
- 4–8 digit PIN fallback stored as a salted hash derived from the device encryption key.
- AES-256-CBC encryption for Tasks and Notes before local SharedPreferences storage.
- Encryption key stored in Android secure storage.
- Existing plaintext Tasks/Notes are migrated to encrypted storage on startup.
- Backup restore writes Tasks/Notes back using encrypted local storage.
- Security settings page added under Settings.

## Important
- Exported JSON backups remain portable/plain JSON so users can restore them manually.
- App Lock protects access to the Taskly UI; Android device security remains the underlying trust boundary.
- The source was patched but Flutter analyze/build was not executed in this environment.
