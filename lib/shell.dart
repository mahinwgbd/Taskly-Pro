import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';
import 'backup_service.dart';

import 'bottomNavigation.dart';
import 'bottomSheet.dart';
import 'calendar.dart';
import 'home.dart';
import 'insights.dart';
import 'notes.dart';
import 'models.dart';
import 'profile.dart';
import 'profile_page.dart';
import 'google_drive_sync.dart';
import 'search.dart';
import 'task.dart';
import 'util.dart';
import 'security_service.dart';
import 'pro_ai_chat.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.onThemeChanged, required this.locale, required this.onLanguageChanged});
  final ValueChanged<ThemeMode> onThemeChanged;
  final Locale locale;
  final ValueChanged<Locale> onLanguageChanged;
  @override State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  static const _tasksKey = 'taskly_tasks_v6';
  static const _notesKey = 'taskly_notes_v6';
  static const _tasksBackupKey = 'taskly_tasks_backup_v4';
  static const _notesBackupKey = 'taskly_notes_backup_v4';
  static const _schemaKey = 'taskly_data_schema_version';
  static const _schemaVersion = 4;
  int currentIndex = 0;
  final ProfileController profile = ProfileController();
  final GoogleDriveSyncService cloudSync = GoogleDriveSyncService.instance;
  final List<TodoItem> tasks = [];
  final List<NoteItem> notes = [];
  String selectedTaskFilter = 'All';
  bool actionsOpen = false;
  bool workspaceLoaded = false;

  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadWorkspace();
    profile.load();
    cloudSync.initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && workspaceLoaded) {
      for (final task in tasks) {
        NotificationService.instance.syncTaskReminder(task);
      }
    }
  }

  Future<void> _loadWorkspace() async {
    final prefs = await SharedPreferences.getInstance();
    tasks.clear();
    notes.clear();

    final storedTask = prefs.getString(_tasksKey);
    final storedNote = prefs.getString(_notesKey);
    final taskData = await _decryptStored(storedTask);
    final noteData = await _decryptStored(storedNote);
    if (taskData != null && taskData.isNotEmpty && storedTask != null && !storedTask.startsWith('ENC1:')) {
      await prefs.setString(_tasksKey, 'ENC1:${await TasklySecurityService.instance.encryptText(taskData)}');
    }
    if (noteData != null && noteData.isNotEmpty && storedNote != null && !storedNote.startsWith('ENC1:')) {
      await prefs.setString(_notesKey, 'ENC1:${await TasklySecurityService.instance.encryptText(noteData)}');
    }
    final tasksLoaded = _loadTasksSafely(taskData);
    if (!tasksLoaded && taskData != null) {
      _loadTasksSafely(await _decryptStored(prefs.getString(_tasksBackupKey)));
    } else if (!tasksLoaded) {
      _loadTasksSafely(await _decryptStored(prefs.getString(_tasksBackupKey)));
    }
    final notesLoaded = _loadNotesSafely(noteData);
    if (!notesLoaded && noteData != null) {
      _loadNotesSafely(await _decryptStored(prefs.getString(_notesBackupKey)));
    } else if (!notesLoaded) {
      _loadNotesSafely(await _decryptStored(prefs.getString(_notesBackupKey)));
    }

    // Migrate old data lazily: the current serializer is backward-compatible,
    // so simply recording the schema version is enough for this release.
    await prefs.setInt(_schemaKey, _schemaVersion);
    if (mounted) setState(() => workspaceLoaded = true);

    // Reconcile reminders after every cold start. This also repairs reminders
    // after Android has reclaimed scheduled alarms.
    for (final task in tasks) {
      await NotificationService.instance.syncTaskReminder(task);
    }
  }

  Future<String?> _decryptStored(String? raw) async {
    if (raw == null || raw.isEmpty) return raw;
    if (!raw.startsWith('ENC1:')) return raw;
    return TasklySecurityService.instance.decryptText(raw.substring(5));
  }

  bool _loadTasksSafely(String? raw) {
    if (raw == null || raw.trim().isEmpty) return false;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return false;
      final seen = <String>{};
      for (final item in decoded) {
        if (item is! Map) continue;
        final task = TodoItem.fromJson(Map<String, dynamic>.from(item));
        if (task.title.trim().isEmpty || !seen.add(task.id)) continue;
        tasks.add(task);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _loadNotesSafely(String? raw) {
    if (raw == null || raw.trim().isEmpty) return false;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return false;
      final seen = <String>{};
      for (final item in decoded) {
        if (item is String && item.trim().isNotEmpty) {
          final now = DateTime.now();
          final note = NoteItem(title: '', content: item.trim(), createdAt: now, updatedAt: now);
          if (seen.add(note.id)) notes.add(note);
          continue;
        }
        if (item is! Map) continue;
        final note = NoteItem.fromJson(Map<String, dynamic>.from(item));
        if ((note.title.trim().isEmpty && note.content.trim().isEmpty && note.checklist.isEmpty) || !seen.add(note.id)) continue;
        notes.add(note);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveWorkspace() async {
    final prefs = await SharedPreferences.getInstance();
    final taskJson = jsonEncode(_taskMaps);
    final noteJson = jsonEncode(notes.map((n) => n.toJson()).toList());
    final encryptedTaskJson = 'ENC1:${await TasklySecurityService.instance.encryptText(taskJson)}';
    final encryptedNoteJson = 'ENC1:${await TasklySecurityService.instance.encryptText(noteJson)}';

    // Keep one last-known-good snapshot before replacing the active payload.
    final previousTasks = prefs.getString(_tasksKey);
    final previousNotes = prefs.getString(_notesKey);
    if (previousTasks != null && previousTasks.isNotEmpty) {
      await prefs.setString(_tasksBackupKey, previousTasks);
    }
    if (previousNotes != null && previousNotes.isNotEmpty) {
      await prefs.setString(_notesBackupKey, previousNotes);
    }

    await prefs.setString(_tasksKey, encryptedTaskJson);
    await prefs.setString(_notesKey, encryptedNoteJson);
    await prefs.setInt(_schemaKey, _schemaVersion);
    await prefs.setString('taskly_cloud_updated_at', DateTime.now().toUtc().toIso8601String());
  }

  List<Map<String, dynamic>> get _taskMaps => tasks.map((t) => t.toJson()).toList();

  Map<String, dynamic> get _profileMap => {
        'profile_name': profile.name,
        'profile_profession': profile.profession,
        'profile_gender': profile.gender,
        'profile_blood_group': profile.bloodGroup,
        'profile_company': profile.company,
        'profile_designation': profile.designation,
        'profile_department': profile.department,
        'profile_phone': profile.phone,
        'profile_email': profile.email,
        'profile_location': profile.location,
        'profile_bio': profile.bio,
        'profile_facebook': profile.facebook,
        'profile_instagram': profile.instagram,
        'profile_linkedin': profile.linkedin,
        'profile_github': profile.github,
        'profile_website': profile.website,
      };

  /// V4.2 intentionally uses manual cloud backup/restore to avoid silent
  /// overwrites. Automatic sync will be introduced only after conflict
  /// resolution is production-tested.
  Future<void> _syncToDrive() async {
    if (!cloudSync.isSignedIn || !workspaceLoaded) return;
    final backup = await TasklyBackupService().buildBackup();
    await cloudSync.uploadBackup(backup);
  }

  Future<void> _restoreFromDrive() async {
    if (!cloudSync.isSignedIn) return;
    final backup = await cloudSync.downloadBackup();
    if (backup == null) return;
    await TasklyBackupService().restoreBackupMap(backup);
    await _loadWorkspace();
    await profile.load();
    if (mounted) setState(() {});
  }

  @override void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    profile.dispose(); super.dispose(); }
  void _toggle(TodoItem task) {
    if (task.completed) {
      setState(() => task.completed = false);
      _saveWorkspace();
      return;
    }
    TodoItem? generatedNext;
    if (task.repeat != 'Does not repeat') {
      final nextDate = _nextOccurrence(task.date, task.repeat);
      generatedNext = task.copyWith(date: nextDate, completed: false);
      final next = generatedNext;
      setState(() {
        task.completed = true;
        tasks.insert(0, next);
        NotificationService.instance.syncTaskReminder(next);
      });
    } else {
      setState(() => task.completed = true);
    }
    _saveWorkspace();
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(tr('Task completed')),
      action: SnackBarAction(label: tr('Undo'), onPressed: () {
        if (!mounted) return;
        setState(() {
          task.completed = false;
          if (generatedNext != null) tasks.remove(generatedNext);
        });
        _saveWorkspace();
      }),
      behavior: SnackBarBehavior.floating,
    ));
  }
  DateTime _nextOccurrence(DateTime date, String repeat) {
    switch (repeat) {
      case 'Daily':
        return date.add(const Duration(days: 1));
      case 'Weekly':
        return date.add(const Duration(days: 7));
      case 'Weekdays':
        var next = date.add(const Duration(days: 1));
        while (next.weekday > DateTime.friday) { next = next.add(const Duration(days: 1)); }
        return next;
      case 'Weekends':
        var next = date.add(const Duration(days: 1));
        while (next.weekday != DateTime.saturday && next.weekday != DateTime.sunday) { next = next.add(const Duration(days: 1)); }
        return next;
      case 'Monthly':
        final targetMonth = date.month == 12 ? 1 : date.month + 1;
        final targetYear = date.month == 12 ? date.year + 1 : date.year;
        final lastDay = DateTime(targetYear, targetMonth + 1, 0).day;
        return DateTime(targetYear, targetMonth, date.day.clamp(1, lastDay).toInt(), date.hour, date.minute);
      default:
        return date;
    }
  }
  void _delete(TodoItem task) {
    NotificationService.instance.cancelTaskReminder(task.id);
    final index = tasks.indexOf(task);
    if (index < 0) return;
    setState(() => tasks.removeAt(index));
    _saveWorkspace();
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(tr('Task deleted')),
      action: SnackBarAction(label: tr('Undo'), onPressed: () {
        if (!mounted) return;
        setState(() => tasks.insert(index.clamp(0, tasks.length).toInt(), task));
        _saveWorkspace();
      }),
      behavior: SnackBarBehavior.floating,
    ));
  }
  void _addTask(TodoItem task) { setState(() => tasks.insert(0, task)); _saveWorkspace(); NotificationService.instance.syncTaskReminder(task); }
  void _editTask(TodoItem oldTask, TodoItem newTask) { final i = tasks.indexOf(oldTask); if (i < 0) return; final updated = newTask.copyWith(id: oldTask.id); setState(() => tasks[i] = updated); _saveWorkspace(); NotificationService.instance.syncTaskReminder(updated); }
  void _addNote(NoteItem note) { setState(() => notes.insert(0, note)); _saveWorkspace(); }
  void _editNote(NoteItem oldNote, NoteItem newNote) { final i = notes.indexOf(oldNote); if (i < 0) return; setState(() => notes[i] = newNote); _saveWorkspace(); }
  void _deleteNote(NoteItem note) {
    setState(() {
      final i = notes.indexOf(note);
      if (i >= 0) notes[i] = note.copyWith(deletedAt: DateTime.now(), archived: false);
    });
    _saveWorkspace();
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(tr('Moved to trash')),
      action: SnackBarAction(label: tr('Undo'), onPressed: () => _restoreNote(note)),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _restoreNote(NoteItem note) {
    final i = notes.indexOf(note);
    if (i < 0) return;
    setState(() => notes[i] = note.copyWith(clearDeletedAt: true, archived: false));
    _saveWorkspace();
  }

  void _archiveNote(NoteItem note) {
    final i = notes.indexOf(note);
    if (i < 0) return;
    setState(() => notes[i] = note.copyWith(archived: !note.archived));
    _saveWorkspace();
  }

  void _permanentDeleteNote(NoteItem note) {
    final i = notes.indexOf(note);
    if (i < 0) return;
    setState(() => notes.removeAt(i));
    _saveWorkspace();
  }
  void _toggleNotePin(NoteItem note) { final i = notes.indexOf(note); if (i < 0) return; setState(() => notes[i] = note.copyWith(pinned: !note.pinned)); _saveWorkspace(); }
  void _toggleNoteChecklist(NoteItem note, int index, bool value) { final i = notes.indexOf(note); if (i < 0 || index < 0 || index >= note.checklist.length) return; final items = List<NoteChecklistItem>.of(note.checklist); items[index] = items[index].copyWith(completed: value); setState(() => notes[i] = note.copyWith(checklist: items)); _saveWorkspace(); }
  void _showAllTasks() => setState(() { selectedTaskFilter = 'All'; currentIndex = 1; });
  void _openProject(String category) => setState(() { selectedTaskFilter = category; currentIndex = 1; });
  Future<void> _restoreWorkspaceFromBackup() async {
    await _loadWorkspace();
    await profile.load();
    if (mounted) setState(() {});
  }

  void _openSettings() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SettingsPage(
    profile: profile,
    onThemeChanged: widget.onThemeChanged,
    cloudSync: cloudSync,
    onSync: _syncToDrive,
    onCloudRestore: _restoreFromDrive,
    onBackupRestored: _restoreWorkspaceFromBackup,
  )));
  void _openSearch() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => GlobalSearchPage(tasks: tasks, notes: notes, onTaskTap: (task) { Navigator.of(context).pop(); _showTaskSheet(editing: task); }, onNoteTap: (note) { Navigator.of(context).pop(); _showNoteSheet(editing: note); })));

  Future<void> _showTaskSheet({TodoItem? editing, TodoItem? draft}) async {
    setState(() => actionsOpen = false);
    final result = await showTaskEditorSheet(context, task: editing ?? draft);
    if (result == null) return;
    if (editing == null) { _addTask(result); } else { _editTask(editing, result); }
  }
  Future<void> _createTaskFromNote(NoteItem note) async {
    final draft = TodoItem(title: note.title.trim().isEmpty ? tr('New task') : note.title.trim(), description: note.content.trim(), time: TimeOfDay.now().format(context), category: 'Personal', priority: 'Medium', date: DateTime.now());
    await _showTaskSheet(draft: draft);
  }

  Future<void> _showNoteSheet({NoteItem? editing}) async {
    setState(() => actionsOpen = false);
    final result = await showModalBottomSheet<NoteItem>(
      context: context, isScrollControlled: true, useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: .82, minChildSize: .55, maxChildSize: .97,
        expand: false, snap: true, snapSizes: const [.82, .97],
        builder: (_, scrollController) => NoteEditorSheet(note: editing, scrollController: scrollController),
      ),
    );
    if (result == null) return;
    if (editing == null) { _addNote(result); } else { _editNote(editing, result); }
  }

  @override
  Widget build(BuildContext context) {
    if (!workspaceLoaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      body: Stack(children: [
        IndexedStack(index: currentIndex, children: [
        AnimatedBuilder(animation: profile, builder: (_, __) => HomePage(tasks: tasks, notes: notes, onToggle: _toggle, onDelete: _delete, onEdit: (t) => _showTaskSheet(editing: t), onAdd: _showTaskSheet, onAddNote: _showNoteSheet, profile: profile, locale: widget.locale, onLanguageChanged: widget.onLanguageChanged, onSeeAllTasks: _showAllTasks, onProjectTap: _openProject, onSeeAllNotes: () => setState(() => currentIndex = 2), onCalendar: () => setState(() => currentIndex = 3), onInsights: () => setState(() => currentIndex = 4))),
        TaskPage(key: ValueKey(selectedTaskFilter), tasks: tasks, onToggle: _toggle, onDelete: _delete, onEdit: (t) => _showTaskSheet(editing: t), initialFilter: selectedTaskFilter, onAdd: _showTaskSheet, onSearch: _openSearch),
        NotesPage(notes: notes, onAdd: _showNoteSheet, onEdit: (n) => _showNoteSheet(editing: n), onDelete: _deleteNote, onArchive: _archiveNote, onRestore: _restoreNote, onPermanentDelete: _permanentDeleteNote, onTogglePin: _toggleNotePin, onToggleChecklist: _toggleNoteChecklist, onConvertToTask: _createTaskFromNote),
        CalendarPage(tasks: tasks, onToggle: _toggle, onDelete: _delete, onEdit: (t) => _showTaskSheet(editing: t), onAdd: _showTaskSheet),
        InsightsPage(tasks: tasks),
        ]),
        Positioned(
          right: 16,
          bottom: 14,
          child: SafeArea(
            top: false,
            left: false,
            child: Tooltip(
              message: tr('Ask Taskly AI'),
              child: FloatingActionButton.small(
                heroTag: 'taskly_ai_fab',
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TasklyProAiChatPage())),
                backgroundColor: CustomColors.primary,
                foregroundColor: Colors.white,
                elevation: 7,
                child: const Icon(Icons.smart_toy_rounded),
              ),
            ),
          ),
        ),
      ]),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child)),
        child: actionsOpen
            ? _ActionMenu(key: const ValueKey('open'), onAddTask: _showTaskSheet, onAddNote: _showNoteSheet, onClose: () => setState(() => actionsOpen = false))
            : Transform.translate(
                offset: const Offset(0, 11),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border: Border.all(color: CustomColors.accent.withOpacity(.22), width: 1.2),
                    boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 16, offset: Offset(0, 7))],
                  ),
                  child: FloatingActionButton(
                    key: const ValueKey('closed'),
                    onPressed: () => setState(() => actionsOpen = true),
                    elevation: 8,
                    backgroundColor: CustomColors.accent,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    child: const Icon(Icons.add_rounded, size: 34),
                  ),
                ),
              ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: ModernBottomNavigation(
        currentIndex: currentIndex,
        onChanged: (index) => setState(() => currentIndex = index),
        onSettings: _openSettings,
      ),
    );
  }
}

class _ActionMenu extends StatelessWidget {
  const _ActionMenu({super.key, required this.onAddTask, required this.onAddNote, required this.onClose});
  final VoidCallback onAddTask; final VoidCallback onAddNote; final VoidCallback onClose;
  @override Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [_MiniAction(label: tr('Add note'), icon: Icons.sticky_note_2_rounded, color: CustomColors.purple, onTap: onAddNote), SizedBox(height: 10), _MiniAction(label: tr('Add task'), icon: Icons.check_rounded, color: CustomColors.primary, onTap: onAddTask), SizedBox(height: 12), FloatingActionButton.small(onPressed: onClose, backgroundColor: CustomColors.accent, foregroundColor: Colors.white, child: Icon(Icons.close_rounded))]);
}
class _MiniAction extends StatelessWidget { const _MiniAction({required this.label, required this.icon, required this.color, required this.onTap}); final String label; final IconData icon; final Color color; final VoidCallback onTap; @override Widget build(BuildContext context) => Material(color: Theme.of(context).cardColor, elevation: 6, borderRadius: BorderRadius.circular(18), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withOpacity(.11), shape: BoxShape.circle), child: Icon(icon, size: 18, color: color)), const SizedBox(width: 9), Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))])))); }
