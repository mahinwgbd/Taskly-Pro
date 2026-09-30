import 'package:flutter/material.dart';

import 'models.dart';
import 'util.dart';

Future<TodoItem?> showTaskEditorSheet(BuildContext context, {TodoItem? task}) {
  return showModalBottomSheet<TodoItem>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TaskEditorSheet(task: task),
  );
}

Future<TodoItem?> showAddTaskSheet(BuildContext context) => showTaskEditorSheet(context);

Future<String?> showAddNoteSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AddNoteSheet(),
  );
}

class _TaskEditorSheet extends StatefulWidget {
  const _TaskEditorSheet({this.task});
  final TodoItem? task;

  @override
  State<_TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<_TaskEditorSheet> {
  late final TextEditingController title;
  late final TextEditingController description;
  late String category;
  late String priority;
  late String repeat;
  late bool reminder;
  late DateTime date;
  late TimeOfDay time;
  late List<SubtaskItem> subtasks;
  final subtaskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    title = TextEditingController(text: task?.title ?? '');
    description = TextEditingController(text: task?.description ?? '');
    category = task?.category ?? 'Personal';
    priority = task?.priority ?? 'Medium';
    repeat = task?.repeat ?? 'Does not repeat';
    reminder = task?.reminder ?? false;
    date = task?.date ?? DateTime.now();
    time = _parseTime(task?.time) ?? TimeOfDay.now();
    subtasks = List.of(task?.subtasks ?? const []);
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null || value.isEmpty) return null;
    final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$', caseSensitive: false).firstMatch(value.trim());
    if (match == null) return null;
    var hour = int.tryParse(match.group(1)!) ?? 10;
    final minute = int.tryParse(match.group(2)!) ?? 0;
    final meridiem = match.group(3)?.toUpperCase();
    if (meridiem == 'PM' && hour < 12) hour += 12;
    if (meridiem == 'AM' && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    subtaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final editing = widget.task != null;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 720),
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const _Handle(),
            const SizedBox(height: 20),
            _SheetHeader(title: editing ? tr('Edit task') : tr('Add a new task'), subtitle: editing ? tr('Refine the details and keep moving.') : tr('Turn your next action into progress.'), onClose: () => Navigator.pop(context)),
            const SizedBox(height: 16),
            TextField(controller: title, autofocus: !editing, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(labelText: tr('Task name'), hintText: tr('What needs to be done?'))),
            const SizedBox(height: 12),
            TextField(controller: description, maxLines: 2, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(labelText: tr('Description (optional)'), hintText: tr('Add a little context...'))),
            const SizedBox(height: 16),
            Text(tr('Category'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 9),
            Wrap(spacing: 8, runSpacing: 8, children: ['Personal', 'Work', 'Meeting', 'Study', 'Shopping'].map((item) => ChoiceChip(label: Text(tr(item)), selected: category == item, onSelected: (_) => setState(() => category = item), selectedColor: CustomColors.primary, labelStyle: TextStyle(color: category == item ? Colors.white : CustomColors.muted, fontSize: 11, fontWeight: FontWeight.w600), side: BorderSide.none)).toList()),
            const SizedBox(height: 16),
            Text(tr('Priority'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 9),
            Wrap(spacing: 8, children: ['Urgent', 'High', 'Medium', 'Low'].map((item) => ChoiceChip(label: Text(tr(item)), selected: priority == item, onSelected: (_) => setState(() => priority = item), selectedColor: _priorityColor(item), labelStyle: TextStyle(color: priority == item ? Colors.white : CustomColors.muted, fontSize: 11, fontWeight: FontWeight.w600), side: BorderSide.none)).toList()),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _SheetOption(icon: Icons.calendar_today_rounded, title: tr('Date'), value: _dateLabel(date), onTap: _pickDate)),
              const SizedBox(width: 10),
              Expanded(child: _SheetOption(icon: Icons.schedule_rounded, title: tr('Time'), value: localizeDigits(time.format(context)), onTap: _pickTime)),
            ]),
            const SizedBox(height: 18),
            Row(children: [Expanded(child: Text(tr('Subtasks'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800))), if (subtasks.isNotEmpty) Text('${localizeNumber(subtasks.where((s) => s.completed).length)}/${localizeNumber(subtasks.length)}', style: TextStyle(fontSize: 10, color: CustomColors.muted, fontWeight: FontWeight.w700))]),
            const SizedBox(height: 7),
            ...subtasks.asMap().entries.map((entry) => ListTile(contentPadding: EdgeInsets.zero, dense: true, leading: Checkbox(value: entry.value.completed, onChanged: (v) => setState(() => subtasks[entry.key] = entry.value.copyWith(completed: v ?? false))), title: Text(entry.value.title, style: TextStyle(fontSize: 11.5, decoration: entry.value.completed ? TextDecoration.lineThrough : null)), trailing: IconButton(onPressed: () => setState(() => subtasks.removeAt(entry.key)), icon: const Icon(Icons.close_rounded, size: 17)))),
            Row(children: [Expanded(child: TextField(controller: subtaskController, onSubmitted: (_) => _addSubtask(), decoration: InputDecoration(hintText: tr('Add a small step')))), SizedBox(width: 7), IconButton.filled(onPressed: _addSubtask, icon: Icon(Icons.add_rounded))]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _SheetOption(icon: Icons.repeat_rounded, title: tr('Repeat'), value: tr(repeat), onTap: _pickRepeat)),
              const SizedBox(width: 10),
              Expanded(child: _SheetOption(icon: reminder ? Icons.notifications_active_rounded : Icons.notifications_none_rounded, title: tr('Reminder'), value: reminder ? tr('On') : tr('Off'), onTap: () => setState(() => reminder = !reminder))),
            ]),
            const SizedBox(height: 22),
            SizedBox(width: double.infinity, height: 56, child: FilledButton.icon(onPressed: _submit, icon: Icon(editing ? Icons.check_rounded : Icons.add_rounded), label: Text(editing ? tr('Save changes') : tr('Create task'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)), style: FilledButton.styleFrom(backgroundColor: CustomColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))))),
          ]),
        ),
      ),
    );
  }

  Color _priorityColor(String value) => switch (value) {
    'Urgent' => const Color(0xFFFF2D55),
    'High' => CustomColors.TrashRed,
    'Low' => CustomColors.cyan,
    _ => CustomColors.yellow,
  };

  String _dateLabel(DateTime value) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(value.year, value.month, value.day);
    if (selected == today) return 'Today';
    if (selected == today.add(const Duration(days: 1))) return 'Tomorrow';
    return '${localizeNumber(value.day)}/${localizeNumber(value.month)}/${localizeNumber(value.year)}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (picked != null) setState(() => date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: time);
    if (picked != null) setState(() => time = picked);
  }

  Future<void> _pickRepeat() async {
    final result = await showModalBottomSheet<String>(context: context, showDragHandle: true, builder: (_) => ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(20, 0, 20, 30), children: ['Does not repeat', 'Daily', 'Weekly', 'Monthly', 'Weekdays', 'Weekends'].map((item) => ListTile(leading: Icon(item == 'Does not repeat' ? Icons.event_rounded : Icons.repeat_rounded), title: Text(tr(item)), trailing: repeat == item ? const Icon(Icons.check_circle_rounded, color: CustomColors.primary) : null, onTap: () => Navigator.pop(context, item))).toList()));
    if (result != null) setState(() => repeat = result);
  }

  void _addSubtask() { final value = subtaskController.text.trim(); if (value.isEmpty) return; setState(() { subtasks.add(SubtaskItem(title: value)); subtaskController.clear(); }); }

  void _submit() {
    final taskTitle = title.text.trim();
    if (taskTitle.isEmpty) return;
    final existing = widget.task;
    Navigator.pop(context, TodoItem(
      id: existing?.id,
      title: taskTitle,
      description: description.text.trim(),
      time: time.format(context),
      category: category,
      priority: priority,
      repeat: repeat,
      reminder: reminder,
      completed: existing?.completed ?? false,
      date: date,
      subtasks: subtasks,
    ));
  }
}

