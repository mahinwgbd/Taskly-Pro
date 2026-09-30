import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'interaction_feedback.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding.dart';
import 'shell.dart';
import 'util.dart';
import 'notification_service.dart';
import 'security_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const TodoApp());
}

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  ThemeMode themeMode = ThemeMode.light;
  bool loaded = false;
  bool onboardingDone = false;
  Locale appLocale = const Locale('en');

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('theme_mode') ?? 'light';
    final done = prefs.getBool('taskly_onboarding_complete') ?? false;
    final language = prefs.getString('taskly_language') ?? 'en';
    if (!mounted) return;
    setState(() {
      themeMode = switch (value) {
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => ThemeMode.light,
      };
      onboardingDone = done;
      appLocale = Locale(language == 'bn' ? 'bn' : 'en');
      setTasklyLanguage(language);
      loaded = true;
    });
  }

  Future<void> setAppLanguage(Locale locale) async {
    final normalized = locale.languageCode == 'bn' ? const Locale('bn') : const Locale('en');
    setTasklyLanguage(normalized.languageCode);
    if (mounted) setState(() => appLocale = normalized);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('taskly_language', normalized.languageCode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    setState(() => themeMode = mode);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: mode == ThemeMode.dark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: mode == ThemeMode.dark ? const Color(0xFF0B0E16) : Colors.white,
      systemNavigationBarIconBrightness: mode == ThemeMode.dark ? Brightness.light : Brightness.dark,
    ));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
      _ => 'light',
    });
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('taskly_onboarding_complete', true);
    if (mounted) setState(() => onboardingDone = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('bn')],
        theme: appTheme(Brightness.light),
        home: const _StartupSplash(),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Taskly Pro',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('bn')],
      theme: appTheme(Brightness.light),
      darkTheme: appTheme(Brightness.dark),
      themeMode: themeMode,
      locale: appLocale,
      builder: (context, child) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => InteractionFeedback.tap(),
        child: child!,
      ),
      home: onboardingDone
          ? SecurityGate(child: AppShell(onThemeChanged: setThemeMode, locale: appLocale, onLanguageChanged: setAppLanguage))
          : Onboarding(onThemeChanged: setThemeMode, onComplete: completeOnboarding, locale: appLocale, onLanguageChanged: setAppLanguage),
    );
  }
}

class _StartupSplash extends StatefulWidget {
  const _StartupSplash();
  @override
  State<_StartupSplash> createState() => _StartupSplashState();
}

class _StartupSplashState extends State<_StartupSplash> with TickerProviderStateMixin {
  late final AnimationController controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1250))..forward();
  late final AnimationController pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);

  @override
  void dispose() { controller.dispose(); pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark ? const [Color(0xFF0E1530), Color(0xFF202C55), Color(0xFF11162B)] : const [Color(0xFFF5F8FF), Color(0xFFE9F0FF), Color(0xFFF9F4FF)],
          ),
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([controller, pulse]),
          builder: (_, __) => Stack(
            children: [
              Positioned(top: -100, right: -80, child: _StartupOrb(size: 270, opacity: dark ? .12 : .10)),
              Positioned(bottom: -130, left: -90, child: _StartupOrb(size: 300, opacity: dark ? .10 : .08)),
              Center(
                child: FadeTransition(
                  opacity: CurvedAnimation(parent: controller, curve: Curves.easeOut),
                  child: ScaleTransition(
                    scale: Tween(begin: .78, end: 1.0).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack)),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Transform.translate(
                        offset: Offset(0, -pulse.value * 5),
                        child: Stack(alignment: Alignment.center, children: [
                          Container(width: 158 + pulse.value * 12, height: 158 + pulse.value * 12, decoration: BoxDecoration(shape: BoxShape.circle, color: CustomColors.primary.withOpacity(.07))),
                          Container(width: 104, height: 104, decoration: BoxDecoration(gradient: const LinearGradient(colors: [CustomColors.primary, Color(0xFF7CB9FF)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(34), boxShadow: const [BoxShadow(color: Color(0x405B7CFA), blurRadius: 35, offset: Offset(0, 16))]), child: const Icon(Icons.check_rounded, color: Colors.white, size: 57)),
                          Positioned(right: -2, top: 3, child: _StartupBadge(icon: Icons.auto_awesome_rounded)),
                          Positioned(left: -6, bottom: 8, child: _StartupBadge(icon: Icons.bolt_rounded)),
                        ]),
                      ),
                      const SizedBox(height: 28),
                      Text('Taskly', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.2, color: dark ? Colors.white : CustomColors.text)),
                      const SizedBox(height: 7),
                      Text(tr('PLAN  •  FOCUS  •  FINISH'), style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 2.1, color: dark ? Colors.white70 : CustomColors.muted)),
                      const SizedBox(height: 28),
                      SizedBox(width: 96, child: ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: CurvedAnimation(parent: controller, curve: Curves.easeOut).value, minHeight: 4, backgroundColor: CustomColors.primary.withOpacity(.10), valueColor: const AlwaysStoppedAnimation(CustomColors.primary)))),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartupOrb extends StatelessWidget {
  const _StartupOrb({required this.size, required this.opacity});
  final double size;
  final double opacity;
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: CustomColors.primary.withOpacity(opacity)));
}

class _StartupBadge extends StatelessWidget {
  const _StartupBadge({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(width: 34, height: 34, decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 12, offset: Offset(0, 5))]), child: Icon(icon, color: CustomColors.purple, size: 17));
}
