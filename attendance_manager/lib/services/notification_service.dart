import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzData;
import '../services/database_helper.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Initialize timezone
    tzData.initializeTimeZones();

    // Android initialization
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();

    // Initialization settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    // Initialize plugin
    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final payload = response.payload;
        if (payload == null) return;

        final parts = payload.split(':');
        if (parts.length != 2 || parts[0] != 'subjectId') return;

        final subjectId = int.tryParse(parts[1]);
        if (subjectId == null) return;

        final db = DatabaseHelper.instance;

        if (response.actionId == 'attended') {
          await db.updateSubjectStatus(subjectId, 'Attended');
        } else if (response.actionId == 'missed') {
          await db.updateSubjectStatus(subjectId, 'Missed');
        } else if (response.actionId == 'cancelled') {
          await db.updateSubjectStatus(subjectId, 'Cancelled');
        }
      },
    );
  }

  Future<void> schedulePeriodEndNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'period_end_channel_id',
      'Period End Notifications',
      channelDescription: 'Notifies when a class period ends',
      importance: Importance.max,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('attended', 'Attended'),
        AndroidNotificationAction('missed', 'Missed'),
        AndroidNotificationAction('cancelled', 'Cancelled'),
      ],
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      payload: payload,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'general_channel_id',
      'General Notifications',
      channelDescription: 'Notifies about important events',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
