import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'util.dart';

/// Taskly Pro 2.0 productivity intelligence dashboard.
///
/// This is intentionally local-first: recommendations are generated from the
/// user's existing Taskly data without sending task/note content anywhere.
class TasklyPro2Dashboard extends StatefulWidget {
  const TasklyPro2Dashboard({super.key});

  @override
  State<TasklyPro2Dashboard> createState() => _TasklyPro2DashboardState();
}

class _TasklyPro2DashboardState extends State<TasklyPro2Dashboard> {
  static const _tasksKey = 'taskly_tasks_v6';
  static const _notesKey = 'taskly_notes_v6';
  List<TodoItem> tasks = [];
  List<NoteItem> notes = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final loadedTasks = <TodoItem>[];
    final loadedNotes = <NoteItem>[];
    try {
      final raw = prefs.getString(_tasksKey);
      final decoded = raw == null ? null : jsonDecode(raw);
      if (decoded is List) {
        final seen = <String>{};
        for (final item in decoded) {
          if (item is! Map) continue;
          final task = TodoItem.fromJson(Map<String, dynamic>.from(item));
          if (task.title.trim().isEmpty || !seen.add(task.id)) continue;
          loadedTasks.add(task);
        }
      }
    } catch (_) {}
    try {
      final raw = prefs.getString(_notesKey);
      final decoded = raw == null ? null : jsonDecode(raw);
      if (decoded is List) {
        final seen = <String>{};
        for (final item in decoded) {
          if (item is! Map) continue;
          final note = NoteItem.fromJson(Map<String, dynamic>.from(item));
          if (!seen.add(note.id)) continue;
          loadedNotes.add(note);
        }
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      tasks = loadedTasks;
      notes = loadedNotes;
      loading = false;
    });
  }

  DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
  bool _sameDay(DateTime a, DateTime b) => _day(a) == _day(b);

  int get completed => tasks.where((t) => t.completed).length;
  int get pending => tasks.where((t) => !t.completed).length;
  int get overdue => tasks.where((t) => !t.completed && _day(t.date).isBefore(_day(DateTime.now()))).length;
  int get dueToday => tasks.where((t) => !t.completed && _sameDay(t.date, DateTime.now())).length;

  int get streak {
    final days = tasks.where((t) => t.completed).map((t) => _day(t.date)).toSet();
    var cursor = _day(DateTime.now());
    if (!days.contains(cursor)) cursor = cursor.subtract(const Duration(days: 1));
    var result = 0;
    while (days.contains(cursor)) {
      result++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return result;
  }

  double get score {
    if (tasks.isEmpty) return 0;
    final completion = completed / tasks.length;
    final overduePenalty = (overdue / tasks.length).clamp(0.0, .35).toDouble();
    final consistency = (streak / 7).clamp(0.0, 1.0).toDouble() * .15;
    return ((completion * .70) + consistency - overduePenalty).clamp(0.0, 1.0).toDouble();
  }

  String get scoreLabel {
    final s = score;
    if (tasks.isEmpty) return tr('Build your first plan');
    if (s >= .8) return tr('Excellent momentum');
    if (s >= .6) return tr('Strong progress');
    if (s >= .4) return tr('Good start');
    return tr('Reset and refocus');
  }

  String get smartNextAction {
    final urgent = tasks.where((t) => !t.completed && t.priority == 'Urgent').toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (urgent.isNotEmpty) return '${tr('Start with')}: ${urgent.first.title}';
    final today = tasks.where((t) => !t.completed && _sameDay(t.date, DateTime.now())).toList()
      ..sort((a, b) => a.priorityRank.compareTo(b.priorityRank));
    if (today.isNotEmpty) return '${tr('Next up')}: ${today.first.title}';
    final upcoming = tasks.where((t) => !t.completed && !_day(t.date).isBefore(_day(DateTime.now()))).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (upcoming.isNotEmpty) return '${tr('Plan ahead')}: ${upcoming.first.title}';
    return tr('Create one focused task for your next step.');
  }

  List<String> get suggestions {
    final result = <String>[];
    if (overdue > 0) result.add('${tr('Clear')} ${localizeNumber(overdue)} ${tr('overdue task(s) before adding more.')}' );
    if (dueToday >= 4) result.add(tr('Your day is busy. Consider moving one low-priority task to tomorrow.'));
    if (completed > 0 && streak >= 3) result.add('${tr('You have a')} ${localizeNumber(streak)} ${tr('day streak. Protect a small focus block today.')}');
    if (notes.isNotEmpty && pending > 0) result.add(tr('Turn one useful note into a concrete task.'));
    if (result.isEmpty) result.add(tr('Set one clear priority and finish it before switching context.'));
    return result.take(3).toList();
  }

  Map<String, int> get priorities {
    final map = {'Urgent': 0, 'High': 0, 'Medium': 0, 'Low': 0};
    for (final task in tasks) {
      map[task.priority] = (map[task.priority] ?? 0) + 1;
    }
    return map;
  }

  List<int> get weekDone {
    final now = _day(DateTime.now());
    final start = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) {
      final d = start.add(Duration(days: i));
      return tasks.where((t) => t.completed && _sameDay(t.date, d)).length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final scorePercent = (score * 100).round();
    final bars = weekDone;
    final maxBar = (bars.fold<int>(1, (a, b) => a > b ? a : b)).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Taskly Pro 2.0', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
          children: [
            _hero(context, dark, scorePercent),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _metric(context, tr('Completed'), localizeNumber(completed), Icons.check_circle_rounded, CustomColors.green)),
              const SizedBox(width: 10),
              Expanded(child: _metric(context, tr('Pending'), localizeNumber(pending), Icons.pending_actions_rounded, CustomColors.primary)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _metric(context, tr('Overdue'), localizeNumber(overdue), Icons.warning_amber_rounded, const Color(0xFFF45151))),
              const SizedBox(width: 10),
              Expanded(child: _metric(context, tr('Streak'), '${localizeNumber(streak)}d', Icons.local_fire_department_rounded, CustomColors.orange)),
            ]),
            const SizedBox(height: 18),
            _section(context, tr('Smart next action'), Icons.auto_awesome_rounded, Text(smartNextAction, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, height: 1.35))),
            const SizedBox(height: 14),
            _section(
              context,
              tr('Weekly momentum'),
              Icons.show_chart_rounded,
              SizedBox(
                height: 150,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (i) {
                    final value = bars[i] / maxBar;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(localizeNumber(bars[i]), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 5),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              height: 92 * value + 4,
                              decoration: BoxDecoration(
                                color: CustomColors.primary.withOpacity(.80),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(const ['M','T','W','T','F','S','S'][i], style: const TextStyle(fontSize: 10, color: CustomColors.muted, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _section(context, tr('Priority distribution'), Icons.flag_rounded, Column(children: priorities.entries.map((e) {
              final total = tasks.length == 0 ? 1 : tasks.length;
              final value = e.value / total;
              return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
                SizedBox(width: 64, child: Text(tr(e.key), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: value, minHeight: 8, backgroundColor: CustomColors.primary.withOpacity(.07), valueColor: AlwaysStoppedAnimation(_priorityColor(e.key))))),
                SizedBox(width: 32, child: Text(localizeNumber(e.value), textAlign: TextAlign.end, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
              ]));
            }).toList())),
            const SizedBox(height: 14),
            _section(
              context,
              tr('Smart suggestions'),
              Icons.tips_and_updates_rounded,
              Column(
                children: suggestions.map<Widget>((s) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: CustomColors.primary.withOpacity(.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lightbulb_rounded, size: 18, color: CustomColors.primary),
                    ),
                    title: Text(s, style: const TextStyle(fontSize: 12.5, height: 1.35, fontWeight: FontWeight.w700)),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            _section(context, tr('Workspace health'), Icons.health_and_safety_rounded, Column(children: [
              _healthRow(tr('Tasks planned'), localizeNumber(tasks.length), tasks.isNotEmpty),
              _healthRow(tr('Notes available'), localizeNumber(notes.length), notes.isNotEmpty),
              _healthRow(tr('Today due'), localizeNumber(dueToday), dueToday < 5),
              _healthRow(tr('Overdue load'), localizeNumber(overdue), overdue == 0),
            ])),
            const SizedBox(height: 16),
            Text(tr('All recommendations are generated locally from your Taskly workspace. Task content is not sent to an AI service by this dashboard.'), style: TextStyle(fontSize: 11, height: 1.4, color: dark ? Colors.white54 : CustomColors.muted)),
          ],
        ),
      ),
    );
  }

  Color _priorityColor(String p) => switch (p) { 'Urgent' => const Color(0xFFFF2D55), 'High' => const Color(0xFFF45151), 'Low' => const Color(0xFF25B8D6), _ => CustomColors.orange };

  Widget _hero(BuildContext context, bool dark, int percent) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: dark ? const [Color(0xFF182448), Color(0xFF30204A)] : const [Color(0xFFEAF1FF), Color(0xFFF4ECFF)]),
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: CustomColors.primary.withOpacity(.15)),
    ),
    child: Row(children: [
      SizedBox(width: 92, height: 92, child: Stack(fit: StackFit.expand, children: [
        CircularProgressIndicator(value: score, strokeWidth: 9, backgroundColor: CustomColors.primary.withOpacity(.10), valueColor: const AlwaysStoppedAnimation(CustomColors.primary)),
        Center(child: Text('$percent%', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900))),
      ])),
      const SizedBox(width: 17),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Productivity Intelligence', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(scoreLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: dark ? Colors.white70 : CustomColors.muted)),
        const SizedBox(height: 9),
        Text('${tr('Today')}: ${localizeNumber(dueToday)} ${tr('task(s) due')} • ${localizeNumber(completed)} ${tr('completed overall')}', style: TextStyle(fontSize: 11, height: 1.35, color: dark ? Colors.white60 : CustomColors.muted)),
      ])),
    ]),
  );

  Widget _metric(BuildContext context, String label, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)),
    child: Row(children: [Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withOpacity(.11), shape: BoxShape.circle), child: Icon(icon, color: color, size: 19)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(fontSize: 10.5, color: CustomColors.muted, fontWeight: FontWeight.w700))]))]),
  );

  Widget _section(BuildContext context, String title, IconData icon, Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(22)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Container(width: 34, height: 34, decoration: BoxDecoration(color: CustomColors.primary.withOpacity(.10), shape: BoxShape.circle), child: Icon(icon, color: CustomColors.primary, size: 18)), const SizedBox(width: 9), Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900))]),
      const SizedBox(height: 12),
      child,
    ]),
  );

  Widget _healthRow(String label, String value, bool good) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CustomColors.muted))), Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)), const SizedBox(width: 8), Icon(good ? Icons.check_circle_rounded : Icons.info_rounded, size: 17, color: good ? CustomColors.green : CustomColors.orange)]));
}
