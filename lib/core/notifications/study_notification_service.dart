import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../features/settings/repositories/app_preferences_repository.dart';

class StudyNotificationService {
  static const _channelId = 'study_reminders';
  static const _baseNotificationId = 4100;

  final FlutterLocalNotificationsPlugin plugin;
  bool _initialized = false;

  StudyNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : plugin = plugin ?? FlutterLocalNotificationsPlugin();

  Future<void> configure(
    AppSettings settings, {
    bool requestPermission = false,
  }) async {
    await _initialize();
    if (requestPermission) await _requestPermission();
    await plugin.cancelAllPendingNotifications();
    if (!settings.notificationsEnabled) return;

    final hour = settings.reminderMinutes ~/ 60;
    final minute = settings.reminderMinutes % 60;
    if (settings.notificationPlan == 'weekdays') {
      for (var weekday = DateTime.monday;
          weekday <= DateTime.friday;
          weekday += 1) {
        await _schedule(
          id: _baseNotificationId + weekday,
          scheduledDate: _nextWeekday(weekday, hour, minute),
          match: DateTimeComponents.dayOfWeekAndTime,
        );
      }
      return;
    }

    await _schedule(
      id: _baseNotificationId,
      scheduledDate: _nextTime(hour, minute),
      match: DateTimeComponents.time,
    );
  }

  Future<void> _initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  Future<void> _requestPermission() async {
    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _schedule({
    required int id,
    required tz.TZDateTime scheduledDate,
    required DateTimeComponents match,
  }) {
    return plugin.zonedSchedule(
      id: id,
      title: 'MaiHonGo',
      body: 'A short Japanese practice keeps your progress moving.',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Study reminders',
          channelDescription: 'Reminders for daily Japanese practice',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: match,
      payload: 'study-reminder',
    );
  }

  tz.TZDateTime _nextTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextWeekday(int weekday, int hour, int minute) {
    var scheduled = _nextTime(hour, minute);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
