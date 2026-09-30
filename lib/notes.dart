import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'models.dart';
import 'util.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key, required this.notes, required this.onAdd, required this.onEdit, required this.onDelete, required this.onArchive, required this.onRestore, required this.onPermanentDelete, required this.onTogglePin, required this.onToggleChecklist, required this.onConvertToTask});
  final List<NoteItem> notes;
  final VoidCallback onAdd;
  final ValueChanged<NoteItem> onEdit;
  final ValueChanged<NoteItem> onDelete;
  final ValueChanged<NoteItem> onArchive;
  final ValueChanged<NoteItem> onRestore;
  final ValueChanged<NoteItem> onPermanentDelete;
  final ValueChanged<NoteItem> onTogglePin;
  final void Function(NoteItem note, int index, bool value) onToggleChecklist;
  final ValueChanged<NoteItem> onConvertToTask;
  @override State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  String query = '';
  bool pinnedOnly = false;
  bool grid = true;
  String sortMode = 'Updated';
  String typeFilter = 'All';
  String viewMode = 'Active';
  String? selectedTag;

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final filtered = widget.notes.where((n) {
      final inView = switch (viewMode) {
        'Archived' => n.archived && !n.isTrashed,
        'Trash' => n.isTrashed,
        _ => !n.archived && !n.isTrashed,
      };
      final matches = inView && (q.isEmpty || n.title.toLowerCase().contains(q) || n.content.toLowerCase().contains(q) || n.tags.any((t) => t.toLowerCase().contains(q)));
      final matchesTag = selectedTag == null || n.tags.any((t) => t.toLowerCase() == selectedTag!.toLowerCase());
      return matches && matchesTag && (!pinnedOnly || n.pinned);
    }).toList();
    filtered.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      if (sortMode == 'Created') return b.createdAt.compareTo(a.createdAt);
      if (sortMode == 'Oldest') return a.updatedAt.compareTo(b.updatedAt);
      return b.updatedAt.compareTo(a.updatedAt);
    });
    final typed = typeFilter == 'Checklist'
        ? filtered.where((n) => n.checklist.isNotEmpty).toList()
        : filtered;
    final allTags = <String>{for (final n in widget.notes) ...n.tags}.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Notes'), style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(tooltip: tr('Layout'), onPressed: () => setState(() => grid = !grid), icon: Icon(grid ? Icons.view_agenda_rounded : Icons.grid_view_rounded)),
          IconButton(tooltip: tr('Pinned only'), onPressed: () => setState(() => pinnedOnly = !pinnedOnly), icon: Icon(pinnedOnly ? Icons.push_pin_rounded : Icons.push_pin_outlined, color: pinnedOnly ? CustomColors.purple : null)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: widget.onAdd, backgroundColor: CustomColors.purple, foregroundColor: Colors.white, icon: Icon(Icons.edit_rounded), label: Text(tr('New note'), style: TextStyle(fontWeight: FontWeight.w800))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: tr('Search notes, tags and ideas...')),
            ),
          ),
          SizedBox(
            height: 43,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              scrollDirection: Axis.horizontal,
              children: [
                _NoteFilterChip(label: tr('Active'), selected: viewMode == 'Active', onTap: () => setState(() { viewMode = 'Active'; pinnedOnly = false; })),
                const SizedBox(width: 7),
                _NoteFilterChip(label: tr('Archived'), icon: Icons.archive_rounded, selected: viewMode == 'Archived', onTap: () => setState(() { viewMode = 'Archived'; pinnedOnly = false; })),
                const SizedBox(width: 7),
                _NoteFilterChip(label: tr('Trash'), icon: Icons.delete_outline_rounded, selected: viewMode == 'Trash', onTap: () => setState(() { viewMode = 'Trash'; pinnedOnly = false; })),
                const SizedBox(width: 7),
                _NoteFilterChip(label: tr('All'), selected: typeFilter == 'All', onTap: () => setState(() => typeFilter = 'All')),
                const SizedBox(width: 7),
                _NoteFilterChip(label: tr('Checklist'), icon: Icons.checklist_rounded, selected: typeFilter == 'Checklist', onTap: () => setState(() => typeFilter = 'Checklist')),
                const SizedBox(width: 7),
                _NoteFilterChip(label: tr('Pinned'), icon: Icons.push_pin_rounded, selected: pinnedOnly, onTap: () => setState(() => pinnedOnly = !pinnedOnly)),
                const SizedBox(width: 7),
                _NoteFilterChip(label: sortMode == 'Oldest' ? tr('Oldest') : sortMode == 'Created' ? tr('Created') : tr('Recent'), icon: Icons.sort_rounded, selected: false, onTap: _cycleSort),
              ],
            ),
          ),
          if (allTags.isNotEmpty) SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              scrollDirection: Axis.horizontal,
              itemCount: allTags.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (_, i) {
                final tag = i == 0 ? null : allTags[i - 1];
                final selected = selectedTag == tag;
                return ChoiceChip(
                  label: Text(i == 0 ? tr('All tags') : '#$tag'),
                  selected: selected,
                  onSelected: (_) => setState(() => selectedTag = tag),
                  selectedColor: CustomColors.purple,
                  labelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface),
                  side: BorderSide.none,
                );
              },
            ),
          ),
          Expanded(child: typed.isEmpty ? _EmptyNotes(onAdd: widget.onAdd, filtered: q.isNotEmpty || pinnedOnly || typeFilter != 'All' || selectedTag != null) : (grid ? _grid(typed) : _list(typed))),
        ],
      ),
    );
  }

  void _cycleSort() {
    setState(() {
      sortMode = switch (sortMode) {
        'Updated' => 'Created',
        'Created' => 'Oldest',
        _ => 'Updated',
      };
    });
  }

  Widget _grid(List<NoteItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .88),
      itemCount: items.length,
      itemBuilder: (_, i) => _NoteCard(note: items[i], onEdit: () => widget.onEdit(items[i]), onDelete: () => widget.onDelete(items[i]), onArchive: () => widget.onArchive(items[i]), onRestore: () => widget.onRestore(items[i]), onPermanentDelete: () => widget.onPermanentDelete(items[i]), onPin: () => widget.onTogglePin(items[i]), onChecklist: (index, value) => widget.onToggleChecklist(items[i], index, value), onConvertToTask: () => widget.onConvertToTask(items[i])),
    );
  }

  Widget _list(List<NoteItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      itemCount: items.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _NoteCard(note: items[i], compact: true, onEdit: () => widget.onEdit(items[i]), onDelete: () => widget.onDelete(items[i]), onArchive: () => widget.onArchive(items[i]), onRestore: () => widget.onRestore(items[i]), onPermanentDelete: () => widget.onPermanentDelete(items[i]), onPin: () => widget.onTogglePin(items[i]), onChecklist: (index, value) => widget.onToggleChecklist(items[i], index, value), onConvertToTask: () => widget.onConvertToTask(items[i])),
      ),
    );
  }
}

