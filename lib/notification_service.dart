import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'models.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  static const _channelId = 'taskly_task_reminders_v3';
  static const _channelName = 'Taskly task reminders';
  static const _channelDescription = 'Reminders for Taskly tasks';

  Future<bool> _notificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  Future<bool> setEnabled(bool enabled) async {
    if (!_ready) await initialize();
    if (!_ready) return false;

    final prefs = await SharedPreferences.getInstance();
    if (!enabled) {
      await prefs.setBool('notifications_enabled', false);
      await _plugin.cancelAll();
      return true;
    }

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    try {
      final granted = await androidPlugin?.requestNotificationsPermission() ?? true;
      if (!granted) {
        await prefs.setBool('notifications_enabled', false);
        await androidPlugin?.openAppNotificationSettings();
        return false;
      }

      try {
        final exactAllowed = await androidPlugin?.canScheduleExactNotifications();
        if (exactAllowed == false) {
          await androidPlugin?.requestExactAlarmsPermission();
        }
      } catch (_) {
        // Exact alarms are optional; scheduling falls back to inexact alarms.
      }

      await _ensureChannel();
      await prefs.setBool('notifications_enabled', true);
      await syncAllSavedTasks();
      return true;
    } catch (_) {
      await prefs.setBool('notifications_enabled', false);
      return false;
    }
  }

  Future<void> _ensureChannel() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ));
  }

  Future<bool> sendTestNotification() async {
    if (!_ready) await initialize();
    if (!_ready || !(await _notificationsEnabled())) return false;
    try {
      await _ensureChannel();
      await _plugin.show(
        id: 990001,
        title: 'Taskly test notification',
        body: 'Notifications are working correctly.',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList(<int>[0, 250, 100, 350]),
          ),
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> syncAllSavedTasks() async {
    if (!_ready || !(await _notificationsEnabled())) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('taskly_tasks_v6');
    if (raw == null || raw.trim().isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      for (final item in decoded) {
        if (item is Map) {
          await syncTaskReminder(TodoItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    } catch (_) {}
  }

  Future<void> initialize() async {
    if (kIsWeb) return;
    tz.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      // Keep UTC fallback if the OS timezone cannot be resolved.
    }

    const android = AndroidInitializationSettings('@mipmap/launcher_icon');
    const settings = InitializationSettings(android: android);
    try {
      await _plugin.initialize(settings: settings);
      _ready = true;
      await _ensureChannel();
    } catch (_) {
      // Notifications are optional; the rest of Taskly must still start.
      _ready = false;
    }
  }

  int _id(String taskId) => taskId.hashCode & 0x7fffffff;

  Future<void> cancelTaskReminder(String taskId) async {
    if (!_ready) return;
    await _plugin.cancel(id: _id(taskId));
  }

  Future<void> syncTaskReminder(TodoItem task) async {
    if (!_ready) await initialize();
    if (!_ready) return;

    if (!(await _notificationsEnabled()) || !task.reminder || task.completed || task.title.trim().isEmpty) {
      await cancelTaskReminder(task.id);
      return;
    }

    final timeParts = task.time.trim().split(':');
    if (timeParts.length < 2) {
      await cancelTaskReminder(task.id);
      return;
    }

    var hour = int.tryParse(timeParts[0].replaceAll(RegExp(r'[^0-9]'), '')) ?? -1;
    final minute = int.tryParse(timeParts[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? -1;
    final upper = task.time.toUpperCase();
    if (hour < 0 || minute < 0 || hour > 23 || minute > 59) {
      await cancelTaskReminder(task.id);
      return;
    }
    if (upper.contains('PM') && hour < 12) hour += 12;
    if (upper.contains('AM') && hour == 12) hour = 0;

    var scheduled = tz.TZDateTime(tz.local, task.date.year, task.date.month, task.date.day, hour, minute);
    final now = tz.TZDateTime.now(tz.local);

    // If the original occurrence has passed, advance recurring tasks to the
    // next valid occurrence rather than silently dropping their reminder.
    while (!scheduled.isAfter(now) && task.repeat != 'Does not repeat') {
      scheduled = _nextOccurrence(scheduled, task.repeat);
    }
    if (!scheduled.isAfter(now)) {
      await cancelTaskReminder(task.id);
      return;
    }

    await cancelTaskReminder(task.id);
    await _ensureChannel();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        enableVibration: true,
        vibrationPattern: Int64List.fromList(<int>[0, 250, 100, 350]),
        playSound: true,
      ),
    );

    try {
      await _plugin.zonedSchedule(
        id: _id(task.id),
        title: 'Taskly reminder',
        body: task.title,
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: task.id,
      );
    } catch (_) {
      try {
        await _plugin.zonedSchedule(
          id: _id(task.id),
          title: 'Taskly reminder',
          body: task.title,
          scheduledDate: scheduled,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: task.id,
        );
      } catch (_) {
        // Do not crash the application if Android rejects scheduling.
      }
    }
  }

  tz.TZDateTime _nextOccurrence(tz.TZDateTime date, String repeat) {
    switch (repeat) {
      case 'Daily':
        return date.add(const Duration(days: 1));
      case 'Weekly':
        return date.add(const Duration(days: 7));
      case 'Weekdays':
        var next = date.add(const Duration(days: 1));
        while (next.weekday > DateTime.friday) {
          next = next.add(const Duration(days: 1));
        }
        return next;
      case 'Weekends':
        var next = date.add(const Duration(days: 1));
        while (next.weekday != DateTime.saturday && next.weekday != DateTime.sunday) {
          next = next.add(const Duration(days: 1));
        }
        return next;
      case 'Monthly':
        final month = date.month == 12 ? 1 : date.month + 1;
        final year = date.month == 12 ? date.year + 1 : date.year;
        final lastDay = DateTime(year, month + 1, 0).day;
        return tz.TZDateTime(tz.local, year, month, date.day.clamp(1, lastDay).toInt(), date.hour, date.minute);
      default:
        return date;
    }
  }

}
