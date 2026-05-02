import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  const androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await notificationsPlugin.initialize(initSettings);

  // Android 13+ 需要手动请求通知权限
  final android = notificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await android?.requestNotificationsPermission();
}

/// 安排一条定时提醒
Future<void> scheduleReminder(
    int id, String title, String body, DateTime scheduledTime) async {
  if (scheduledTime.isBefore(DateTime.now())) return;

  const androidDetails = AndroidNotificationDetails(
    'notepad_reminders',
    '记事本提醒',
    channelDescription: '记事本的定时提醒通知',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  );
  const details = NotificationDetails(android: androidDetails);

  try {
    await notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  } catch (e) {
    // 如果精确闹钟权限不可用，尝试使用非精确模式
    try {
      await notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // 忽略最终失败
    }
  }
}

/// 取消一条提醒
Future<void> cancelReminder(int id) async {
  await notificationsPlugin.cancel(id);
}
