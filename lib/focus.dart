import 'dart:async';
import 'package:flutter/material.dart';
import 'models.dart';
import 'util.dart';

class FocusPage extends StatefulWidget {
  const FocusPage({super.key, required this.tasks});
  final List<TodoItem> tasks;
  @override State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  Timer? timer;
  int seconds = 25 * 60;
  bool running = false;
  TodoItem? selected;
  int sessions = 0;

  @override void dispose() { timer?.cancel(); super.dispose(); }
  void _start() { if (running) return; setState(() => running = true); timer = Timer.periodic(const Duration(seconds: 1), (_) { if (seconds <= 1) { timer?.cancel(); setState(() { seconds = 25 * 60; running = false; sessions++; }); return; } setState(() => seconds--); }); }
  void _pause() { timer?.cancel(); setState(() => running = false); }
  void _reset() { timer?.cancel(); setState(() { seconds = 25 * 60; running = false; }); }

  @override Widget build(BuildContext context) {
    final mins = localizeDigits((seconds ~/ 60).toString().padLeft(2, '0')); final secs = localizeDigits((seconds % 60).toString().padLeft(2, '0'));
    final available = widget.tasks.where((t) => !t.completed).toList();
    return Scaffold(appBar: AppBar(title: Text(tr('Focus Mode'), style: TextStyle(fontWeight: FontWeight.w900))), body: ListView(padding: EdgeInsets.fromLTRB(22, 8, 22, 40), children: [
      Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(gradient: const LinearGradient(colors: [CustomColors.primary, Color(0xFF8A63F6)]), borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Color(0x335B7CFA), blurRadius: 25, offset: Offset(0, 12))]), child: Column(children: [
        Text(tr('DEEP WORK'), style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.4)), SizedBox(height: 15),
        Text('$mins:$secs', style: const TextStyle(color: Colors.white, fontSize: 58, fontWeight: FontWeight.w900, letterSpacing: 2)), const SizedBox(height: 6),
        Text(selected?.title ?? tr('Choose a task below'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)), const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton.filled(onPressed: running ? _pause : _start, style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: CustomColors.primary, padding: const EdgeInsets.all(15)), icon: Icon(running ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 30)), const SizedBox(width: 10), IconButton(onPressed: _reset, style: IconButton.styleFrom(foregroundColor: Colors.white), icon: const Icon(Icons.refresh_rounded))]),
      ])),
      SizedBox(height: 18), Row(children: [Expanded(child: Text(tr('Focus task'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))), Text('${localizeNumber(sessions)} ${tr(sessions == 1 ? 'session' : 'sessions')}', style: TextStyle(color: CustomColors.muted, fontSize: 11, fontWeight: FontWeight.w700))]), SizedBox(height: 9),
      if (available.isEmpty) Card(child: Padding(padding: EdgeInsets.all(22), child: Text(tr('Add an unfinished task to start a focus session.'), textAlign: TextAlign.center))) else ...available.map((task) => Card(color: selected == task ? CustomColors.primary.withOpacity(.08) : null, child: ListTile(onTap: () => setState(() => selected = task), leading: Icon(selected == task ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded, color: CustomColors.primary), title: Text(task.title, style: TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${tr(task.category)} • ${tr(task.priority)}')))),
      SizedBox(height: 14), Text(tr('Tip'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)), SizedBox(height: 5), Text(tr('Pick one task, silence distractions, and work until the timer ends. Short breaks between sessions keep your focus sustainable.'), style: TextStyle(color: CustomColors.muted, fontSize: 12, height: 1.45)),
    ]));
  }
}
