import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'security_service.dart';

import 'models.dart';

class TasklyBackupService {
  static const schemaVersion = 1;
  static const tasksKey = 'taskly_tasks_v6';
  static const notesKey = 'taskly_notes_v6';
  static const schemaKey = 'taskly_data_schema_version';

  Future<Map<String, dynamic>> buildBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final tasks = _decodeTasks(await _decryptStored(prefs.getString(tasksKey)));
    final notes = _decodeNotes(await _decryptStored(prefs.getString(notesKey)));

    final profileKeys = <String>[
      'profile_name', 'profile_profession', 'profile_gender', 'profile_blood_group',
      'profile_company', 'profile_designation', 'profile_department', 'profile_phone',
      'profile_email', 'profile_location', 'profile_bio', 'profile_facebook',
      'profile_instagram', 'profile_linkedin', 'profile_github', 'profile_website',
      'profile_photo_path',
    ];
    final profile = <String, dynamic>{};
    for (final key in profileKeys) {
      final value = prefs.getString(key);
      if (value != null && value.isNotEmpty) profile[key] = value;
    }

    final settings = <String, dynamic>{
      'theme_mode': prefs.getString('theme_mode') ?? 'light',
      'taskly_language': prefs.getString('taskly_language') ?? 'en',
      'notifications_enabled': prefs.getBool('notifications_enabled') ?? true,
      'taskly_onboarding_complete': prefs.getBool('taskly_onboarding_complete') ?? false,
    };

    final photoPath = prefs.getString('profile_photo_path');
    if (photoPath != null) {
      final file = File(photoPath);
      if (await file.exists()) {
        profile['profile_photo_base64'] = base64Encode(await file.readAsBytes());
        profile['profile_photo_extension'] = _extension(photoPath);
      }
    }
    profile.remove('profile_photo_path');

