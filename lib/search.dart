import 'package:flutter/material.dart';
import 'models.dart';
import 'util.dart';

class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({super.key, required this.tasks, required this.notes, required this.onTaskTap, required this.onNoteTap});
  final List<TodoItem> tasks;
  final List<NoteItem> notes;
  final ValueChanged<TodoItem> onTaskTap;
  final ValueChanged<NoteItem> onNoteTap;

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final tasks = q.isEmpty ? <TodoItem>[] : widget.tasks.where((t) => t.title.toLowerCase().contains(q) || t.description.toLowerCase().contains(q) || t.category.toLowerCase().contains(q)).toList();
    final notes = q.isEmpty ? <NoteItem>[] : widget.notes.where((n) => n.title.toLowerCase().contains(q) || n.content.toLowerCase().contains(q) || n.tags.any((t) => t.toLowerCase().contains(q))).toList();

    return Scaffold(
      appBar: AppBar(title: Text(tr('Search'), style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          TextField(
            autofocus: true,
            onChanged: (value) => setState(() => query = value),
            decoration: InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: tr('Search tasks and notes...')),
          ),
          const SizedBox(height: 22),
          if (q.isEmpty) const _SearchHint(),
          if (q.isNotEmpty && tasks.isEmpty && notes.isEmpty) const _NoResults(),
          if (tasks.isNotEmpty) ...[
            _ResultHeading(title: tr('Tasks')),
            ...tasks.map((task) => _TaskResult(task: task, onTap: () => widget.onTaskTap(task))),
          ],
          if (notes.isNotEmpty) ...[
            _ResultHeading(title: tr('Notes')),
            ...notes.map((note) => _NoteResult(note: note, onTap: () => widget.onNoteTap(note))),
          ],
        ],
      ),
    );
  }
}

class _ResultHeading extends StatelessWidget {
  const _ResultHeading({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 9), child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)));
}

class _TaskResult extends StatelessWidget {
  const _TaskResult({required this.task, required this.onTap});
  final TodoItem task;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 9),
    elevation: 0,
    color: Theme.of(context).cardColor,
    child: ListTile(onTap: onTap, leading: Icon(task.completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: task.completed ? CustomColors.green : task.priorityColor), title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${tr(task.category)} • ${localizeDigits(task.time)}', maxLines: 1, overflow: TextOverflow.ellipsis), trailing: const Icon(Icons.chevron_right_rounded)),
  );
}

class _NoteResult extends StatelessWidget {
  const _NoteResult({required this.note, required this.onTap});
  final NoteItem note;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 9), elevation: 0, child: ListTile(onTap: onTap, leading: Icon(note.pinned ? Icons.push_pin_rounded : Icons.sticky_note_2_rounded, color: CustomColors.purple), title: Text(note.title.isNotEmpty ? note.title : note.content, maxLines: 2, overflow: TextOverflow.ellipsis), subtitle: note.title.isNotEmpty ? Text(note.content, maxLines: 2, overflow: TextOverflow.ellipsis) : null));
}

class _SearchHint extends StatelessWidget {
  const _SearchHint();
  @override
  Widget build(BuildContext context) => Column(children: [SizedBox(height: 70), Icon(Icons.manage_search_rounded, size: 62, color: CustomColors.primary), SizedBox(height: 14), Text(tr('Search your workspace'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), SizedBox(height: 6), Text(tr('Find tasks, descriptions, categories and notes from one place.'), textAlign: TextAlign.center, style: TextStyle(color: CustomColors.muted, fontSize: 12))]);
}

class _NoResults extends StatelessWidget {
  const _NoResults();
  @override
  Widget build(BuildContext context) => Column(children: [SizedBox(height: 70), Icon(Icons.search_off_rounded, size: 54, color: CustomColors.muted), SizedBox(height: 12), Text(tr('Nothing found'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), SizedBox(height: 5), Text(tr('Try a different keyword.'), style: TextStyle(color: CustomColors.muted, fontSize: 12))]);
}
