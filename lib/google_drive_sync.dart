import 'dart:async';

import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'google_auth_config.dart';
import 'util.dart';

class CloudBackupData {
  CloudBackupData({required this.tasks, required this.notes, required this.profile, this.profilePhotoBase64, required this.updatedAt});

  final List<Map<String, dynamic>> tasks;
  final List<Map<String, dynamic>> notes;
  final Map<String, dynamic> profile;
  final String? profilePhotoBase64;
  final String updatedAt;

  Map<String, dynamic> toJson() => {
        'schema': 2,
        'updatedAt': updatedAt,
        'tasks': tasks,
        'notes': notes,
        'profile': profile,
        if (profilePhotoBase64 != null) 'profilePhotoBase64': profilePhotoBase64,
      };

  factory CloudBackupData.fromJson(Map<String, dynamic> json) => CloudBackupData(
        tasks: (json['tasks'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().toList(),
        notes: (json['notes'] as List<dynamic>? ?? []).map((item) {
          if (item is Map<String, dynamic>) return item;
          if (item is String) return <String, dynamic>{'title': '', 'content': item};
          return <String, dynamic>{};
        }).where((item) => item.isNotEmpty).toList(),
        profile: (json['profile'] as Map<String, dynamic>? ?? {}),
        profilePhotoBase64: json['profilePhotoBase64'] as String?,
        updatedAt: json['updatedAt'] as String? ?? DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
      );
}

class GoogleDriveSyncService extends ChangeNotifier {
  GoogleDriveSyncService._();
  static final GoogleDriveSyncService instance = GoogleDriveSyncService._();

  static const backupFileName = 'taskly_backup_v4_2.json';
  static const driveAppDataScope = 'https://www.googleapis.com/auth/drive.appdata';
  static const scopes = <String>[driveAppDataScope];
  static const _accountEmailKey = 'google_account_email';
  static const _accountNameKey = 'google_account_name';

  final GoogleSignIn _signIn = GoogleSignIn.instance;
  GoogleSignInAccount? _user;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSubscription;
  bool _initialized = false;
  String _configuredClientId = '';
  bool _busy = false;
  String? errorMessage;

  GoogleSignInAccount? get user => _user;
  bool get isSignedIn => _user != null;
  bool get isBusy => _busy;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedClientId = prefs.getString('google_server_client_id') ?? '';
      final configuredClientId = googleServerClientId.isNotEmpty ? googleServerClientId.trim() : storedClientId.trim();
      if (configuredClientId.isEmpty) {
        _initialized = false;
        errorMessage = tr('Google OAuth is not configured yet. Add your Web Client ID in Settings → Google Drive Backup → Google OAuth Setup.');
        notifyListeners();
        return;
      }
      if (!isValidGoogleWebClientId(configuredClientId)) {
        _initialized = false;
        errorMessage = tr('Invalid Web Client ID. It should end with .apps.googleusercontent.com.');
        notifyListeners();
        return;
      }
      _configuredClientId = configuredClientId;
      await _signIn.initialize(serverClientId: configuredClientId);
      _authSubscription = _signIn.authenticationEvents.listen(_handleAuthEvent, onError: (Object error) {
        errorMessage = _friendlyGoogleError(error);
        notifyListeners();
      });
      _initialized = true;
      await _signIn.attemptLightweightAuthentication();
    } catch (e) {
      _initialized = false;
      errorMessage = _friendlyGoogleError(e);
      notifyListeners();
    }
  }

