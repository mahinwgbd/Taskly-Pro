import 'package:flutter/material.dart';
import 'util.dart';
import 'pro_notes_page.dart';
import 'pro2_dashboard.dart';
import 'pro21_workflow.dart';
import 'pro_ai_chat.dart';

class TasklyProPage extends StatelessWidget {
  const TasklyProPage({super.key});

  static const features = <Map<String, dynamic>>[
    {'icon': Icons.cloud_sync_rounded, 'title': 'Cloud Backup & Sync', 'subtitle': 'Google Drive backup with safer restore workflows.'},
    {'icon': Icons.insights_rounded, 'title': 'Advanced Insights', 'subtitle': 'Productivity trends, completion rate and deeper analytics.'},
    {'icon': Icons.task_alt_rounded, 'title': 'Advanced Tasks', 'subtitle': 'Recurring tasks, subtasks, priorities, dependencies and workflows.'},
    {'icon': Icons.note_alt_rounded, 'title': 'Advanced Notes', 'subtitle': 'Tags, pinning, archive, trash and Note → Task.'},
    {'icon': Icons.timer_rounded, 'title': 'Focus Pro', 'subtitle': 'Focused work sessions and productivity history.'},
    {'icon': Icons.notifications_active_rounded, 'title': 'Smart Reminders', 'subtitle': 'Reliable scheduled reminders with recovery handling.'},
    {'icon': Icons.lock_rounded, 'title': 'Privacy & Security', 'subtitle': 'App lock, biometric protection and encrypted local workspace.'},
    {'icon': Icons.smart_toy_rounded, 'title': 'AI Productivity Assistant', 'subtitle': 'Plan days, analyze notes, prioritize tasks and create tasks with natural language.'},
    {'icon': Icons.file_download_rounded, 'title': 'Advanced Export', 'subtitle': 'Keep your workspace portable with structured backups.'},
  ];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Taskly Pro', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: dark ? const [Color(0xFF202A55), Color(0xFF33234F)] : const [Color(0xFFEAF1FF), Color(0xFFF6EEFF)]),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: CustomColors.primary.withOpacity(.18)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 58, height: 58, decoration: BoxDecoration(color: CustomColors.primary, borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 31)),
                const SizedBox(width: 15),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Taskly Pro', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
                  SizedBox(height: 3),
                  Text('Plan smarter • Focus deeper • Finish more', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ])),
              ]),
              const SizedBox(height: 18),
              Text('Your complete productivity workspace.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: dark ? Colors.white : CustomColors.text)),
              const SizedBox(height: 6),
              Text('Pro builds on the Taskly core while adding deeper productivity, backup and workflow capabilities.', style: TextStyle(height: 1.45, color: dark ? Colors.white70 : CustomColors.muted)),
            ]),
          ),
          const SizedBox(height: 22),
          Text('Pro capabilities', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: dark ? Colors.white : CustomColors.text)),
          const SizedBox(height: 10),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: dark ? const Color(0xFF181C28) : Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: dark ? Colors.white10 : const Color(0x11000000))),
              child: Row(children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: CustomColors.primary.withOpacity(.10), borderRadius: BorderRadius.circular(14)), child: Icon(f['icon'] as IconData, color: CustomColors.primary)),
                const SizedBox(width: 13),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(f['title'] as String, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(f['subtitle'] as String, style: TextStyle(fontSize: 12.5, height: 1.3, color: dark ? Colors.white60 : CustomColors.muted))])),
                const Icon(Icons.check_circle_rounded, color: CustomColors.primary, size: 21),
              ]),
            ),
          )),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TasklyPro2Dashboard())),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Open Pro 2.0 Intelligence', style: TextStyle(fontWeight: FontWeight.w900)),
          )),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TasklyProNotesPage())),
            icon: const Icon(Icons.menu_book_rounded),
            label: const Text('Open Advanced Notes', style: TextStyle(fontWeight: FontWeight.w900)),
          )),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TasklyPro21WorkflowPage())),
            icon: const Icon(Icons.account_tree_rounded),
            label: const Text('Open Pro 2.1 Workflow', style: TextStyle(fontWeight: FontWeight.w900)),
          )),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TasklyProAiChatPage())),
            icon: const Icon(Icons.smart_toy_rounded),
            label: const Text('Open Taskly AI Pro 2.4', style: TextStyle(fontWeight: FontWeight.w900)),
          )),
          const SizedBox(height: 12),
          Text('This Pro edition uses the same Taskly workspace/data model, so your existing Tasks and Notes remain compatible.', style: TextStyle(fontSize: 12, height: 1.4, color: dark ? Colors.white54 : CustomColors.muted)),
        ],
      ),
    );
  }
}
