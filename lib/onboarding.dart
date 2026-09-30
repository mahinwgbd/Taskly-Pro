import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'shell.dart';
import 'util.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key, required this.onThemeChanged, required this.onComplete, required this.locale, required this.onLanguageChanged});
  final ValueChanged<ThemeMode> onThemeChanged;
  final VoidCallback onComplete;
  final Locale locale;
  final ValueChanged<Locale> onLanguageChanged;

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> with TickerProviderStateMixin {
  late final PageController pageController = PageController();
  late final AnimationController floatController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
  int page = 0;

  final pages = const [
    _IntroPage(icon: Icons.bolt_rounded, eyebrow: 'PLAN WITHOUT THE NOISE', title: 'Turn busy days\ninto clear steps.', body: 'Tasks, focus sessions and progress—designed to keep your attention on what matters.'),
    _IntroPage(icon: Icons.auto_awesome_rounded, eyebrow: 'CAPTURE EVERYTHING', title: 'Ideas deserve\na place too.', body: 'Write notes, add checklists, pin important thoughts and find them instantly.'),
    _IntroPage(icon: Icons.insights_rounded, eyebrow: 'SEE YOUR MOMENTUM', title: 'Small wins become\nbig progress.', body: 'Track completion, build streaks and understand how your time is moving.'),
  ];

  @override
  void dispose() { pageController.dispose(); floatController.dispose(); super.dispose(); }

  void _finish() {
    widget.onComplete();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AppShell(onThemeChanged: widget.onThemeChanged, locale: widget.locale, onLanguageChanged: widget.onLanguageChanged)));
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final current = pages[page];
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark ? const [Color(0xFF11162B), Color(0xFF1C2340)] : const [Color(0xFFF8FAFF), Color(0xFFEEF3FF)],
          ),
        ),
        child: SafeArea(
          child: Stack(children: [
            Positioned(top: -110, right: -70, child: _Orb(size: 260, color: CustomColors.primary.withOpacity(dark ? .12 : .09))),
            Positioned(bottom: -120, left: -80, child: _Orb(size: 290, color: CustomColors.accent.withOpacity(dark ? .09 : .07))),
            Column(children: [
              Padding(padding: const EdgeInsets.fromLTRB(22, 18, 22, 0), child: Row(children: [
                Container(width: 38, height: 38, decoration: BoxDecoration(gradient: const LinearGradient(colors: [CustomColors.primary, Color(0xFF8BB9FF)]), borderRadius: BorderRadius.circular(13), boxShadow: const [BoxShadow(color: Color(0x225B7CFA), blurRadius: 14, offset: Offset(0, 6))]), child: const Icon(Icons.check_rounded, color: Colors.white, size: 22)),
                const SizedBox(width: 10),
                Text('Taskly', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: dark ? Colors.white : CustomColors.text)),
                const Spacer(),
                TextButton(onPressed: _finish, child: Text(tr('Skip'), style: TextStyle(color: dark ? Colors.white70 : CustomColors.muted, fontWeight: FontWeight.w800))),
              ])),
              Expanded(child: PageView.builder(controller: pageController, itemCount: pages.length, onPageChanged: (v) => setState(() => page = v), itemBuilder: (_, i) => _AnimatedIntro(page: pages[i], controller: floatController, index: i))),
              Padding(padding: const EdgeInsets.fromLTRB(22, 0, 22, 22), child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(pages.length, (i) => AnimatedContainer(duration: const Duration(milliseconds: 220), margin: const EdgeInsets.symmetric(horizontal: 4), width: i == page ? 28 : 7, height: 7, decoration: BoxDecoration(color: i == page ? CustomColors.primary : CustomColors.primary.withOpacity(.18), borderRadius: BorderRadius.circular(10))))),
                const SizedBox(height: 22),
                SizedBox(width: double.infinity, height: 56, child: FilledButton(onPressed: page == pages.length - 1 ? _finish : () => pageController.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic), style: FilledButton.styleFrom(backgroundColor: CustomColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), elevation: 8, shadowColor: CustomColors.primary.withOpacity(.25)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(page == pages.length - 1 ? tr('Let’s get started') : tr('Continue'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)), const SizedBox(width: 8), Icon(page == pages.length - 1 ? Icons.arrow_forward_rounded : Icons.chevron_right_rounded)]))),
              ])),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _IntroPage {
  const _IntroPage({required this.icon, required this.eyebrow, required this.title, required this.body});
  final IconData icon;
  final String eyebrow;
  final String title;
  final String body;
}

class _AnimatedIntro extends StatelessWidget {
  const _AnimatedIntro({required this.page, required this.controller, required this.index});
  final _IntroPage page;
  final AnimationController controller;
  final int index;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: controller, builder: (_, __) {
        final wave = math.sin(controller.value * math.pi * 2 + index) * 7;
        return Padding(padding: const EdgeInsets.symmetric(horizontal: 28), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Transform.translate(offset: Offset(0, wave), child: Stack(alignment: Alignment.center, children: [
            Container(width: 245, height: 245, decoration: BoxDecoration(shape: BoxShape.circle, color: CustomColors.primary.withOpacity(.055))),
            Container(width: 188, height: 188, decoration: BoxDecoration(gradient: const LinearGradient(colors: [CustomColors.primary, Color(0xFF7CB9FF)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(56), boxShadow: const [BoxShadow(color: Color(0x335B7CFA), blurRadius: 34, offset: Offset(0, 18))]), child: Icon(page.icon, color: Colors.white, size: 82)),
            Positioned(right: 4, top: 18, child: _FloatingBadge(icon: Icons.star_rounded, color: CustomColors.yellow)),
            Positioned(left: 2, bottom: 20, child: _FloatingBadge(icon: Icons.favorite_rounded, color: CustomColors.accent)),
          ])),
          const SizedBox(height: 40),
          Text(tr(page.eyebrow), style: const TextStyle(color: CustomColors.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.7)),
          const SizedBox(height: 10),
          Text(tr(page.title), textAlign: TextAlign.center, style: TextStyle(fontSize: 34, height: 1.05, fontWeight: FontWeight.w900, letterSpacing: -1, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : CustomColors.text)),
          const SizedBox(height: 14),
          Text(tr(page.body), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, height: 1.5, color: CustomColors.muted)),
        ]));
  });
}

class _FloatingBadge extends StatelessWidget {
  const _FloatingBadge({required this.icon, required this.color});
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(width: 42, height: 42, decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 14, offset: Offset(0, 5))]), child: Icon(icon, color: color, size: 21));
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}
