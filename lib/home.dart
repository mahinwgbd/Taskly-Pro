import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'models.dart';
import 'profile.dart';
import 'util.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.tasks,
    required this.notes,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    required this.onAdd,
    required this.onAddNote,
    required this.onSeeAllNotes,
    required this.profile,
    required this.locale,
    required this.onLanguageChanged,
    required this.onSeeAllTasks,
    required this.onProjectTap,
    required this.onCalendar,
    required this.onInsights,
  });

  final List<TodoItem> tasks;
  final List<NoteItem> notes;
  final ValueChanged<TodoItem> onToggle;
  final ValueChanged<TodoItem> onDelete;
  final ValueChanged<TodoItem> onEdit;
  final VoidCallback onAdd;
  final VoidCallback onAddNote;
  final VoidCallback onSeeAllNotes;
  final ProfileController profile;
  final Locale locale;
  final ValueChanged<Locale> onLanguageChanged;
  final VoidCallback onSeeAllTasks;
  final ValueChanged<String> onProjectTap;
  final VoidCallback onCalendar;
  final VoidCallback onInsights;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat(reverse: true);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void dispose() {
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    // Keep today's task positions stable when a checkbox is toggled.
    // Previously completed tasks were immediately moved below pending tasks,
    // making it look as if a different checkbox had been tapped.
    final todayTasks = widget.tasks.where((t) => _sameDay(t.date, today)).toList();
    final completed = todayTasks.where((t) => t.completed).length;
    final pending = todayTasks.length - completed;
    final progress = todayTasks.isEmpty ? 0.0 : completed / todayTasks.length;

    int countFor(String category) =>
        widget.tasks.where((task) => task.category == category).length;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _ambient,
              builder: (_, __) => _HeroHeader(
                profile: widget.profile,
                progress: progress,
                pending: pending,
                completed: completed,
                notesCount: widget.notes.length,
                locale: widget.locale,
                onLanguageChanged: widget.onLanguageChanged,
                motion: _ambient.value,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _SectionTitle(
              title: tr('Your day'),
              subtitle: pending == 0 && todayTasks.isNotEmpty
                  ? tr('Everything is under control.')
                  : pending == 0
                      ? tr('A clean slate. Make it yours.')
                      : '${localizeNumber(pending)} ${tr(pending == 1 ? 'task' : 'tasks')} ${tr('waiting for you.')}',
              action: todayTasks.isEmpty ? null : tr('See all'),
              onTap: widget.onSeeAllTasks,
            ),
          ),
          if (todayTasks.isEmpty)
            SliverToBoxAdapter(child: _EmptyToday(onAdd: widget.onAdd))
          else
            SliverList.builder(
              itemCount: math.min(todayTasks.length, 4),
              itemBuilder: (_, i) => TaskCard(
                task: todayTasks[i],
                onToggle: widget.onToggle,
                onDelete: widget.onDelete,
                onEdit: widget.onEdit,
              ),
            ),
          SliverToBoxAdapter(
            child: _SectionTitle(
              title: tr('Quick notes'),
              subtitle: widget.notes.isEmpty
                  ? tr('Save an idea before it disappears.')
                  : '${localizeNumber(widget.notes.length)} ${tr(widget.notes.length == 1 ? 'note' : 'notes')} ${tr('in your space.')}',
              action: tr('See all'),
              onTap: widget.onSeeAllNotes,
            ),
          ),
          SliverToBoxAdapter(
            child: widget.notes.isEmpty
                ? _EmptyNotes(onAdd: widget.onAddNote)
                : _NotesPreview(notes: widget.notes, onAdd: widget.onAddNote),
          ),
          SliverToBoxAdapter(
            child: _SectionTitle(
              title: tr('Focus spaces'),
              subtitle: tr('Jump into a category and keep moving.'),
              action: null,
              onTap: widget.onSeeAllTasks,
            ),
          ),
          SliverToBoxAdapter(
            child: _MoreTools(
              onCalendar: widget.onCalendar,
              onInsights: widget.onInsights,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 125),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.28,
              children: [
                ProjectCard(tr('Personal'), Icons.person_rounded, CustomColors.yellow,
                    countFor('Personal'), () => widget.onProjectTap('Personal')),
                ProjectCard(tr('Work'), Icons.work_rounded, CustomColors.green,
                    countFor('Work'), () => widget.onProjectTap('Work')),
                ProjectCard(tr('Meeting'), Icons.groups_rounded, CustomColors.pink,
                    countFor('Meeting'), () => widget.onProjectTap('Meeting')),
                ProjectCard(tr('Shopping'), Icons.shopping_basket_rounded,
                    CustomColors.orange, countFor('Shopping'),
                    () => widget.onProjectTap('Shopping')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreTools extends StatelessWidget {
  const _MoreTools({required this.onCalendar, required this.onInsights});

  final VoidCallback onCalendar;
  final VoidCallback onInsights;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: _ToolCard(
              icon: Icons.calendar_month_rounded,
              title: tr('Calendar'),
              subtitle: tr('Plan your days'),
              color: CustomColors.primary,
              onTap: onCalendar,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ToolCard(
              icon: Icons.insights_rounded,
              title: tr('Insights'),
              subtitle: tr('See your progress'),
              color: CustomColors.purple,
              onTap: onInsights,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(.72), width: 1.0)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8.5, color: CustomColors.muted, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 11, color: color),
              ],
            ),
          ),
        ),
      );
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({required this.locale, required this.onChanged});

  final Locale locale;
  final ValueChanged<Locale> onChanged;

  @override
  Widget build(BuildContext context) {
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(.68), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _languageButton('বাংলা', isBn, () => onChanged(const Locale('bn'))),
          _languageButton('English', !isBn, () => onChanged(const Locale('en'))),
        ],
      ),
    );
  }

  Widget _languageButton(String label, bool selected, VoidCallback onTap) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: Text(label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: selected ? CustomColors.primary : Colors.white)),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.profile,
    required this.progress,
    required this.pending,
    required this.completed,
    required this.notesCount,
    required this.locale,
    required this.onLanguageChanged,
    required this.motion,
  });

  final ProfileController profile;
  final double progress;
  final int pending;
  final int completed;
  final int notesCount;
  final Locale locale;
  final ValueChanged<Locale> onLanguageChanged;
  final double motion;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    final name = profile.name.trim().isEmpty ? tr('there') : profile.name.trim();
    final details = [profile.designation, profile.profession, profile.company]
        .where((e) => e.trim().isNotEmpty)
        .take(2)
        .toList();
    if (details.isEmpty && profile.name.trim() == ProfileController.defaultName) {
      details.add(tr('Guest'));
    }
    final isDone = percent == 100 && completed > 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF365FEA), Color(0xFF6D8FFF), Color(0xFF76C9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0, .55, 1],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Color(0x335B7CFA), blurRadius: 28, offset: Offset(0, 14)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -38 + motion * 12,
            top: -48,
            child: _GlowOrb(size: 135, opacity: .13),
          ),
          Positioned(
            left: -54 - motion * 10,
            bottom: -80,
            child: _GlowOrb(size: 170, opacity: .09),
          ),
          Column(
            children: [
              Row(
                children: [
                  ProfileAvatar(profile: profile, radius: 25),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(),
                          style: const TextStyle(
                            color: Color(0xD9FFFFFF),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          name == tr('there') ? tr('Welcome to Taskly') : name,
                          maxLines: 2,
                          softWrap: true,
                          overflow: TextOverflow.clip,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16.2,
                            height: 1.08,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.3,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          details.isEmpty ? tr('Ready when you are.') : details.join('  •  '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xD9FFFFFF), fontSize: 9.5, height: 1.15),
                        ),
                      ],
                    ),
                  ),
                  _LanguageSelector(
                    locale: locale,
                    onChanged: onLanguageChanged,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _dateLabel(DateTime.now()),
                          style: const TextStyle(
                            color: Color(0xCFFFFFFF),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isDone
                              ? tr('You did it!')
                              : pending == 0
                                  ? tr('Start something great.')
                                  : '${localizeNumber(pending)} ${tr(pending == 1 ? 'step' : 'steps')} ${tr('to go')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                            letterSpacing: -.7,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          _motivation(percent, hasTasks: completed + pending > 0),
                          maxLines: 2,
                          style: const TextStyle(
                            color: Color(0xE8FFFFFF),
                            fontSize: 10.5,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _ProgressRing(progress: progress, percent: percent, isDone: isDone),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatChip(icon: Icons.check_rounded, value: localizeNumber(completed), label: tr('done')),
                  const SizedBox(width: 7),
                  _StatChip(icon: Icons.timelapse_rounded, value: localizeNumber(pending), label: tr('left')),
                  const SizedBox(width: 7),
                  _StatChip(icon: Icons.sticky_note_2_rounded, value: localizeNumber(notesCount), label: tr('notes')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.opacity});
  final double size;
  final double opacity;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
        ),
      );
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.13),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(.09)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: Colors.white70),
              const SizedBox(width: 4),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
              const SizedBox(width: 3),
              Text(tr(label), style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress, required this.percent, required this.isDone});
  final double progress;
  final int percent;
  final bool isDone;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress),
        duration: const Duration(milliseconds: 850),
        curve: Curves.easeOutCubic,
        builder: (_, value, __) => SizedBox(
          width: 88,
          height: 88,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(size: const Size.square(88), painter: _RingPainter(value)),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${localizeNumber(percent)}%', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  Text(isDone ? tr('DONE') : tr('TODAY'), style: const TextStyle(color: Colors.white70, fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: .8)),
                ],
              ),
              if (isDone) const Positioned(right: 1, top: 0, child: Icon(Icons.auto_awesome_rounded, color: Colors.amberAccent, size: 17)),
            ],
          ),
        ),
      );
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 6;
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(.18);
    canvas.drawCircle(center, radius, bg);
    if (progress <= 0) return;
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [Colors.white, Color(0xFFE5F3FF), Colors.white],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0, 1),
      false,
      fg,
    );
  }
  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle, required this.action, required this.onTap});
  final String title;
  final String subtitle;
  final String? action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 16, 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: -.3)),
                  const SizedBox(height: 3),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: CustomColors.muted, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (action != null)
              TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4)),
                child: Text(action!, style: const TextStyle(color: CustomColors.primary, fontSize: 11, fontWeight: FontWeight.w900)),
              ),
          ],
        ),
      );
}

