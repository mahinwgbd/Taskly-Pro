import 'package:flutter/material.dart';
import 'home.dart';
import 'focus.dart';
import 'models.dart';
import 'util.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key, required this.tasks, required this.onToggle, required this.onDelete, required this.onEdit, required this.initialFilter, required this.onAdd, required this.onSearch});
  final List<TodoItem> tasks;
  final ValueChanged<TodoItem> onToggle;
  final ValueChanged<TodoItem> onDelete;
  final ValueChanged<TodoItem> onEdit;
  final String initialFilter;
  final VoidCallback onAdd;
  final VoidCallback onSearch;

  @override State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  late String filter;
  String query = '';
  bool showCompleted = true;
  String sort = 'Date';

  @override void initState() { super.initState(); filter = widget.initialFilter; }

  bool _isOverdue(TodoItem task) {
    if (task.completed) return false;
    final now = DateTime.now();
    final day = DateTime(task.date.year, task.date.month, task.date.day);
    return day.isBefore(DateTime(now.year, now.month, now.day));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.tasks.where((task) {
      final today = DateTime.now();
      final sameDay = task.date.year == today.year && task.date.month == today.month && task.date.day == today.day;
      final overdue = !task.completed && DateTime(task.date.year, task.date.month, task.date.day).isBefore(DateTime(today.year, today.month, today.day));
      final matchesFilter = switch (filter) { 'All' => true, 'Today' => sameDay, 'Overdue' => overdue, 'High Priority' => task.priority == 'High', 'Urgent' => task.priority == 'Urgent', _ => task.category == filter };
      final q = query.toLowerCase();
      final matchesQuery = task.title.toLowerCase().contains(q) || task.description.toLowerCase().contains(q);
      final matchesCompleted = showCompleted || !task.completed;
      return matchesFilter && matchesQuery && matchesCompleted;
    }).toList();

    filtered.sort((a, b) {
      if (sort == 'Priority') {
        return a.priorityRank.compareTo(b.priorityRank);
      }
      if (sort == 'Title') return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      if (sort == 'Created') return widget.tasks.indexOf(b).compareTo(widget.tasks.indexOf(a));
      return a.date.compareTo(b.date);
    });

    final overdueCount = widget.tasks.where(_isOverdue).length;

    return SafeArea(bottom: false, child: CustomScrollView(slivers: [
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(tr('My Tasks'), style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800))),
          IconButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FocusPage(tasks: widget.tasks))), tooltip: tr('Focus mode'), icon: Icon(Icons.timer_rounded, color: CustomColors.purple)),
          IconButton(onPressed: widget.onSearch, tooltip: tr('Search workspace'), icon: Icon(Icons.search_rounded)),
        ]),
        const SizedBox(height: 5),
        Row(children: [Expanded(child: Text('${localizeNumber(widget.tasks.length)} ${tr(widget.tasks.length == 1 ? 'task' : 'tasks')} ${tr('in your workspace')}', style: TextStyle(fontSize: 13, color: CustomColors.muted))), TextButton.icon(onPressed: widget.onAdd, icon: Icon(Icons.add_rounded, size: 18), label: Text(tr('Add task'), style: TextStyle(fontWeight: FontWeight.w700)))]),
        if (overdueCount > 0) Padding(padding: const EdgeInsets.only(top: 7), child: Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7), decoration: BoxDecoration(color: CustomColors.TrashRed.withOpacity(.09), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.warning_amber_rounded, size: 15, color: CustomColors.TrashRed), const SizedBox(width: 6), Text('${localizeNumber(overdueCount)} ${tr('overdue')} ${tr(overdueCount == 1 ? 'task' : 'tasks')}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: CustomColors.TrashRed))]))),
        const SizedBox(height: 12),
        TextField(onChanged: (v) => setState(() => query = v), decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: tr('Filter tasks...'))),
        const SizedBox(height: 12),
        SizedBox(height: 38, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: 5, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, i) { final items = ['All', 'Today', 'Overdue', 'High Priority', 'Urgent']; final item = items[i]; final active = i == 0 ? filter == 'All' : filter == item; return ChoiceChip(label: Text(tr(item)), selected: active, onSelected: (_) => setState(() => filter = item), selectedColor: CustomColors.purple, labelStyle: TextStyle(color: active ? Colors.white : CustomColors.muted, fontSize: 11, fontWeight: FontWeight.w700), side: BorderSide.none); })),
        const SizedBox(height: 8),
        SizedBox(height: 38, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: const ['Work', 'Personal', 'Meeting', 'Study', 'Shopping'].length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, i) { final item = const ['All', 'Work', 'Personal', 'Meeting', 'Study', 'Shopping'][i]; return ChoiceChip(label: Text(tr(item)), selected: filter == item, onSelected: (_) => setState(() => filter = item), selectedColor: CustomColors.primary, labelStyle: TextStyle(color: filter == item ? Colors.white : CustomColors.muted, fontSize: 12, fontWeight: FontWeight.w600), side: BorderSide.none); })),
        const SizedBox(height: 10),
        Row(children: [FilterChip(label: Text(tr('Hide done')), selected: !showCompleted, onSelected: (v) => setState(() => showCompleted = !v), selectedColor: CustomColors.green.withOpacity(.18), side: BorderSide.none), Spacer(), PopupMenuButton<String>(initialValue: sort, onSelected: (value) => setState(() => sort = value), itemBuilder: (_) => [PopupMenuItem(value: 'Date', child: Text(tr('Sort by date'))), PopupMenuItem(value: 'Priority', child: Text(tr('Sort by priority'))), PopupMenuItem(value: 'Created', child: Text(tr('Recently added'))), PopupMenuItem(value: 'Title', child: Text(tr('Sort by title')))], child: Container(padding: EdgeInsets.symmetric(horizontal: 11, vertical: 8), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.sort_rounded, size: 16, color: CustomColors.muted), SizedBox(width: 5), Text(tr(sort), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: CustomColors.muted))])))]),
      ]))),
      if (filtered.isEmpty) SliverToBoxAdapter(child: _NoSearchResult(onAdd: widget.onAdd, hasTasks: widget.tasks.isNotEmpty)) else SliverList.builder(itemCount: filtered.length, itemBuilder: (_, i) => _TaskRow(task: filtered[i], overdue: _isOverdue(filtered[i]), onToggle: widget.onToggle, onDelete: widget.onDelete, onEdit: widget.onEdit)),
      const SliverToBoxAdapter(child: SizedBox(height: 120)),
    ]));
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task, required this.overdue, required this.onToggle, required this.onDelete, required this.onEdit});
  final TodoItem task; final bool overdue; final ValueChanged<TodoItem> onToggle; final ValueChanged<TodoItem> onDelete; final ValueChanged<TodoItem> onEdit;
  @override Widget build(BuildContext context) => Stack(children: [TaskCard(task: task, onToggle: onToggle, onDelete: onDelete, onEdit: onEdit), if (overdue) Positioned(right: 35, top: 10, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: CustomColors.TrashRed.withOpacity(.1), borderRadius: BorderRadius.circular(7)), child: Text(tr('OVERDUE'), style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w900, color: CustomColors.TrashRed))))]);
}

class _NoSearchResult extends StatelessWidget { _NoSearchResult({required this.onAdd, required this.hasTasks}); final VoidCallback onAdd; final bool hasTasks; @override Widget build(BuildContext context) => Padding(padding: EdgeInsets.all(40), child: Column(children: [Icon(Icons.task_alt_rounded, size: 52, color: CustomColors.primary), SizedBox(height: 12), Text(hasTasks ? tr('No matching tasks') : tr('Your task list is empty'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)), SizedBox(height: 5), Text(hasTasks ? tr('Try another search or category.') : tr('Add something you want to get done.'), style: TextStyle(color: CustomColors.muted, fontSize: 12), textAlign: TextAlign.center), SizedBox(height: 14), FilledButton.icon(onPressed: onAdd, icon: Icon(Icons.add_rounded), label: Text(tr('Add task')))]));
}
