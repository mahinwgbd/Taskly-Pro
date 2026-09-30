# Taskly V3.2.1

## Notes Editor Upgrade

- Fixed note color palette selection and persistence.
- Replaced the plain note editor with a rich-text editor backed by Quill Delta JSON.
- Added bottom editing toolbar for:
  - Font size
  - Font color
  - Emoji
  - Voice-to-text
  - Drawing
  - Image insertion
  - Bullet list
  - Numbered list
  - Attachments
  - Bold / Italic / Underline
  - Left / Center / Right / Justify alignment
- Existing plain-text notes remain readable and are migrated automatically when opened.
- Existing note title, pinned state, color, tags and checklist data remain compatible.
- Added local attachment metadata to notes.
- Added Android microphone/speech-recognition permissions and speech-service query.
- Kept package/application ID as `com.taskly.app`.
- Updated app version to `3.2.1+25`.
- Updated launcher/app icon assets using the supplied Taskly logo.

## Dependencies

- flutter_quill 11.5.1
- flutter_quill_extensions 11.0.0
- speech_to_text 7.4.0
- file_picker 12.2.0
