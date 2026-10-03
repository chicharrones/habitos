import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzData;
import '../models/habit.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // Entry point for background notification responses
}

class NotificationsHelper {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'habits_exact_reminders';
  static const String channelName = 'Recordatorios de Hábitos';
  static const String channelDescription =
      'Notificaciones de alta prioridad para recordar tus hábitos diarios.';

  static Future<void> init({
    DidReceiveNotificationResponseCallback? onNotificationResponse,
  }) async {
    tzData.initializeTimeZones();
    try {
      final dynamic info = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = info is String ? info : info.toString();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('Etc/UTC'));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Create high importance notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<bool> requestPermissions() async {
    final statusNotif = await Permission.notification.request();
    final statusExact = await Permission.scheduleExactAlarm.request();
    return statusNotif.isGranted && statusExact.isGranted;
  }

  static Future<void> openBatteryOptimizationSettings() async {
    await Permission.ignoreBatteryOptimizations.request();
  }

  static Future<void> scheduleHabitAlarms(Habit habit) async {
    if (habit.id == null || habit.isArchived || habit.alarmTimes.isEmpty) {
      await cancelHabitAlarms(habit.id ?? -1);
      return;
    }

    // Cancel old alarms for this habit
    await cancelHabitAlarms(habit.id!);

    final now = tz.TZDateTime.now(tz.local);
    final canExact = await Permission.scheduleExactAlarm.isGranted;

    final scheduleMode = canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    for (int i = 0; i < habit.alarmTimes.length; i++) {
      final timeStr = habit.alarmTimes[i];
      final parts = timeStr.split(':');
      if (parts.length != 2) continue;

      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;

      final notificationId = (habit.id! * 100) + i;

      if (habit.frequencyType == 'specificDays' && habit.frequencyDays.isNotEmpty) {
        for (final day in habit.frequencyDays) {
          final specificNotifId = (habit.id! * 1000) + (day * 10) + i;
          final scheduledDate = _nextInstanceOfDayAndTime(day, hour, minute);

          await flutterLocalNotificationsPlugin.zonedSchedule(
            id: specificNotifId,
            title: habit.title,
            body: habit.description.isNotEmpty
                ? habit.description
                : '¡Es hora de cumplir tu hábito!',
            scheduledDate: scheduledDate,
            notificationDetails: _getNotificationDetails(),
            androidScheduleMode: scheduleMode,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        }
      } else {
        // Daily or timesPerWeek default daily reminder
        tz.TZDateTime scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );

        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }

        await flutterLocalNotificationsPlugin.zonedSchedule(
          id: notificationId,
          title: habit.title,
          body: habit.description.isNotEmpty
              ? habit.description
              : '¡Es hora de cumplir tu hábito!',
          scheduledDate: scheduledDate,
          notificationDetails: _getNotificationDetails(),
          androidScheduleMode: scheduleMode,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    }
  }

  static NotificationDetails _getNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'DONE_ACTION',
            'Hecho',
            showsUserInterface: false,
          ),
          AndroidNotificationAction(
            'SNOOZE_ACTION',
            'Posponer 10 min',
            showsUserInterface: false,
          ),
          AndroidNotificationAction(
            'SKIP_ACTION',
            'Omitir',
            showsUserInterface: false,
          ),
        ],
      ),
    );
  }

  static tz.TZDateTime _nextInstanceOfDayAndTime(
      int dayOfWeek, int hour, int minute) {
    tz.TZDateTime scheduledDate = tz.TZDateTime.now(tz.local);
    scheduledDate = tz.TZDateTime(
        tz.local, scheduledDate.year, scheduledDate.month, scheduledDate.day, hour, minute);

    while (scheduledDate.weekday != dayOfWeek ||
        scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static Future<void> cancelHabitAlarms(int habitId) async {
    for (int i = 0; i < 10; i++) {
      await flutterLocalNotificationsPlugin.cancel(id: (habitId * 100) + i);
      for (int day = 1; day <= 7; day++) {
        await flutterLocalNotificationsPlugin.cancel(
            id: (habitId * 1000) + (day * 10) + i);
      }
    }
  }

  static Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
