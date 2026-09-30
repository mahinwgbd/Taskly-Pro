# Taskly V4.2.3

## Build fixes
- Updated flutter_local_notifications calls to the v22 named-parameter API (`show`, `initialize`, `cancel`).
- Updated file_picker calls for v12+ static API (`FilePicker.saveFile`, `FilePicker.pickFile`) and direct byte reading.
- Fixed `_NoteCard` constructor to receive the required `onConvertToTask` callback.
- Bumped app version to 4.2.3+44.

These changes address the compile errors reported while running Taskly V4.2.2.
