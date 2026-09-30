import 'package:flutter/material.dart';

import 'home.dart';
import 'models.dart';
import 'util.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({
    super.key,
    required this.tasks,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    required this.onAdd,
  });

  final List<TodoItem> tasks;
  final ValueChanged<TodoItem> onToggle;
  final ValueChanged<TodoItem> onDelete;
  final ValueChanged<TodoItem> onEdit;
  final VoidCallback onAdd;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime selected = DateTime.now();

  bool sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final dayTasks = widget.tasks
        .where((task) => sameDay(task.date, selected))
        .toList();

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('Calendar'),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                                                      ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          tr('Plan your days without losing the big picture.'),
                          style: TextStyle(
                            fontSize: 12,
                            color: CustomColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onAdd,
                    icon: const Icon(
                      Icons.add_circle_rounded,
                      color: CustomColors.primary,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(14, 8, 14, 18),
              padding: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: CalendarDatePicker(
                initialDate: selected,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                onDateChanged: (value) {
                  setState(() => selected = value);
                },
                selectableDayPredicate: (_) => true,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _dateTitle(selected),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                                              ),
                    ),
                  ),
                  Text(
                    '${localizeNumber(dayTasks.length)} ${tr(dayTasks.length == 1 ? 'task' : 'tasks')}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: CustomColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (dayTasks.isEmpty)
            SliverToBoxAdapter(
              child: _CalendarEmpty(onAdd: widget.onAdd),
            )
          else
            SliverList.builder(
              itemCount: dayTasks.length,
              itemBuilder: (_, i) {
                return TaskCard(
                  task: dayTasks[i],
                  onToggle: widget.onToggle,
                  onDelete: widget.onDelete,
                  onEdit: widget.onEdit,
                );
              },
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      ),
    );
  }

  String _dateTitle(DateTime d) {
    final now = DateTime.now();
    if (sameDay(now, d)) return tr('Today');
    return '${tr(_weekday(d.weekday))}, ${localizeNumber(d.day)}/${localizeNumber(d.month)}/${localizeNumber(d.year)}';
  }

  String _weekday(int day) {
    return const [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ][day - 1];
  }
}

class _CalendarEmpty extends StatelessWidget {
  const _CalendarEmpty({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_available_rounded,
            size: 42,
            color: CustomColors.primary,
          ),
          const SizedBox(height: 10),
          Text(
            tr('Nothing planned here'),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            tr('Keep the day light or add a task.'),
            style: TextStyle(fontSize: 12, color: CustomColors.muted),
          ),
          const SizedBox(height: 13),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: Text(tr('Add task')),
          ),
        ],
      ),
    );
  }
}