class _NoteFilterChip extends StatelessWidget {
  const _NoteFilterChip({required this.label, required this.selected, required this.onTap, this.icon});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? CustomColors.purple : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? CustomColors.purple : CustomColors.divider),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, size: 14, color: selected ? Colors.white : CustomColors.muted), const SizedBox(width: 5)],
              Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface)),
            ]),
          ),
        ),
      );
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.onEdit, required this.onDelete, required this.onArchive, required this.onRestore, required this.onPermanentDelete, required this.onPin, required this.onChecklist, required this.onConvertToTask, this.compact = false});
  final NoteItem note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onArchive;
  final VoidCallback onRestore;
  final VoidCallback onPermanentDelete;
  final VoidCallback onPin;
  final void Function(int, bool) onChecklist;
  final VoidCallback onConvertToTask;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final noteTextColor = dark ? const Color(0xFFF4F6FF) : CustomColors.text;
    final visible = note.checklist.take(compact ? 4 : 3).toList();
    return Material(
      color: dark ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(.92) : note.backgroundColorFor(Brightness.light),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(note.title.isEmpty ? tr('Untitled note') : note.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: noteTextColor))),
                IconButton(visualDensity: VisualDensity.compact, onPressed: onPin, icon: Icon(note.pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined, size: 18, color: note.pinned ? CustomColors.purple : CustomColors.muted)),
                PopupMenuButton<String>(onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'pin') onPin();
                  if (v == 'archive') onArchive();
                  if (v == 'restore') onRestore();
                  if (v == 'delete') onDelete();
                  if (v == 'task') onConvertToTask();
                  if (v == 'permanent') onPermanentDelete();
                }, itemBuilder: (_) => [
                  if (note.isTrashed) ...[
                    PopupMenuItem(value: 'restore', child: Text(tr('Restore'))),
                    PopupMenuItem(value: 'permanent', child: Text(tr('Delete permanently'))),
                  ] else ...[
                    PopupMenuItem(value: 'edit', child: Text(tr('Edit'))),
                    PopupMenuItem(value: 'task', child: Text(tr('Create task'))),
                    PopupMenuItem(value: 'pin', child: Text(note.pinned ? tr('Unpin') : tr('Pin'))),
                    PopupMenuItem(value: 'archive', child: Text(note.archived ? tr('Unarchive') : tr('Archive'))),
                    PopupMenuItem(value: 'delete', child: Text(tr('Move to trash'))),
                  ]
                ]),
              ]),
              if (note.content.trim().isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(note.content, maxLines: compact ? 5 : 4, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, height: 1.45, color: noteTextColor)),
              ],
              if (visible.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...visible.asMap().entries.map((e) => InkWell(
                  onTap: () => onChecklist(e.key, !e.value.completed),
                  child: Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(children: [
                    Icon(e.value.completed ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, size: 17, color: e.value.completed ? CustomColors.green : CustomColors.muted),
                    const SizedBox(width: 6),
                    Expanded(child: Text(e.value.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, color: noteTextColor, decoration: e.value.completed ? TextDecoration.lineThrough : null))),
                  ])),
                )),
              ],
              if (!compact) const Spacer(),
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 9),
                Wrap(spacing: 4, runSpacing: 4, children: note.tags.take(3).map((t) => Chip(label: Text('#$t', style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700)), visualDensity: VisualDensity.compact, padding: EdgeInsets.zero)).toList()),
              ],
              const SizedBox(height: 8),
              Text(_relative(note.updatedAt), style: const TextStyle(fontSize: 9.5, color: CustomColors.muted, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  String _relative(DateTime date) {
    final d = DateTime.now().difference(date);
    if (d.inMinutes < 1) return tr('Just now');
    if (d.inHours < 1) return '${localizeNumber(d.inMinutes)}${tr('m ago')}';
    if (d.inDays < 1) return '${localizeNumber(d.inHours)}${tr('h ago')}';
    if (d.inDays < 7) return '${localizeNumber(d.inDays)}${tr('d ago')}';
    return '${localizeNumber(date.day)}/${localizeNumber(date.month)}/${localizeNumber(date.year)}';
  }
}

class NoteEditorSheet extends StatefulWidget {
  const NoteEditorSheet({super.key, this.note, this.scrollController});
  final NoteItem? note;
  final ScrollController? scrollController;
  @override State<NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<NoteEditorSheet> {
  late final TextEditingController title;
  late final TextEditingController tags;
  late final FocusNode titleFocus;
  late final ScrollController sheetScroll;
  final titleKey = GlobalKey();
  final editorKey = GlobalKey();
  final tagsKey = GlobalKey();
  late final QuillController editor;
  late final FocusNode editorFocus;
  late final ScrollController editorScroll;
  final checklistController = TextEditingController();
  final stt.SpeechToText speech = stt.SpeechToText();
  late List<NoteChecklistItem> checklist;
  late List<String> attachments;
  late bool pinned;
  late int colorIndex;
  bool speechReady = false;
  bool listening = false;
  int? _voiceStart;
  int _voiceLength = 0;

  @override
  void initState() {
    super.initState();
    final n = widget.note;
    title = TextEditingController(text: n?.title ?? '');
    tags = TextEditingController(text: n?.tags.join(', ') ?? '');
    checklist = List.of(n?.checklist ?? const []);
    attachments = List.of(n?.attachments ?? const []);
    pinned = n?.pinned ?? false;
    colorIndex = n?.colorIndex ?? 0;
    editorFocus = FocusNode();
    editorFocus.addListener(_handleEditorFocus);
    titleFocus = FocusNode();
    titleFocus.addListener(_handleTitleFocus);
    sheetScroll = widget.scrollController ?? ScrollController();
    editorScroll = ScrollController();
    editor = QuillController(
      document: _documentFor(n),
      selection: const TextSelection.collapsed(offset: 0),
      config: const QuillControllerConfig(),
    );
    _initSpeech();
  }

  Document _documentFor(NoteItem? n) {
    final raw = n?.richTextJson;
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        return Document.fromJson(jsonDecode(raw));
      } catch (_) {
        // Fall back to the legacy plain-text note format.
      }
    }
    final text = n?.content ?? '';
    return Document.fromJson([
      {'insert': text.isEmpty ? '\n' : '$text\n'},
    ]);
  }

  Future<void> _initSpeech() async {
    try {
      final ok = await speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          setState(() => listening = status == 'listening');
        },
        onError: (_) {
          if (!mounted) return;
          setState(() => listening = false);
        },
      );
      if (mounted) setState(() => speechReady = ok);
    } catch (_) {
      if (mounted) setState(() => speechReady = false);
    }
  }

  @override
  void dispose() {
    speech.cancel();
    title.dispose();
    tags.dispose();
    titleFocus.dispose();
    checklistController.dispose();
    editor.dispose();
    editorFocus.dispose();
    editorScroll.dispose();
    if (widget.scrollController == null) sheetScroll.dispose();
    super.dispose();
  }

  void _handleTitleFocus() {
    if (titleFocus.hasFocus) _scrollFieldIntoView(titleKey);
  }

  void _handleEditorFocus() {
    if (editorFocus.hasFocus) _scrollFieldIntoView(editorKey, extra: 18);
  }

  void _scrollFieldIntoView(GlobalKey key, {double extra = 12}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = key.currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(target, alignment: .08, duration: const Duration(milliseconds: 280), curve: Curves.easeOut, alignmentPolicy: ScrollPositionAlignmentPolicy.explicit);
      if (extra > 0 && sheetScroll.hasClients) {
        final max = sheetScroll.position.maxScrollExtent;
        final next = (sheetScroll.offset + extra).clamp(0.0, max);
        sheetScroll.animateTo(next, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        clipBehavior: Clip.antiAlias,
        child: CustomScrollView(
          controller: sheetScroll,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.only(top: 10), child: Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: CustomColors.divider, borderRadius: BorderRadius.circular(10)))))),
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(22, 14, 14, 8), child: Row(children: [
              Expanded(child: Text(widget.note == null ? tr('New note') : tr('Edit note'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
              IconButton(onPressed: () => setState(() => pinned = !pinned), icon: Icon(pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined, color: pinned ? CustomColors.purple : CustomColors.muted)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
            ]))),
            SliverToBoxAdapter(child: Padding(key: titleKey, padding: const EdgeInsets.symmetric(horizontal: 22), child: TextField(
              controller: title, focusNode: titleFocus, onTap: () => _scrollFieldIntoView(titleKey), textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: tr('Title'), hintText: tr('Give this idea a name')),
            ))),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(child: Padding(key: editorKey, padding: const EdgeInsets.symmetric(horizontal: 22), child: SizedBox(
              height: 270,
              child: Container(
                decoration: BoxDecoration(color: dark ? NoteItem.darkColors[colorIndex.clamp(0, NoteItem.darkColors.length - 1)] : NoteItem.colors[colorIndex], borderRadius: BorderRadius.circular(18), border: Border.all(color: CustomColors.purple.withOpacity(.65), width: 1.2)),
                clipBehavior: Clip.antiAlias,
                child: QuillEditor(controller: editor, focusNode: editorFocus, scrollController: editorScroll, config: QuillEditorConfig(
                  placeholder: tr('Write your thoughts, meeting notes, plans...'), padding: const EdgeInsets.fromLTRB(14, 14, 14, 14), embedBuilders: FlutterQuillEmbeds.editorBuilders(),
                )),
              ),
            ))),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(child: _buildEditorToolbar(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 9)),
            SliverToBoxAdapter(child: Padding(key: tagsKey, padding: const EdgeInsets.symmetric(horizontal: 22), child: TextField(
              controller: tags, onTap: () => _scrollFieldIntoView(tagsKey), decoration: InputDecoration(prefixIcon: const Icon(Icons.tag_rounded), labelText: tr('Tags'), hintText: tr('work, idea, personal')),
            ))),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),
            SliverToBoxAdapter(child: _buildColorPalette(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(child: _buildChecklist(context)),
            if (attachments.isNotEmpty) SliverToBoxAdapter(child: _buildAttachments(context)),
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(22, 8, 22, 24), child: SizedBox(width: double.infinity, height: 52, child: FilledButton.icon(
              onPressed: _save, icon: Icon(widget.note == null ? Icons.save_rounded : Icons.check_rounded),
              label: Text(widget.note == null ? tr('Save note') : tr('Save changes'), style: const TextStyle(fontWeight: FontWeight.w800)),
              style: FilledButton.styleFrom(backgroundColor: CustomColors.purple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))),
            )))),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorToolbar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      height: 52,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CustomColors.divider),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: QuillSimpleToolbar(
          controller: editor,
          config: QuillSimpleToolbarConfig(
            axis: Axis.horizontal,
            multiRowsDisplay: false,
            toolbarRunSpacing: 0,
            showDividers: false,
            showFontFamily: false,
            showFontSize: true,
            showBoldButton: true,
            showItalicButton: true,
            showUnderLineButton: true,
            showColorButton: true,
            showBackgroundColorButton: false,
            showStrikeThrough: false,
            showInlineCode: false,
            showClearFormat: false,
            showAlignmentButtons: true,
            showLeftAlignment: true,
            showCenterAlignment: true,
            showRightAlignment: true,
            showJustifyAlignment: true,
            showHeaderStyle: false,
            showListNumbers: true,
            showListBullets: true,
            showListCheck: false,
            showCodeBlock: false,
            showQuote: false,
            showIndent: false,
            showLink: false,
            showUndo: false,
            showRedo: false,
            showDirection: false,
            showSearchButton: false,
            showSubscript: false,
            showSuperscript: false,
            embedButtons: FlutterQuillEmbeds.toolbarButtons(
              videoButtonOptions: const QuillToolbarVideoButtonOptions(),
            ),
            customButtons: [
              QuillToolbarCustomButtonOptions(
                icon: const Icon(Icons.emoji_emotions_outlined),
                tooltip: tr('Emoji'),
                onPressed: _pickEmoji,
              ),
              QuillToolbarCustomButtonOptions(
                icon: Icon(listening ? Icons.stop_circle_outlined : Icons.mic_none_rounded),
                tooltip: tr('Voice to text'),
                onPressed: _voiceToText,
              ),
              QuillToolbarCustomButtonOptions(
                icon: const Icon(Icons.draw_outlined),
                tooltip: tr('Draw'),
                onPressed: _openDrawing,
              ),
              QuillToolbarCustomButtonOptions(
                icon: const Icon(Icons.attach_file_rounded),
                tooltip: tr('Attachment'),
                onPressed: _pickAttachments,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPalette(BuildContext context) {
    final selectedBackground = NoteItem.colors[colorIndex.clamp(0, NoteItem.colors.length - 1)];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(tr('Color'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: selectedBackground, shape: BoxShape.circle, border: Border.all(color: CustomColors.divider)),
              ),
            ],
          ),
          const SizedBox(height: 7),
          SizedBox(
            height: 46,
            child: Row(
              children: List.generate(NoteItem.colors.length, (i) {
                final selected = colorIndex == i;
                return Padding(
                  padding: const EdgeInsets.only(right: 9),
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkResponse(
                      radius: 24,
                      containedInkWell: true,
                      highlightShape: BoxShape.circle,
                      onTap: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        setState(() => colorIndex = i);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: NoteItem.colors[i],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? CustomColors.purple : CustomColors.divider,
                            width: selected ? 2.5 : 1,
                          ),
                          boxShadow: selected
                              ? [BoxShadow(color: CustomColors.purple.withOpacity(.22), blurRadius: 8, spreadRadius: 1)]
                              : null,
                        ),
                        child: selected ? const Icon(Icons.check_rounded, size: 18, color: CustomColors.purple) : null,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklist(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(tr('Checklist'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800))), Text('${localizeNumber(checklist.length)} ${tr('items')}', style: TextStyle(fontSize: 10, color: CustomColors.muted))]),
        if (checklist.isNotEmpty)
          ...checklist.asMap().entries.map((e) => ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            visualDensity: const VisualDensity(vertical: -3),
            leading: Checkbox(value: e.value.completed, onChanged: (v) => setState(() => checklist[e.key] = e.value.copyWith(completed: v ?? false))),
            title: Text(e.value.title, style: TextStyle(fontSize: 12, decoration: e.value.completed ? TextDecoration.lineThrough : null)),
            trailing: IconButton(onPressed: () => setState(() => checklist.removeAt(e.key)), icon: const Icon(Icons.close_rounded, size: 18)),
          )),
        Row(children: [
          Expanded(child: TextField(controller: checklistController, onSubmitted: (_) => _addChecklist(), decoration: InputDecoration(hintText: tr('Add checklist item')))),
          const SizedBox(width: 8),
          IconButton.filled(onPressed: _addChecklist, icon: const Icon(Icons.add_rounded)),
        ]),
      ]),
    );
  }

  Widget _buildAttachments(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(22, 5, 22, 0),
        scrollDirection: Axis.horizontal,
        itemCount: attachments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) => Chip(
          avatar: const Icon(Icons.attach_file_rounded, size: 15),
          label: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 150), child: Text(_fileName(attachments[i]), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10))),
          onDeleted: () => setState(() => attachments.removeAt(i)),
        ),
      ),
    );
  }

  String _fileName(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.split('/').last;
  }

  void _addChecklist() {
    final value = checklistController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      checklist.add(NoteChecklistItem(title: value));
      checklistController.clear();
    });
  }

  Future<void> _pickEmoji() async {
    final emojis = ['😀', '😂', '😍', '🥳', '🔥', '❤️', '👍', '👏', '🎯', '💡', '✅', '⭐', '🚀', '📌', '📝', '☕', '🎉', '😎', '🙏', '💪'];
    final emoji = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      showDragHandle: true,
      builder: (_) => SafeArea(child: GridView.count(crossAxisCount: 5, shrinkWrap: true, padding: const EdgeInsets.all(20), children: emojis.map((e) => InkWell(onTap: () => Navigator.pop(context, e), child: Center(child: Text(e, style: const TextStyle(fontSize: 30))))).toList())),
    );
    if (emoji == null) return;
    _insertText(emoji);
  }

  void _insertText(String text) {
    final selection = editor.selection;
    final index = selection.start < 0 ? editor.document.length - 1 : selection.start;
    editor.document.insert(index, text);
    editor.updateSelection(TextSelection.collapsed(offset: index + text.length), ChangeSource.local);
    editorFocus.requestFocus();
  }

  Future<void> _voiceToText() async {
    if (!speechReady) {
      await _initSpeech();
      if (!speechReady && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Voice input is not available on this device.'))));
        return;
      }
    }
    if (listening) {
      await speech.stop();
      if (mounted) setState(() => listening = false);
      return;
    }
    final selection = editor.selection;
    _voiceStart = selection.start < 0 ? editor.document.length - 1 : selection.start;
    _voiceLength = selection.end - selection.start;
    await speech.listen(
      partialResults: true,
      listenMode: stt.ListenMode.dictation,
      onResult: (result) {
        final words = result.recognizedWords.trim();
        if (words.isEmpty || _voiceStart == null) return;
        final start = _voiceStart!;
        if (_voiceLength > 0) {
          editor.replaceText(start, _voiceLength, words, null);
        } else {
          editor.replaceText(start, _voiceLength, words, null);
        }
        _voiceLength = words.length;
        editor.updateSelection(TextSelection.collapsed(offset: start + _voiceLength), ChangeSource.local);
      },
    );
    if (mounted) setState(() => listening = true);
  }

  Future<void> _pickAttachments() async {
    try {
      final files = await FilePicker.pickFiles(allowMultiple: true);
      if (files.isEmpty) return;
      final paths = files.map((f) => f.path).whereType<String>().where((p) => p.isNotEmpty).toList();
      if (paths.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('This file provider did not return a local path.'))));
        return;
      }
      setState(() {
        attachments.addAll(paths.where((p) => !attachments.contains(p)));
      });
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Could not attach the selected file.'))));
    }
  }

  Future<void> _openDrawing() async {
    final path = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DrawingDialog(),
    );
    if (path == null) return;
    final index = editor.selection.start < 0 ? editor.document.length - 1 : editor.selection.start;
    editor.document.insert(index, BlockEmbed.image(path));
    editor.updateSelection(TextSelection.collapsed(offset: index + 1), ChangeSource.local);
    if (mounted) setState(() {});
  }

  void _save() {
    final plain = editor.document.toPlainText().replaceAll('\uFFFC', '').trim();
    if (title.text.trim().isEmpty && plain.isEmpty && checklist.isEmpty) return;
    final now = DateTime.now();
    final deltaJson = jsonEncode(editor.document.toDelta().toJson());
    Navigator.pop(
      context,
      NoteItem(
        id: widget.note?.id,
        title: title.text.trim(),
        content: plain,
        createdAt: widget.note?.createdAt ?? now,
        updatedAt: now,
        pinned: pinned,
        colorIndex: colorIndex,
        tags: tags.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList(),
        checklist: checklist,
        richTextJson: deltaJson,
        attachments: attachments,
      ),
    );
  }
}