    return {
      'format': 'taskly_backup',
      'backupVersion': schemaVersion,
      'appVersion': '4.1.0',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'data': {
        'tasks': tasks,
        'notes': notes,
        'profile': profile,
        'settings': settings,
      },
    };
  }

  /// Saves the current workspace before a destructive restore.
  Future<void> createSafetySnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final backup = await buildBackup();
    await prefs.setString('taskly_pre_restore_backup_v4_2', jsonEncode(backup));
    await prefs.setString('taskly_pre_restore_backup_created_at', DateTime.now().toUtc().toIso8601String());
  }

  /// Restores a validated backup map and creates a safety snapshot first.
  Future<BackupImportResult> restoreBackupMap(Map<String, dynamic> decoded) async {
    if (decoded['format'] != 'taskly_backup') {
      throw const FormatException('This is not a valid Taskly backup file.');
    }
    final data = decoded['data'];
    if (data is! Map) throw const FormatException('The backup data is incomplete.');

    await createSafetySnapshot();

    final tasks = _decodeTaskList(data['tasks']);
    final notes = _decodeNoteList(data['notes']);
    final profile = data['profile'] is Map ? Map<String, dynamic>.from(data['profile'] as Map) : <String, dynamic>{};
    final settings = data['settings'] is Map ? Map<String, dynamic>.from(data['settings'] as Map) : <String, dynamic>{};

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tasksKey, 'ENC1:${await TasklySecurityService.instance.encryptText(jsonEncode(tasks))}');
    await prefs.setString(notesKey, 'ENC1:${await TasklySecurityService.instance.encryptText(jsonEncode(notes))}');
    await prefs.setInt(schemaKey, 4);

    for (final key in [
      'profile_name', 'profile_profession', 'profile_gender', 'profile_blood_group',
      'profile_company', 'profile_designation', 'profile_department', 'profile_phone',
      'profile_email', 'profile_location', 'profile_bio', 'profile_facebook',
      'profile_instagram', 'profile_linkedin', 'profile_github', 'profile_website',
    ]) {
      final value = profile[key]?.toString() ?? '';
      if (value.isEmpty) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, value);
      }
    }

    final theme = settings['theme_mode']?.toString();
    if (theme == 'light' || theme == 'dark' || theme == 'system') await prefs.setString('theme_mode', theme!);
    final language = settings['taskly_language']?.toString();
    if (language == 'en' || language == 'bn') await prefs.setString('taskly_language', language!);
    if (settings['notifications_enabled'] is bool) await prefs.setBool('notifications_enabled', settings['notifications_enabled'] as bool);
    if (settings['taskly_onboarding_complete'] is bool) await prefs.setBool('taskly_onboarding_complete', settings['taskly_onboarding_complete'] as bool);

    final photoBase64 = profile['profile_photo_base64']?.toString();
    String? photoPath;
    if (photoBase64 != null && photoBase64.isNotEmpty) {
      final directory = await getApplicationDocumentsDirectory();
      final extension = _safeExtension(profile['profile_photo_extension']?.toString() ?? '.jpg');
      final path = '${directory.path}/profile_photo$extension';
      await File(path).writeAsBytes(base64Decode(photoBase64), flush: true);
      await prefs.setString('profile_photo_path', path);
      photoPath = path;
    }

    await prefs.setString('taskly_cloud_updated_at', decoded['createdAt']?.toString() ?? DateTime.now().toUtc().toIso8601String());
    return BackupImportResult(taskCount: tasks.length, noteCount: notes.length, photoRestored: photoPath != null);
  }

  Future<String?> exportBackup() async {
    final backup = await buildBackup();
    final pretty = const JsonEncoder.withIndent('  ').convert(backup);
    final fileName = 'Taskly_Backup_${_stamp(DateTime.now())}.json';
    final bytes = Uint8List.fromList(utf8.encode(pretty));
    final output = await FilePicker.saveFile(
      dialogTitle: 'Save Taskly Backup',
      fileName: fileName,
      bytes: bytes,
      mimeType: 'application/json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (output == null) return null;
    return output.toString();
  }

  Future<BackupImportResult?> importBackup() async {
    final picked = await FilePicker.pickFile(
      dialogTitle: 'Select Taskly Backup',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (picked == null) return null;
    String raw;
    try {
      raw = utf8.decode(await picked.readAsBytes());
    } catch (_) {
      if (picked.path != null && picked.path!.isNotEmpty) {
        raw = await File(picked.path!).readAsString();
      } else {
        throw const FormatException('The selected backup file could not be read.');
      }
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) throw const FormatException('Invalid backup structure.');
    return restoreBackupMap(decoded);
  }

  List<Map<String, dynamic>> _decodeTasks(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      return _decodeTaskList(decoded);
    } catch (_) {
      return [];
    }
  }

  List<Map<String, dynamic>> _decodeNotes(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      return _decodeNoteList(decoded);
    } catch (_) {
      return [];
    }
  }

  Future<String?> _decryptStored(String? raw) async {
    if (raw == null || raw.isEmpty || !raw.startsWith('ENC1:')) return raw;
    return TasklySecurityService.instance.decryptText(raw.substring(5));
  }

  List<Map<String, dynamic>> _decodeTaskList(dynamic decoded) {
    if (decoded is! List) return [];
    final seen = <String>{};
    final output = <Map<String, dynamic>>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      try {
        final task = TodoItem.fromJson(map);
        if (task.title.trim().isEmpty || !seen.add(task.id)) continue;
        output.add(task.toJson());
      } catch (_) {}
    }
    return output;
  }

  List<Map<String, dynamic>> _decodeNoteList(dynamic decoded) {
    if (decoded is! List) return [];
    final seen = <String>{};
    final output = <Map<String, dynamic>>[];
    for (final item in decoded) {
      try {
        final note = item is String
            ? NoteItem(title: '', content: item)
            : item is Map ? NoteItem.fromJson(Map<String, dynamic>.from(item)) : null;
        if (note == null || (note.title.trim().isEmpty && note.content.trim().isEmpty && note.checklist.isEmpty) || !seen.add(note.id)) continue;
        output.add(note.toJson());
      } catch (_) {}
    }
    return output;
  }

  String _stamp(DateTime value) => '${value.year}${_two(value.month)}${_two(value.day)}_${_two(value.hour)}${_two(value.minute)}';
  String _two(int value) => value.toString().padLeft(2, '0');
  String _extension(String path) => path.contains('.') ? path.substring(path.lastIndexOf('.')) : '.jpg';
  String _safeExtension(String value) => ['.jpg', '.jpeg', '.png', '.webp'].contains(value.toLowerCase()) ? value : '.jpg';
}

class BackupImportResult {
  const BackupImportResult({required this.taskCount, required this.noteCount, required this.photoRestored});
  final int taskCount;
  final int noteCount;
  final bool photoRestored;
}
