# Taskly Pro 1.0.0

Taskly Pro is the premium product line built on the Taskly 4.2.3 workspace foundation.

## Included foundation
- Advanced Tasks
- Advanced Notes
- Calendar and reminders
- Local backup/restore
- Google Drive manual backup
- Insights
- Focus
- Dedicated Taskly Pro hub

## Compatibility
The Pro edition keeps the existing Taskly data keys and JSON model so existing workspace data remains compatible.

## Build
```powershell
flutter clean
flutter pub get
flutter analyze
flutter build apk --release --split-per-abi
```

This release does not include a payment/subscription SDK yet. Monetization and entitlement verification should be added separately after the core Pro build is stable.
