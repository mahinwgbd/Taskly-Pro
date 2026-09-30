import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'security_service.dart';
import 'util.dart';

class TasklyProAiChatPage extends StatefulWidget {
  const TasklyProAiChatPage({super.key});
  @override
  State<TasklyProAiChatPage> createState() => _TasklyProAiChatPageState();
}

class _ChatMessage {
  _ChatMessage(this.text, this.user) : time = DateTime.now();
  final String text;
  final bool user;
  final DateTime time;
}

class _TasklyProAiChatPageState extends State<TasklyProAiChatPage> {
  static const _tasksKey = 'taskly_tasks_v6';
  static const _notesKey = 'taskly_notes_v6';
  final controller = TextEditingController();
  final scroll = ScrollController();
  final messages = <_ChatMessage>[];
  List<TodoItem> tasks = [];
  List<NoteItem> notes = [];
  bool thinking = false;

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  @override
  void dispose() {
    controller.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<String?> _readWorkspaceValue(SharedPreferences p, String key) async {
    final raw = p.getString(key);
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('ENC1:')) {
      return TasklySecurityService.instance.decryptText(raw.substring(5));
    }
    return raw;
  }

  Future<void> _loadContext() async {
    final p = await SharedPreferences.getInstance();
    try {
      final raw = await _readWorkspaceValue(p, _tasksKey);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          tasks = decoded.whereType<Map>().map((e) => TodoItem.fromJson(Map<String, dynamic>.from(e))).toList();
        }
      }
    } catch (_) {}
    try {
      final raw = await _readWorkspaceValue(p, _notesKey);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          notes = decoded.whereType<Map>().map((e) => NoteItem.fromJson(Map<String, dynamic>.from(e))).toList();
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        if (messages.isEmpty) {
          messages.add(_ChatMessage(
            'Hi! I\'m Taskly AI Pro. I can analyze your private workspace locally, plan your day, suggest priorities, create tasks from natural language, and summarize notes.',
            false,
          ));
        }
      });
    }
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? controller.text).trim();
    if (text.isEmpty || thinking) return;
    controller.clear();
    setState(() {
      messages.add(_ChatMessage(text, true));
      thinking = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 280));
    final reply = await _processCommand(text);
    if (!mounted) return;
    setState(() {
      messages.add(_ChatMessage(reply, false));
      thinking = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 30));
    if (scroll.hasClients) {
      scroll.animateTo(scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  Future<String> _processCommand(String input) async {
    final q = input.toLowerCase().trim();
    if (_looksLikeCreateTask(q)) return _createTaskFromPrompt(input);
    if (_looksLikeComplete(q)) return _completeTaskFromPrompt(input);
    if (_looksLikeReschedule(q)) return _rescheduleTaskFromPrompt(input);
    if (_looksLikePriorityChange(q)) return _changePriorityFromPrompt(input);
    if (_looksLikeDelete(q)) return _deleteTaskFromPrompt(input);
    if (q.contains('daily briefing') || q.contains('brief') || q.contains('দিনের সারাংশ')) return _dailyBriefing();
    if (q.contains('today') || q.contains('আজ') || q.contains('plan') || q.contains('পরিকল্পনা')) return _planToday();
    if (q.contains('overdue') || q.contains('বাকি') || q.contains('দেরি')) return _overdue();
    if (q.contains('summar') || q.contains('analy') || q.contains('note') || q.contains('নোট')) return _analyzeNotes();
    if (q.contains('priority') || q.contains('prioriti') || q.contains('অগ্রাধিকার')) return _priorityAdvice();
    if (q.contains('focus') || q.contains('ফোকাস')) return _focusAdvice();
    if (q.contains('how many') || q.contains('কত') || q.contains('task') || q.contains('কাজ')) {
      final pending = tasks.where((t) => !t.completed).length;
      final done = tasks.where((t) => t.completed).length;
      return 'Workspace summary: ${localizeNumber(pending)} pending task(s), ${localizeNumber(done)} completed task(s), and ${localizeNumber(notes.length)} note(s).';
    }
    return 'I can act on your Taskly workspace. Try “Create task: submit assignment tomorrow”, “Complete presentation”, “Move presentation to tomorrow”, “Make presentation urgent”, “Plan my day”, or “Daily briefing”.';
  }

  bool _looksLikeCreateTask(String q) => q.contains('create task') || q.contains('add task') || q.contains('নতুন কাজ') || q.contains('টাস্ক তৈরি') || q.startsWith('task:');

  Future<String> _createTaskFromPrompt(String input) async {
    var title = input
        .replaceFirst(RegExp(r'^.*?(create task|add task|task:|নতুন কাজ|টাস্ক তৈরি)\s*[:\-]?\s*', caseSensitive: false), '')
        .trim();
    if (title.isEmpty) return 'Please give me a task title. Example: “Create task: submit university assignment tomorrow”.';

    DateTime date = DateTime.now();
    final lower = title.toLowerCase();
    if (lower.contains('tomorrow') || title.contains('আগামীকাল')) {
      date = DateTime.now().add(const Duration(days: 1));
      title = title.replaceAll(RegExp(r'\b(tomorrow)\b', caseSensitive: false), '').replaceAll('আগামীকাল', '').trim();
    } else if (lower.contains('today') || title.contains('আজ')) {
      title = title.replaceAll(RegExp(r'\b(today)\b', caseSensitive: false), '').replaceAll('আজ', '').trim();
    }

    final priority = lower.contains('urgent') || title.contains('জরুরি') ? 'Urgent' : lower.contains('high') ? 'High' : 'Medium';
    title = title.replaceAll(RegExp(r'\b(urgent|high)\b', caseSensitive: false), '').replaceAll('জরুরি', '').trim();
    if (title.isEmpty) return 'I need a task title before I can create it.';

    tasks.add(TodoItem(title: title, time: '', category: 'AI', date: DateTime(date.year, date.month, date.day), priority: priority, description: 'Created by Taskly AI Pro'));
    await _saveTasks();
    return 'Done. I created “$title” for ${_dateLabel(date)} with $priority priority.';
  }

  Future<void> _saveTasks() async {
    final p = await SharedPreferences.getInstance();
    final json = jsonEncode(tasks.map((e) => e.toJson()).toList());
    final encrypted = await TasklySecurityService.instance.encryptText(json);
    await p.setString(_tasksKey, 'ENC1:$encrypted');
  }

  String _planToday() {
    final today = DateTime.now();
    final items = tasks.where((t) => !t.completed && t.date.year == today.year && t.date.month == today.month && t.date.day == today.day).toList()
      ..sort((a, b) => a.priorityRank.compareTo(b.priorityRank));
    if (items.isEmpty) return 'You have no pending tasks due today. Create one focused task and give it a clear outcome.';
    final lines = items.take(5).map((t) => '• ${t.title} — ${t.priority}').join('\n');
    return 'Your suggested plan for today:\n$lines\n\nStart with the highest-priority item, then reassess after completing it.';
  }

  String _overdue() {
    final now = DateTime.now();
    final overdue = tasks.where((t) => !t.completed && DateTime(t.date.year, t.date.month, t.date.day).isBefore(DateTime(now.year, now.month, now.day))).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (overdue.isEmpty) return 'You have no overdue tasks.';
    return 'You have ${overdue.length} overdue task(s):\n${overdue.take(7).map((t) => '• ${t.title} — ${t.priority}').join('\n')}\n\nConsider completing, rescheduling, or archiving each one.';
  }

  String _priorityAdvice() {
    final pending = tasks.where((t) => !t.completed).toList()..sort((a, b) => a.priorityRank.compareTo(b.priorityRank));
    if (pending.isEmpty) return 'There are no pending tasks to prioritize.';
    return 'Priority suggestions based on your current task metadata:\n${pending.take(5).map((t) => '• ${t.title} — ${t.priority}').join('\n')}';
  }

  String _analyzeNotes() {
    if (notes.isEmpty) return 'You do not have any notes available for analysis yet.';
    final active = notes.where((n) => !n.isTrashed && !n.archived).toList();
    final actionable = active.where((n) => n.content.contains('?') || n.content.toLowerCase().contains('todo') || n.content.toLowerCase().contains('task')).length;
    final pinned = active.where((n) => n.pinned).length;
    return 'Local note analysis: ${active.length} active note(s), $pinned pinned, and $actionable note(s) that look potentially actionable.\n\nTip: ask me to turn an actionable idea into a task, then give it a due date.';
  }

  String _focusAdvice() {
    final pending = tasks.where((t) => !t.completed).toList()..sort((a, b) => a.priorityRank.compareTo(b.priorityRank));
    if (pending.isEmpty) return 'Your task list is clear. This is a good time to review notes or plan the next project.';
    return 'Focus suggestion: work on “${pending.first.title}” first. Use a 25–50 minute distraction-free session, then reassess your next task.';
  }

  bool _looksLikeComplete(String q) => q.startsWith('complete ') || q.startsWith('finish ') || q.contains('সম্পন্ন কর') || q.contains('শেষ কর');
  bool _looksLikeReschedule(String q) => q.contains('move ') || q.contains('reschedule') || q.contains('postpone') || (q.contains('tomorrow') && q.contains(' to ')) || q.contains('আগামীকাল');
  bool _looksLikePriorityChange(String q) => (q.contains('make ') && (q.contains('urgent') || q.contains('high') || q.contains('medium') || q.contains('low'))) || q.contains('জরুরি কর');
  bool _looksLikeDelete(String q) => q.startsWith('delete ') || q.startsWith('remove ') || q.contains('মুছে দাও');

  TodoItem? _findTask(String input) {
    var needle = input.trim();
    needle = needle.replaceFirst(RegExp(r'^(complete|finish|delete|remove|move|reschedule|postpone)\s+', caseSensitive: false), '');
    needle = needle.replaceAll(RegExp(r'\b(to|for|on)\s+(today|tomorrow)\b', caseSensitive: false), '').trim();
    if (needle.isEmpty) return null;
    for (final task in tasks.where((t) => !t.completed)) {
      if (task.title.toLowerCase().contains(needle.toLowerCase())) return task;
    }
    return null;
  }

  Future<String> _completeTaskFromPrompt(String input) async {
    final task = _findTask(input);
    if (task == null) return 'I could not find that task. Try “Complete presentation”.';
    task.completed = true;
    await _saveTasks();
    return 'Done. I marked “${task.title}” as completed.';
  }

  Future<String> _rescheduleTaskFromPrompt(String input) async {
    final task = _findTask(input);
    if (task == null) return 'I could not find that task. Try “Move presentation to tomorrow”.';
    final lower = input.toLowerCase();
    DateTime target;
    if (lower.contains('tomorrow') || input.contains('আগামীকাল')) {
      target = DateTime.now().add(const Duration(days: 1));
    } else if (lower.contains('today') || input.contains('আজ')) {
      target = DateTime.now();
    } else {
      return 'Tell me the target date, for example “Move presentation to tomorrow”.';
    }
    task.date = DateTime(target.year, target.month, target.day);
    await _saveTasks();
    return 'Done. “${task.title}” is now scheduled for ${_dateLabel(task.date)}.';
  }

  Future<String> _changePriorityFromPrompt(String input) async {
    final task = _findTask(input);
    if (task == null) return 'I could not find that task. Try “Make presentation urgent”.';
    final lower = input.toLowerCase();
    final priority = lower.contains('urgent') || input.contains('জরুরি') ? 'Urgent' : lower.contains('high') ? 'High' : lower.contains('low') ? 'Low' : 'Medium';
    task.priority = priority;
    await _saveTasks();
    return 'Done. “${task.title}” is now $priority priority.';
  }

  Future<String> _deleteTaskFromPrompt(String input) async {
    final task = _findTask(input);
    if (task == null) return 'I could not find that task. Try “Delete presentation”.';
    tasks.removeWhere((t) => t.id == task.id);
    await _saveTasks();
    return 'Deleted “${task.title}”.';
  }

  String _dailyBriefing() {
    final now = DateTime.now();
    final pending = tasks.where((t) => !t.completed).toList();
    final today = pending.where((t) => t.date.year == now.year && t.date.month == now.month && t.date.day == now.day).toList()..sort((a, b) => a.priorityRank.compareTo(b.priorityRank));
    final overdue = pending.where((t) => DateTime(t.date.year, t.date.month, t.date.day).isBefore(DateTime(now.year, now.month, now.day))).length;
    final urgent = pending.where((t) => t.priority == 'Urgent').length;
    return 'Daily briefing\n\n• Pending: ${pending.length}\n• Due today: ${today.length}\n• Overdue: $overdue\n• Urgent: $urgent\n\n${today.isEmpty ? 'No task is due today.' : 'First focus: ${today.first.title} (${today.first.priority}).'}';
  }

  String _dateLabel(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Taskly AI Pro', style: TextStyle(fontWeight: FontWeight.w900)), actions: [IconButton(onPressed: _loadContext, icon: const Icon(Icons.refresh_rounded))]),
      body: Column(children: [
        SizedBox(
          height: 54,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), children: [
            _chip('Plan my day'), _chip('Daily briefing'), _chip('Create task: '), _chip('Show overdue tasks'), _chip('What should I prioritize?'),
          ],),
        ),
        Expanded(
          child: ListView.builder(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            itemCount: messages.length,
            itemBuilder: (_, i) {
              final m = messages[i];
              return Align(
                alignment: m.user ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  constraints: const BoxConstraints(maxWidth: 350),
                  decoration: BoxDecoration(color: m.user ? CustomColors.primary : (dark ? const Color(0xFF181C28) : const Color(0xFFF2F4F8)), borderRadius: BorderRadius.circular(18)),
                  child: Text(m.text, style: TextStyle(color: m.user ? Colors.white : (dark ? Colors.white : CustomColors.text), height: 1.4)),
                ),
              );
            },
          ),
        ),
        if (thinking) const Padding(padding: EdgeInsets.only(bottom: 6), child: Text('Taskly AI Pro is thinking…')),
        SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(12, 6, 12, 10), child: Row(children: [
          Expanded(child: TextField(controller: controller, autofocus: true, textInputAction: TextInputAction.send, onSubmitted: (_) => _send(), decoration: InputDecoration(hintText: 'Ask Taskly AI Pro…', filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none)))),
          const SizedBox(width: 8),
          IconButton.filled(onPressed: thinking ? null : _send, icon: const Icon(Icons.send_rounded)),
        ]))),
      ]),
    );
  }

  Widget _chip(String text) => Padding(padding: const EdgeInsets.only(right: 7), child: ActionChip(label: Text(text, style: const TextStyle(fontSize: 12)), onPressed: () => _send(text)));
}
