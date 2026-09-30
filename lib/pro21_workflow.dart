import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'util.dart';

class TasklyPro21WorkflowPage extends StatefulWidget {
  const TasklyPro21WorkflowPage({super.key});
  @override
  State<TasklyPro21WorkflowPage> createState() => _TasklyPro21WorkflowPageState();
}

class _TasklyPro21WorkflowPageState extends State<TasklyPro21WorkflowPage> {
  static const _tasksKey = 'taskly_tasks_v6';
  List<TodoItem> tasks = [];
  final templates = const [
    ('University Project', Icons.school_rounded, ['Research', 'Requirements', 'UI Design', 'Development', 'Testing', 'Presentation']),
    ('Work Project', Icons.work_rounded, ['Planning', 'Implementation', 'Review', 'Delivery']),
    ('Weekly Planning', Icons.calendar_month_rounded, ['Review last week', 'Plan priorities', 'Schedule focus time']),
  ];

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    try {
      final raw = p.getString(_tasksKey);
      final decoded = raw == null ? null : jsonDecode(raw);
      if (decoded is List) {
        tasks = decoded.whereType<Map>().map((e) => TodoItem.fromJson(Map<String,dynamic>.from(e))).toList();
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _saveTasks() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_tasksKey, jsonEncode(tasks.map((e) => e.toJson()).toList()));
  }

  Future<void> _createTemplate((String, IconData, List<String>) template) async {
    final now = DateTime.now();
    final created = <TodoItem>[];
    for (var i = 0; i < template.$3.length; i++) {
      created.add(TodoItem(title: template.$3[i], time: '', category: 'Project', date: now.add(Duration(days: i)), priority: i == 0 ? 'High' : 'Medium', description: 'Created from ${template.$1} template'));
    }
    tasks.addAll(created);
    await _saveTasks();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${template.$1}: ${localizeNumber(created.length)} tasks created')));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF181C28) : Colors.white;
    return Scaffold(
      appBar: AppBar(title: const Text('Pro 2.1 Workflow', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        _intro(dark), const SizedBox(height: 18),
        Text('Project Templates', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: dark ? Colors.white : CustomColors.text)),
        const SizedBox(height: 10),
        ...templates.map((t) => Card(color: surface, child: ListTile(
          leading: CircleAvatar(backgroundColor: CustomColors.primary.withOpacity(.12), child: Icon(t.$2, color: CustomColors.primary)),
          title: Text(t.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text('${localizeNumber(t.$3.length)} linked tasks'),
          trailing: FilledButton(onPressed: () => _createTemplate(t), child: const Text('Create')),
        ))),
        const SizedBox(height: 18),
        _info(dark, Icons.account_tree_rounded, 'Dependencies', 'Link tasks so blocked work cannot be treated as ready until its prerequisite is completed.'),
        _info(dark, Icons.checklist_rounded, 'Bulk Actions', 'Select multiple tasks to complete, archive, delete or change priority together.'),
        _info(dark, Icons.filter_alt_rounded, 'Saved Filters', 'Combine status, priority, category and due-date filters into reusable views.'),
        _info(dark, Icons.timeline_rounded, 'Activity Timeline', 'Keep a history of important task changes for future productivity insights.'),
      ]),
    );
  }

  Widget _intro(bool dark) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: LinearGradient(colors: dark ? const [Color(0xFF202A55), Color(0xFF302044)] : const [Color(0xFFEAF1FF), Color(0xFFF5EEFF)]), borderRadius: BorderRadius.circular(24)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.auto_awesome_rounded, size: 32), SizedBox(height: 10), Text('Automate your workflow', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)), SizedBox(height: 5), Text('Turn repeatable plans into templates and prepare Taskly for dependencies, projects and smart automation.', style: TextStyle(height: 1.4))]));
  Widget _info(bool dark, IconData icon, String title, String text) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: dark ? const Color(0xFF181C28) : Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: dark ? Colors.white10 : const Color(0x11000000))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: CustomColors.primary), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(text, style: TextStyle(color: dark ? Colors.white60 : CustomColors.muted, height: 1.35))]))]));
}