String _taskDateLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(date.year, date.month, date.day);
  if (d == today) return tr('Today');
  if (d == today.add(const Duration(days: 1))) return tr('Tomorrow');
  if (d.isBefore(today)) return tr('Overdue');
  return '${localizeNumber(date.day)}/${localizeNumber(date.month)}';
}

Color _taskDateColor(TodoItem task) {
  if (task.completed) return CustomColors.muted;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(task.date.year, task.date.month, task.date.day);
  if (d.isBefore(today)) return CustomColors.TrashRed;
  if (d == today) return CustomColors.primary;
  return CustomColors.muted;
}

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, required this.onToggle, required this.onDelete, required this.onEdit});
  final TodoItem task;
  final ValueChanged<TodoItem> onToggle;
  final ValueChanged<TodoItem> onDelete;
  final ValueChanged<TodoItem> onEdit;

  @override
  Widget build(BuildContext context) => Dismissible(
        key: ObjectKey(task),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(task),
        background: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          decoration: BoxDecoration(color: CustomColors.TrashRed, borderRadius: BorderRadius.circular(20)),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
        ),
        child: InkWell(
          onTap: () => onEdit(task),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            padding: const EdgeInsets.fromLTRB(13, 12, 10, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.72), width: 1.15),
              boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 18, offset: Offset(0, 6))],
            ),
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label: task.completed ? tr('Mark task incomplete') : tr('Mark task complete'),
                  child: InkWell(
                    onTap: () => onToggle(task),
                    borderRadius: BorderRadius.circular(22),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 31,
                    height: 31,
                    decoration: BoxDecoration(
                      color: task.completed ? CustomColors.green : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: task.completed ? CustomColors.green : const Color(0xFFD3D7E3), width: 2),
                    ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                          child: task.completed ? const Icon(Icons.check_rounded, key: ValueKey('checked'), size: 19, color: Colors.white) : const SizedBox(key: ValueKey('empty')),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: task.completed ? CustomColors.muted : Theme.of(context).colorScheme.onSurface, decoration: task.completed ? TextDecoration.lineThrough : null)),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 12, color: CustomColors.muted),
                          const SizedBox(width: 3),
                          Text(localizeDigits(task.time), style: const TextStyle(fontSize: 9.5, color: CustomColors.muted, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 7),
                          Text(_taskDateLabel(task.date), style: TextStyle(fontSize: 9.5, color: _taskDateColor(task), fontWeight: FontWeight.w800)),
                          if (task.repeat != 'Does not repeat') ...[
                            const SizedBox(width: 6),
                            Icon(Icons.repeat_rounded, size: 11, color: CustomColors.purple),
                          ],
                          const SizedBox(width: 7),
                          Container(width: 5, height: 5, decoration: BoxDecoration(color: task.categoryColor, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Flexible(child: Text(tr(task.category), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9.5, color: task.categoryColor, fontWeight: FontWeight.w800))),
                          const SizedBox(width: 6),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: task.priorityColor.withOpacity(.11), borderRadius: BorderRadius.circular(8)), child: Text(tr(task.priority), style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w900, color: task.priorityColor))),
                        ],
                      ),
                      if (task.subtasks.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(children: [const Icon(Icons.checklist_rounded, size: 12, color: CustomColors.muted), const SizedBox(width: 3), Text('${localizeNumber(task.completedSubtasks)}/${localizeNumber(task.subtasks.length)}', style: const TextStyle(fontSize: 8.5, color: CustomColors.muted, fontWeight: FontWeight.w800)), const SizedBox(width: 7), Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: task.subtaskProgress, minHeight: 4, backgroundColor: CustomColors.primary.withOpacity(.08), valueColor: const AlwaysStoppedAnimation(CustomColors.primary))))]),
                      ],
                    ],
                  ),
                ),
                Icon(task.reminder ? Icons.notifications_active_rounded : Icons.more_horiz_rounded, size: 19, color: task.reminder ? CustomColors.yellow : CustomColors.muted),
              ],
            ),
          ),
        ),
      );
}

