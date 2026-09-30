import 'package:flutter/material.dart';
import 'models.dart';
import 'util.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key, required this.tasks});
  final List<TodoItem> tasks;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = tasks.where((t) => _sameDay(t.date, now)).toList();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final week = tasks.where((t) => !t.date.isBefore(weekStart)).toList();
    final completed = tasks.where((t) => t.completed).length;
    final pending = tasks.where((t) => !t.completed).length;
    final overdue = tasks.where((t) =>
        !t.completed &&
        DateTime(t.date.year, t.date.month, t.date.day)
            .isBefore(DateTime(now.year, now.month, now.day))).length;
    final high = tasks.where((t) => !t.completed && t.priority == 'High').length;
    final rate = tasks.isEmpty ? 0.0 : completed / tasks.length;
    final streak = _streak(tasks, now);
    final badges = completed >= 50 ? 'Legend' : completed >= 20 ? 'Achiever' : completed >= 5 ? 'Getting started' : 'First win';

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('Insights'), style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                  SizedBox(height: 5),
                  Text(tr('See how consistently you turn plans into progress.'), style: TextStyle(fontSize: 12, color: CustomColors.muted)),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: [
                _StatCard(tr('Completion'), '${localizeNumber((rate * 100).round())}%', Icons.trending_up_rounded, CustomColors.green),
                _StatCard(tr('Pending'), localizeNumber(pending), Icons.pending_actions_rounded, CustomColors.primary),
                _StatCard(tr('Overdue'), localizeNumber(overdue), Icons.warning_amber_rounded, const Color(0xFFF45151)),
                _StatCard(tr('High priority'), localizeNumber(high), Icons.priority_high_rounded, CustomColors.orange),
              ],
            ),
          ),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 0), child: Row(children: [Expanded(child: _Highlight(icon: Icons.local_fire_department_rounded, title: '${localizeNumber(streak)} ${tr('day streak')}', subtitle: streak == 0 ? tr('Complete a task today to start.') : tr('Keep the chain alive.'), color: CustomColors.orange)), const SizedBox(width: 10), Expanded(child: _Highlight(icon: Icons.emoji_events_rounded, title: tr(badges), subtitle: '${localizeNumber(completed)} ${tr(completed == 1 ? 'completed task' : 'completed tasks')}', color: CustomColors.purple))]))),
          SliverToBoxAdapter(
            child: _Section(
              title: tr('Today'),
              child: Row(
                children: [
                  Expanded(child: _MiniMetric(label: tr('Tasks'), value: localizeNumber(today.length))),
                  Expanded(child: _MiniMetric(label: tr('Done'), value: localizeNumber(today.where((t) => t.completed).length))),
                  Expanded(child: _MiniMetric(label: tr('Pending'), value: localizeNumber(today.where((t) => !t.completed).length))),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _Section(
              title: tr('This week'),
              child: Column(
                children: List.generate(7, (index) {
                  final day = weekStart.add(Duration(days: index));
                  final dayTasks = week.where((t) => _sameDay(t.date, day)).toList();
                  final done = dayTasks.where((t) => t.completed).length;
                  return _DayBar(
                    label: tr(_weekday(day.weekday)),
                    count: dayTasks.length,
                    done: done,
                  );
                }),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _Section(
              title: tr('Categories'),
              child: Column(
                children: ['Work', 'Personal', 'Meeting', 'Study', 'Shopping']
                    .map((category) {
                  final total = tasks.where((t) => t.category == category).length;
                  final done = tasks.where((t) => t.category == category && t.completed).length;
                  final value = total == 0 ? 0.0 : done / total;
                  return _CategoryBar(category: tr(category), done: done, total: total, value: value);
                }).toList(),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  int _streak(List<TodoItem> all, DateTime now) {
    final completedDays = all.where((t) => t.completed).map((t) => DateTime(t.date.year, t.date.month, t.date.day)).toSet();
    var day = DateTime(now.year, now.month, now.day);
    if (!completedDays.contains(day)) day = day.subtract(const Duration(days: 1));
    var count = 0;
    while (completedDays.contains(day)) { count++; day = day.subtract(const Duration(days: 1)); }
    return count;
  }

  String _weekday(int day) => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day - 1];
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.title, this.value, this.icon, this.color);
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 6))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withOpacity(.11), shape: BoxShape.circle), child: Icon(icon, color: color, size: 19)),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
        Text(title, style: const TextStyle(fontSize: 10.5, color: CustomColors.muted, fontWeight: FontWeight.w600)),
      ]),
    ]),
  );
}

class _Highlight extends StatelessWidget {
  const _Highlight({required this.icon, required this.title, required this.subtitle, required this.color});
  final IconData icon; final String title; final String subtitle; final Color color;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(19)), child: Row(children: [Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withOpacity(.11), shape: BoxShape.circle), child: Icon(icon, color: color, size: 18)), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)), const SizedBox(height: 2), Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, color: CustomColors.muted))]))]));
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 25, 20, 0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(22)),
        child: child,
      ),
    ]),
  );
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});
  final String label; final String value;
  @override Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
    const SizedBox(height: 3),
    Text(label, style: const TextStyle(fontSize: 10, color: CustomColors.muted)),
  ]);
}

class _DayBar extends StatelessWidget {
  const _DayBar({required this.label, required this.count, required this.done});
  final String label; final int count; final int done;
  @override Widget build(BuildContext context) {
    final value = count == 0 ? 0.0 : done / count;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        SizedBox(width: 34, child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: CustomColors.muted))),
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: value, minHeight: 8, backgroundColor: CustomColors.primary.withOpacity(.08), valueColor: const AlwaysStoppedAnimation(CustomColors.primary)))),
        SizedBox(width: 40, child: Text('${localizeNumber(done)}/${localizeNumber(count)}', textAlign: TextAlign.end, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: CustomColors.muted))),
      ]),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.category, required this.done, required this.total, required this.value});
  final String category; final int done; final int total; final double value;
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      SizedBox(width: 72, child: Text(category, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: CustomColors.muted))),
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: value, minHeight: 8, backgroundColor: CustomColors.purple.withOpacity(.08), valueColor: const AlwaysStoppedAnimation(CustomColors.purple)))),
      SizedBox(width: 40, child: Text('${localizeNumber(done)}/${localizeNumber(total)}', textAlign: TextAlign.end, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: CustomColors.muted))),
    ]),
  );
}