class _DrawingDialog extends StatefulWidget {
  const _DrawingDialog();
  @override State<_DrawingDialog> createState() => _DrawingDialogState();
}

class _DrawingDialogState extends State<_DrawingDialog> {
  final GlobalKey repaintKey = GlobalKey();
  final List<List<Offset>> strokes = [];
  List<Offset> current = [];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .68,
        child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(18, 14, 8, 8), child: Row(children: [
            Expanded(child: Text(tr('Draw'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
            IconButton(onPressed: () => setState(() => strokes.clear()), icon: const Icon(Icons.delete_outline_rounded)),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
          ])),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: RepaintBoundary(
                key: repaintKey,
                child: GestureDetector(
                  onPanStart: (d) => setState(() => current = [d.localPosition]),
                  onPanUpdate: (d) => setState(() => current = [...current, d.localPosition]),
                  onPanEnd: (_) => setState(() { if (current.isNotEmpty) strokes.add(List.of(current)); current = []; }),
                  child: CustomPaint(
                    painter: _DrawingPainter(strokes: strokes, current: current, dark: Theme.of(context).brightness == Brightness.dark),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
          Padding(padding: EdgeInsets.fromLTRB(12, 8, 12, 14), child: SizedBox(width: double.infinity, height: 48, child: FilledButton.icon(onPressed: _save, icon: Icon(Icons.check_rounded), label: Text(tr('Insert drawing'))))),
        ]),
      ),
    );
  }