class _EmptyToday extends StatelessWidget {
  const _EmptyToday({required this.onAdd});
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: CustomColors.primary.withOpacity(.10)),
        ),
        child: Row(
          children: [
            Container(width: 54, height: 54, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFEDF2FF), Color(0xFFEFFAFF)]), borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.wb_sunny_rounded, color: CustomColors.primary, size: 27)),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tr('Your day is wide open'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)), SizedBox(height: 4), Text(tr('Add one small task and give today a direction.'), style: TextStyle(fontSize: 10.5, height: 1.35, color: CustomColors.muted))])),
            const SizedBox(width: 8),
            IconButton.filled(onPressed: onAdd, style: IconButton.styleFrom(backgroundColor: CustomColors.primary, foregroundColor: Colors.white), icon: const Icon(Icons.add_rounded)),
          ],
        ),
      );
}

class _NotesPreview extends StatelessWidget {
  const _NotesPreview({required this.notes, required this.onAdd});
  final List<NoteItem> notes;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) {
    final visible = notes.take(4).toList();
    return SizedBox(
      height: 112,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 5),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: visible.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => i == visible.length ? _AddNoteCard(onTap: onAdd) : _NotePreviewCard(note: visible[i]),
      ),
    );
  }
}

class _NotePreviewCard extends StatelessWidget {
  const _NotePreviewCard({required this.note});
  final NoteItem note;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final noteTextColor = dark ? const Color(0xFFF4F6FF) : CustomColors.text;
    final checklistText = note.checklist.isEmpty ? null : '${localizeNumber(note.completedChecklist)}/${localizeNumber(note.checklist.length)} ${tr('checked')}';
    return Container(
      width: 226,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(.92) : note.backgroundColorFor(Brightness.light),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.72), width: 1.05),
        boxShadow: const [BoxShadow(color: Color(0x0B000000), blurRadius: 14, offset: Offset(0, 5))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 30, height: 30, decoration: BoxDecoration(color: CustomColors.purple.withOpacity(.10), borderRadius: BorderRadius.circular(10)), child: Icon(note.pinned ? Icons.push_pin_rounded : Icons.sticky_note_2_rounded, size: 16, color: CustomColors.purple)),
          const Spacer(),
          if (note.pinned) const Icon(Icons.push_pin_rounded, size: 14, color: CustomColors.purple),
        ]),
        const SizedBox(height: 8),
        Text(note.title.isNotEmpty ? note.title : note.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, height: 1.25, fontWeight: FontWeight.w900, color: noteTextColor)),
        const Spacer(),
        Row(children: [
          if (checklistText != null) ...[const Icon(Icons.checklist_rounded, size: 12, color: CustomColors.muted), const SizedBox(width: 3), Text(checklistText, style: const TextStyle(fontSize: 8.5, color: CustomColors.muted, fontWeight: FontWeight.w700)), const SizedBox(width: 7)],
          if (note.tags.isNotEmpty) Expanded(child: Text('#${note.tags.first}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8.5, color: CustomColors.purple, fontWeight: FontWeight.w800))),
        ]),
      ]),
    );
  }
}

