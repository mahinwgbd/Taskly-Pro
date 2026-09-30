import 'package:flutter/services.dart';

/// Lightweight app-wide touch feedback. Debounced so scrolling does not
/// produce a stream of clicks/haptics.
class InteractionFeedback {
  InteractionFeedback._();
  static DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);

  static Future<void> tap() async {
    final now = DateTime.now();
    if (now.difference(_last).inMilliseconds < 70) return;
    _last = now;
    await Future.wait([
      SystemSound.play(SystemSoundType.click),
      HapticFeedback.lightImpact(),
    ]);
  }
}
