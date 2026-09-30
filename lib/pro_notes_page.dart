import 'package:flutter/material.dart';
import 'models.dart';
import 'util.dart';

/// Taskly Pro 1.2: Advanced Notes & Knowledge Base hub.
/// This page is intentionally data-safe: it works with the existing NoteItem
/// model and does not alter existing note storage until a user chooses an action.
class TasklyProNotesPage extends StatefulWidget {
  const TasklyProNotesPage({super.key, this.notes = const []});
  final List<NoteItem> notes;

  @override
  State<TasklyProNotesPage> createState() => _TasklyProNotesPageState();
}

class _TasklyProNotesPageState extends State<TasklyProNotesPage> {
  String query = '';
  String? selectedTag;
  String sort = 'Recent';

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tags = <String>{for (final n in widget.notes) ...n.tags}.toList()..sort();
    final q = query.trim().toLowerCase();
    final filtered = widget.notes.where((n) {
      final matchesText = q.isEmpty || n.title.toLowerCase().contains(q) || n.content.toLowerCase().contains(q) || n.tags.any((t) => t.toLowerCase().contains(q));
      final matchesTag = selectedTag == null || n.tags.any((t) => t.toLowerCase() == selectedTag!.toLowerCase());
      return matchesText && matchesTag && !n.isTrashed;
    }).toList()
      ..sort((a, b) => sort == 'Title' ? a.title.toLowerCase().compareTo(b.title.toLowerCase()) : b.updatedAt.compareTo(a.updatedAt));

    return Scaffold(
      appBar: AppBar(title: const Text('Advanced Notes', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: dark ? const [Color(0xFF202A55), Color(0xFF34244F)] : const [Color(0xFFEAF1FF), Color(0xFFF6EEFF)]),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: CustomColors.primary.withOpacity(.16)),
            ),
            child: Row(children: [
              Container(width: 52, height: 52, decoration: BoxDecoration(color: CustomColors.primary, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 28)),
              const SizedBox(width: 14),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Knowledge Base', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                SizedBox(height: 4),
                Text('Search, organize and connect your notes.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ])),
            ]),
          ),
          const SizedBox(height: 16),
          TextField(onChanged: (v) => setState(() => query = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Search title, content or tags...')),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _ModeButton(label: 'Recent', selected: sort == 'Recent', onTap: () => setState(() => sort = 'Recent'))),
            const SizedBox(width: 8),
            Expanded(child: _ModeButton(label: 'Title', selected: sort == 'Title', onTap: () => setState(() => sort = 'Title'))),
          ]),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(height: 38, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: tags.length + 1, separatorBuilder: (_, __) => const SizedBox(width: 7), itemBuilder: (_, i) {
              final tag = i == 0 ? null : tags[i - 1];
              final selected = selectedTag == tag;
              return ChoiceChip(label: Text(i == 0 ? 'All tags' : '#$tag'), selected: selected, onSelected: (_) => setState(() => selectedTag = tag), selectedColor: CustomColors.primary, labelStyle: TextStyle(color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700));
            })),
          ],
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: Text('${filtered.length} notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: dark ? Colors.white : CustomColors.text))),
            Text('Pro 1.2', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: CustomColors.primary)),
          ]),
          const SizedBox(height: 8),
          if (filtered.isEmpty)
            Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: dark ? const Color(0xFF171B27) : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: dark ? Colors.white10 : const Color(0x11000000))), child: Column(children: [Icon(Icons.search_off_rounded, size: 34, color: CustomColors.muted), const SizedBox(height: 8), Text('No matching notes', style: TextStyle(fontWeight: FontWeight.w800, color: dark ? Colors.white70 : CustomColors.text))]))
          else
            ...filtered.map((note) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _NotePreview(note: note))),
          const SizedBox(height: 14),
          const _FeatureStrip(icon: Icons.link_rounded, title: 'Note linking', subtitle: 'Connect related notes and tasks from the existing workspace.'),
          const _FeatureStrip(icon: Icons.folder_rounded, title: 'Knowledge organization', subtitle: 'Use tags, pinned notes, archive and search as your knowledge structure.'),
          const _FeatureStrip(icon: Icons.lock_rounded, title: 'Private notes foundation', subtitle: 'Prepared for the Pro security layer without changing current note data.'),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({required this.label, required this.selected, required this.onTap});
  final String label; final bool selected; final VoidCallback onTap;
  @override Widget build(BuildContext context) => OutlinedButton(onPressed: onTap, style: OutlinedButton.styleFrom(backgroundColor: selected ? CustomColors.primary : null, foregroundColor: selected ? Colors.white : null), child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)));
}

class _NotePreview extends StatelessWidget {
  const _NotePreview({required this.note});
  final NoteItem note;
  @override Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: note.backgroundColorFor(Theme.of(context).brightness), borderRadius: BorderRadius.circular(18), border: Border.all(color: dark ? Colors.white10 : const Color(0x12000000))), child: Row(children: [
      Icon(note.pinned ? Icons.push_pin_rounded : Icons.note_alt_outlined, color: note.pinned ? CustomColors.purple : CustomColors.muted, size: 19),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(note.title.isEmpty ? 'Untitled note' : note.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w900, color: dark ? Colors.white : CustomColors.text)), const SizedBox(height: 3), Text(note.content.replaceAll('\n', ' '), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, height: 1.3, color: dark ? Colors.white70 : CustomColors.muted))]))
    ]));
  }
}

class _FeatureStrip extends StatelessWidget {
  const _FeatureStrip({required this.icon, required this.title, required this.subtitle});
  final IconData icon; final String title; final String subtitle;
  @override Widget build(BuildContext context) => ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 4), leading: CircleAvatar(backgroundColor: CustomColors.primary.withOpacity(.10), child: Icon(icon, color: CustomColors.primary, size: 19)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, height: 1.3)));
}