class _AddNoteCard extends StatelessWidget {
  const _AddNoteCard({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          width: 126,
          decoration: BoxDecoration(color: CustomColors.purple.withOpacity(.07), borderRadius: BorderRadius.circular(21), border: Border.all(color: CustomColors.purple.withOpacity(.16))),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.edit_rounded, color: CustomColors.purple, size: 25), SizedBox(height: 6), Text(tr('New note'), style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: CustomColors.purple)), SizedBox(height: 2), Text(tr('capture an idea'), style: TextStyle(fontSize: 8.5, color: CustomColors.muted))]),
        ),
      );
}

class _EmptyNotes extends StatelessWidget {
  const _EmptyNotes({required this.onAdd});
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(21), border: Border.all(color: CustomColors.purple.withOpacity(.10))),
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFF3EDFF), Color(0xFFEFF7FF)]), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.auto_awesome_rounded, color: CustomColors.purple, size: 21)),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tr('Nothing here yet'), style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900)), SizedBox(height: 3), Text(tr('Ideas, meeting notes and checklists can live here.'), style: TextStyle(fontSize: 9.5, color: CustomColors.muted))])),
          TextButton(onPressed: onAdd, child: Text(tr('Write'), style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900))),
        ]),
      );
}

class ProjectCard extends StatelessWidget {
  const ProjectCard(this.title, this.icon, this.color, this.count, this.onTap, {super.key});
  final String title;
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(22), border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.72), width: 1.05), boxShadow: const [BoxShadow(color: Color(0x0B000000), blurRadius: 15, offset: Offset(0, 5))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(.13), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 21)),
            Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900))), Text(localizeNumber(count), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color))]),
            Text(count == 1 ? '${localizeNumber(1)} ${tr('task')}' : '${localizeNumber(count)} ${tr('tasks')}', style: const TextStyle(fontSize: 9.5, color: CustomColors.muted, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

String _greeting() {
  final hour = TimeOfDay.now().hour;
  if (hour < 12) return tr('Good morning');
  if (hour < 17) return tr('Good afternoon');
  return tr('Good evening');
}

String _dateLabel(DateTime date) {
  const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
  return '${tr(weekdays[date.weekday - 1])}  •  ${tr(months[date.month - 1])} ${localizeNumber(date.day)}';
}

String _motivation(int percent, {required bool hasTasks}) {
  if (!hasTasks) return tr('No pressure. Start with one small win.');
  if (percent >= 100) return tr('Perfect finish. Protect this momentum.');
  if (percent >= 80) return tr('Almost there. One last push can close the loop.');
  if (percent >= 60) return tr('You are in the flow. Keep the rhythm going.');
  if (percent >= 40) return tr('Solid progress. Your future self will thank you.');
  if (percent >= 20) return tr('Good start. Small wins are adding up.');
  if (percent >= 10) return tr('One step is enough to start the momentum.');
  return tr('Pick one thing. Give it your full attention.');
}