  Future<void> _save() async {
    if (strokes.isEmpty && current.isEmpty) return;
    try {
      final boundary = repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.2);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/taskly_drawing_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
      if (mounted) Navigator.pop(context, file.path);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Could not save drawing.'))));
    }
  }
}

class _DrawingPainter extends CustomPainter {
  const _DrawingPainter({required this.strokes, required this.current, required this.dark});
  final List<List<Offset>> strokes;
  final List<Offset> current;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = dark ? const Color(0xFF11141C) : Colors.white);
    final pen = Paint()
      ..color = dark ? Colors.white : const Color(0xFF15192A)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    void draw(List<Offset> points) {
      if (points.isEmpty) return;
      if (points.length == 1) { canvas.drawCircle(points.first, 1.7, pen); return; }
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) path.lineTo(points[i].dx, points[i].dy);
      canvas.drawPath(path, pen);
    }
    for (final stroke in strokes) draw(stroke);
    draw(current);
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}

class _EmptyNotes extends StatelessWidget {
  const _EmptyNotes({required this.onAdd, required this.filtered});
  final VoidCallback onAdd;
  final bool filtered;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(filtered ? Icons.search_off_rounded : Icons.auto_awesome_rounded, size: 58, color: CustomColors.purple.withOpacity(.55)), SizedBox(height: 14), Text(filtered ? tr('No notes found') : tr('Your ideas deserve a home'), textAlign: TextAlign.center, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)), SizedBox(height: 7), Text(filtered ? tr('Try another keyword or turn off the pinned filter.') : tr('Capture ideas, plans, meeting notes and checklists in one place.'), textAlign: TextAlign.center, style: TextStyle(color: CustomColors.muted, fontSize: 12, height: 1.4)), if (!filtered) ...[SizedBox(height: 18), FilledButton.icon(onPressed: onAdd, icon: Icon(Icons.edit_rounded), label: Text(tr('Write your first note')))]])));
}
