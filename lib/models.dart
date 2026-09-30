import 'package:flutter/material.dart';

class TodoItem {
  TodoItem({
    String? id,
    required this.title,
    required this.time,
    required this.category,
    this.completed = false,
    this.reminder = false,
    DateTime? date,
    this.priority = 'Medium',
    this.description = '',
    this.repeat = 'Does not repeat',
    this.subtasks = const [],
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(), date = date ?? DateTime.now();

  final String id;
  final String title;
  final String time;
  final String category;
  DateTime date;
  String priority;
  final String description;
  final String repeat;
  final List<SubtaskItem> subtasks;
  bool completed;
  bool reminder;

  TodoItem copyWith({String? id, String? title, String? time, String? category, DateTime? date, String? priority, String? description, String? repeat, bool? completed, bool? reminder, List<SubtaskItem>? subtasks}) => TodoItem(
    id: id ?? this.id, title: title ?? this.title, time: time ?? this.time, category: category ?? this.category,
    date: date ?? this.date, priority: priority ?? this.priority, description: description ?? this.description,
    repeat: repeat ?? this.repeat, completed: completed ?? this.completed, reminder: reminder ?? this.reminder,
    subtasks: subtasks ?? this.subtasks,
  );


  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'time': time,
    'category': category,
    'priority': priority,
    'repeat': repeat,
    'completed': completed,
    'reminder': reminder,
    'date': date.toIso8601String(),
    'subtasks': subtasks.map((s) => s.toJson()).toList(),
  };

  factory TodoItem.fromJson(Map<String, dynamic> json) => TodoItem(
    id: json['id'] as String?,
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    time: json['time'] as String? ?? '',
    category: json['category'] as String? ?? 'Personal',
    priority: json['priority'] as String? ?? 'Medium',
    repeat: json['repeat'] as String? ?? 'Does not repeat',
    completed: json['completed'] as bool? ?? false,
    reminder: json['reminder'] as bool? ?? false,
    date: DateTime.tryParse(json['date'] as String? ?? ''),
    subtasks: (json['subtasks'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(SubtaskItem.fromJson)
        .toList(),
  );

  int get completedSubtasks => subtasks.where((s) => s.completed).length;
  double get subtaskProgress => subtasks.isEmpty ? (completed ? 1 : 0) : completedSubtasks / subtasks.length;

  Color get categoryColor => switch (category) {
    'Work' => const Color(0xFF27C77B), 'Meeting' => const Color(0xFFE83E9F), 'Study' => const Color(0xFF25B8D6),
    'Shopping' => const Color(0xFFFF8A3D), 'Personal' => const Color(0xFFFFB82E), _ => const Color(0xFF8A63F6),
  };
  Color get priorityColor => switch (priority) {
    'Urgent' => const Color(0xFFFF2D55),
    'High' => const Color(0xFFF45151),
    'Low' => const Color(0xFF25B8D6),
    _ => const Color(0xFFFFB82E),
  };

  int get priorityRank => switch (priority) { 'Urgent' => 0, 'High' => 1, 'Medium' => 2, 'Low' => 3, _ => 2 };
}

class SubtaskItem {
  SubtaskItem({required this.title, this.completed = false});
  final String title;
  bool completed;
  SubtaskItem copyWith({String? title, bool? completed}) => SubtaskItem(title: title ?? this.title, completed: completed ?? this.completed);
  Map<String, dynamic> toJson() => {'title': title, 'completed': completed};
  factory SubtaskItem.fromJson(Map<String, dynamic> json) => SubtaskItem(title: json['title'] as String? ?? '', completed: json['completed'] as bool? ?? false);
}

class NoteItem {
  NoteItem({
    String? id,
    required this.title,
    required this.content,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.pinned = false,
    this.colorIndex = 0,
    this.tags = const [],
    this.checklist = const [],
    this.richTextJson,
    this.attachments = const [],
    this.archived = false,
    this.deletedAt,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(), createdAt = createdAt ?? DateTime.now(), updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool pinned;
  final int colorIndex;
  final List<String> tags;
  final List<NoteChecklistItem> checklist;
  /// Quill Delta JSON. Kept separate from [content] so old Taskly notes remain compatible.
  final String? richTextJson;
  /// Local file paths/URIs attached to the note.
  final List<String> attachments;
  final bool archived;
  final DateTime? deletedAt;

  bool get isTrashed => deletedAt != null;

  NoteItem copyWith({
    String? id, String? title, String? content, DateTime? createdAt, DateTime? updatedAt, bool? pinned,
    int? colorIndex, List<String>? tags, List<NoteChecklistItem>? checklist, String? richTextJson,
    List<String>? attachments, bool? archived, DateTime? deletedAt, bool clearDeletedAt = false,
  }) => NoteItem(
    id: id ?? this.id, title: title ?? this.title, content: content ?? this.content, createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? DateTime.now(), pinned: pinned ?? this.pinned, colorIndex: colorIndex ?? this.colorIndex,
    tags: tags ?? this.tags, checklist: checklist ?? this.checklist, richTextJson: richTextJson ?? this.richTextJson,
    attachments: attachments ?? this.attachments, archived: archived ?? this.archived,
    deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'content': content, 'createdAt': createdAt.toIso8601String(), 'updatedAt': updatedAt.toIso8601String(),
    'pinned': pinned, 'colorIndex': colorIndex, 'tags': tags, 'checklist': checklist.map((e) => e.toJson()).toList(),
    if (richTextJson != null && richTextJson!.isNotEmpty) 'richTextJson': richTextJson,
    'attachments': attachments, 'archived': archived,
    if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
  };

  factory NoteItem.fromJson(Map<String, dynamic> json) => NoteItem(
    id: json['id'] as String?, title: json['title'] as String? ?? '', content: json['content'] as String? ?? '',
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''), updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    pinned: json['pinned'] as bool? ?? false, colorIndex: json['colorIndex'] as int? ?? 0,
    tags: (json['tags'] as List<dynamic>? ?? []).whereType<String>().toList(),
    checklist: (json['checklist'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().map(NoteChecklistItem.fromJson).toList(),
    richTextJson: json['richTextJson'] as String?,
    attachments: (json['attachments'] as List<dynamic>? ?? []).whereType<String>().toList(),
    archived: json['archived'] as bool? ?? false,
    deletedAt: DateTime.tryParse(json['deletedAt'] as String? ?? ''),
  );

  static const colors = <Color>[Color(0xFFF7F2FF), Color(0xFFFFF5D9), Color(0xFFEAF8F1), Color(0xFFEAF6FF), Color(0xFFFFEEF7), Color(0xFFF0F1F6)];
  static const darkColors = <Color>[Color(0xFF242033), Color(0xFF2D281B), Color(0xFF1B2B25), Color(0xFF1B2934), Color(0xFF30202B), Color(0xFF252832)];
  Color get backgroundColor => colors[colorIndex.clamp(0, colors.length - 1)];
  Color backgroundColorFor(Brightness brightness) => brightness == Brightness.dark
      ? darkColors[colorIndex.clamp(0, darkColors.length - 1)]
      : backgroundColor;
  int get completedChecklist => checklist.where((e) => e.completed).length;
}

class NoteChecklistItem {
  NoteChecklistItem({required this.title, this.completed = false});
  final String title;
  final bool completed;
  NoteChecklistItem copyWith({String? title, bool? completed}) => NoteChecklistItem(title: title ?? this.title, completed: completed ?? this.completed);
  Map<String, dynamic> toJson() => {'title': title, 'completed': completed};
  factory NoteChecklistItem.fromJson(Map<String, dynamic> json) => NoteChecklistItem(title: json['title'] as String? ?? '', completed: json['completed'] as bool? ?? false);
}
