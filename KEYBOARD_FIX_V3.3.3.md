# Taskly V3.3.3 — Notes Keyboard/Layout Fix

## Fixed
- Note editor is now inside a draggable bottom sheet.
- Drag the sheet upward to expand it up to 97% of the screen.
- The editor content is vertically scrollable when the keyboard is visible.
- Tapping the title automatically scrolls the title into view.
- Tapping the rich-text body automatically scrolls the editor into view.
- Tags are also brought into view when focused.
- The rich-text editor keeps a stable editing area instead of collapsing when the keyboard opens.
- Keyboard-dismiss-on-drag is enabled for the editor sheet.

## Build
```powershell
flutter clean
flutter pub get
flutter build apk --release --split-per-abi
```

For modern ARM64 phones use:
`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