  Future<void> _handleAuthEvent(GoogleSignInAuthenticationEvent event) async {
    switch (event) {
      case GoogleSignInAuthenticationEventSignIn():
        _user = event.user;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_accountEmailKey, _user?.email ?? '');
        await prefs.setString(_accountNameKey, _user?.displayName ?? '');
        errorMessage = null;
        notifyListeners();
      case GoogleSignInAuthenticationEventSignOut():
        _user = null;
        notifyListeners();
    }
  }

  Future<bool> signIn() async {
    _busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await initialize();
      final user = await _signIn.authenticate(scopeHint: scopes);
      _user = user;
      final authorization = await user.authorizationClient.authorizeScopes(scopes);
      final client = authorization.authClient(scopes: scopes);
      client.close();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accountEmailKey, user.email);
      await prefs.setString(_accountNameKey, user.displayName ?? '');
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = _friendlyGoogleError(e);
      notifyListeners();
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }


  Future<bool> saveServerClientId(String clientId) async {
    final value = clientId.trim();
    if (!isValidGoogleWebClientId(value)) {
      errorMessage = tr('Invalid Web Client ID. It should end with .apps.googleusercontent.com.');
      notifyListeners();
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('google_server_client_id', value);
    errorMessage = null;
    notifyListeners();
    return true;
  }

  String _friendlyGoogleError(Object error) {
    final text = error.toString();
    if (_configuredClientId.isEmpty) {
      return tr('Google OAuth needs your Web Client ID. Add it in Settings → Google Drive Backup → Google OAuth Setup, then restart Taskly.');
    }
    if (text.contains('clientConfigurationError') || text.contains('serverClientId') || text.contains('ApiException: 10') || text.contains('DEVELOPER_ERROR')) {
      return tr('Google OAuth configuration error (DEVELOPER_ERROR). Google Cloud must have an Android OAuth client for package com.taskly.app + your debug SHA-1, and the Web Client ID must be the serverClientId.');
    }
    if (text.contains('canceled')) {
      return tr('Google sign-in was cancelled or Android could not match the configured OAuth client.');
    }
    return tr('Google sign-in failed. Check your OAuth client and SHA-1 configuration.');
  }

  Future<void> signOut() async {
    await _signIn.signOut();
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accountEmailKey);
    await prefs.remove(_accountNameKey);
    notifyListeners();
  }

  Future<drive.DriveApi?> _driveApi() async {
    final user = _user;
    if (user == null) return null;
    final authorization = await user.authorizationClient.authorizationForScopes(scopes) ?? await user.authorizationClient.authorizeScopes(scopes);
    final client = authorization.authClient(scopes: scopes);
    return drive.DriveApi(client);
  }

  DateTime? _lastCloudBackup;
  DateTime? get lastCloudBackup => _lastCloudBackup;

  Future<Map<String, dynamic>?> downloadBackup() async {
    final api = await _driveApi();
    if (api == null) {
      errorMessage = tr('Connect Google Drive first.');
      notifyListeners();
      return null;
    }
    _busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final remote = await _findBackup(api);
      if (remote == null) {
        errorMessage = tr('No Taskly backup was found in Google Drive.');
        return null;
      }
      _lastCloudBackup = DateTime.tryParse(remote.$3);
      final decoded = jsonDecode(remote.$2);
      if (decoded is! Map<String, dynamic> || decoded['format'] != 'taskly_backup') {
        errorMessage = tr('The Google Drive backup is invalid or corrupted.');
        return null;
      }
      notifyListeners();
      return decoded;
    } catch (e) {
      errorMessage = tr('Could not download the Google Drive backup.');
      return null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> uploadBackup(Map<String, dynamic> backup) async {
    final api = await _driveApi();
    if (api == null) {
      errorMessage = tr('Connect Google Drive first.');
      notifyListeners();
      return false;
    }
    _busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final remote = await _findBackup(api);
      if (remote == null) {
        await _createBackupMap(api, backup);
      } else {
        await _updateBackupMap(api, remote.$1, backup);
      }
      _lastCloudBackup = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('taskly_last_cloud_backup_at', _lastCloudBackup!.toUtc().toIso8601String());
      notifyListeners();
      return true;
    } catch (_) {
      errorMessage = tr('Could not upload the backup to Google Drive.');
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<String?> remoteBackupTimestamp() async {
    final api = await _driveApi();
    if (api == null) return null;
    try {
      final remote = await _findBackup(api);
      return remote?.$3;
    } catch (_) {
      return null;
    }
  }

  Future<bool> sync(CloudBackupData localData) async {
    final api = await _driveApi();
    if (api == null) return false;
    _busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final remote = await _findBackup(api);
      if (remote == null) {
        await _createBackup(api, localData);
        return true;
      }
      final remoteData = CloudBackupData.fromJson(jsonDecode(remote.$2) as Map<String, dynamic>);
      final localTime = DateTime.tryParse(localData.updatedAt) ?? DateTime.now();
      final remoteTime = DateTime.tryParse(remoteData.updatedAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (remoteTime.isAfter(localTime)) {
        await _writeLocalRestore(remoteData);
      } else {
        await _updateBackup(api, remote.$1, localData);
      }
      return true;
    } catch (e) {
      errorMessage = tr('Could not sync with Google Drive.');
      notifyListeners();
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> restoreFromDrive() async {
    final api = await _driveApi();
    if (api == null) return false;
    _busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final remote = await _findBackup(api);
      if (remote == null) return false;
      await _writeLocalRestore(CloudBackupData.fromJson(jsonDecode(remote.$2) as Map<String, dynamic>));
      return true;
    } catch (_) {
      errorMessage = tr('Could not restore the backup.');
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<(String, String, String)?> _findBackup(drive.DriveApi api) async {
    final list = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$backupFileName' and trashed = false",
      $fields: 'files(id,name,modifiedTime)',
      pageSize: 1,
    );
    final file = list.files?.isNotEmpty == true ? list.files!.first : null;
    if (file?.id == null) return null;
    final response = await api.files.get(file!.id!, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
    final bytes = <int>[];
    await for (final chunk in response.stream) {
      bytes.addAll(chunk);
    }
    return (file.id!, utf8.decode(bytes), file.modifiedTime?.toIso8601String() ?? DateTime.fromMillisecondsSinceEpoch(0).toIso8601String());
  }

  Future<void> _createBackupMap(drive.DriveApi api, Map<String, dynamic> backup) async {
    final bytes = Uint8List.fromList(utf8.encode(const JsonEncoder.withIndent('  ').convert(backup)));
    final media = drive.Media(Stream<Uint8List>.value(bytes), bytes.length);
    final metadata = drive.File()..name = backupFileName..parents = ['appDataFolder'];
    await api.files.create(metadata, uploadMedia: media, $fields: 'id');
  }

  Future<void> _updateBackupMap(drive.DriveApi api, String id, Map<String, dynamic> backup) async {
    final bytes = Uint8List.fromList(utf8.encode(const JsonEncoder.withIndent('  ').convert(backup)));
    final media = drive.Media(Stream<Uint8List>.value(bytes), bytes.length);
    await api.files.update(drive.File()..name = backupFileName, id, uploadMedia: media);
  }

  Future<void> _createBackup(drive.DriveApi api, CloudBackupData data) async {
    final media = _mediaFor(data);
    final metadata = drive.File()
      ..name = backupFileName
      ..parents = ['appDataFolder'];
    await api.files.create(metadata, uploadMedia: media, $fields: 'id');
  }

  Future<void> _updateBackup(drive.DriveApi api, String id, CloudBackupData data) async {
    await api.files.update(drive.File(), id, uploadMedia: _mediaFor(data));
  }

  drive.Media _mediaFor(CloudBackupData data) {
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(data.toJson())));
    return drive.Media(Stream<Uint8List>.value(bytes), bytes.length);
  }

  Future<void> _writeLocalRestore(CloudBackupData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('taskly_tasks_v6', jsonEncode(data.tasks));
    await prefs.setString('taskly_notes_v6', jsonEncode(data.notes));
    for (final entry in data.profile.entries) {
      final value = entry.value;
      if (value == null || value.toString().isEmpty) {
        await prefs.remove(entry.key);
      } else {
        await prefs.setString(entry.key, value.toString());
      }
    }
    await prefs.setString('taskly_cloud_updated_at', data.updatedAt);
    if (data.profilePhotoBase64 != null) {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/profile_photo.jpg';
      await File(path).writeAsBytes(base64Decode(data.profilePhotoBase64!));
      await prefs.setString('profile_photo_path', path);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
