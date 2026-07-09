import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Daily "don't lose your streak" reminder via local notifications.
/// Android-only for now: web has no reliable scheduled notifications
/// without a push server, and iOS ships later.
abstract final class ReminderService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static const _notificationId = 1;

  static Future<void> _ensureInit() async {
    if (_initialized) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _initialized = true;
  }

  /// Schedules the daily reminder. Returns false when unsupported here or
  /// the notification permission was denied.
  static Future<bool> enable() async {
    if (kIsWeb) return false;
    try {
      await _ensureInit();
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return false;
      final granted = await android.requestNotificationsPermission() ?? true;
      if (!granted) return false;
      await _plugin.periodicallyShow(
        id: _notificationId,
        title: "Don't lose your streak! 🔥",
        body: 'One quick level keeps your streak alive.',
        repeatInterval: RepeatInterval.daily,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'streak_reminders',
            'Streak reminders',
            channelDescription: 'Daily reminder to keep your learning streak',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> disable() async {
    if (kIsWeb) return;
    try {
      await _ensureInit();
      await _plugin.cancel(id: _notificationId);
    } catch (_) {}
  }
}