class _AddNoteSheet extends StatefulWidget {
  const _AddNoteSheet();
  @override
  State<_AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<_AddNoteSheet> {
  final controller = TextEditingController();
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(padding: EdgeInsets.only(bottom: bottom), child: Container(padding: const EdgeInsets.fromLTRB(22, 12, 22, 28), decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _Handle(), const SizedBox(height: 22),
      _SheetHeader(title: tr('Capture a note'), subtitle: tr('Ideas, reminders, or anything worth keeping.'), onClose: () => Navigator.pop(context)),
      const SizedBox(height: 18),
      TextField(controller: controller, autofocus: true, minLines: 4, maxLines: 7, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(hintText: tr('Write something…'), alignLabelWithHint: true)),
      const SizedBox(height: 18),
      SizedBox(width: double.infinity, height: 54, child: FilledButton.icon(onPressed: () { if (controller.text.trim().isNotEmpty) Navigator.pop(context, controller.text.trim()); }, icon: Icon(Icons.save_rounded), label: Text(tr('Save note'), style: TextStyle(fontWeight: FontWeight.w700)), style: FilledButton.styleFrom(backgroundColor: CustomColors.purple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))))),
    ])));
  }
}

class _Handle extends StatelessWidget { const _Handle(); @override Widget build(BuildContext context) => Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: const Color(0xFFD9DCE5), borderRadius: BorderRadius.circular(20)))); }

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title, required this.subtitle, required this.onClose});
  final String title; final String subtitle; final VoidCallback onClose;
  @override Widget build(BuildContext context) => Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(fontSize: 12, color: CustomColors.muted))])), IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded))]);
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: CustomColors.background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: CustomColors.primary, size: 19),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: CustomColors.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
