import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../services/database_helper.dart';

// Define the alarm task identifiers.
const scheduleNotificationTask = 'schedulePeriodEndNotifications';
const markMissedTask = 'markMissedClassesAtMidnight';

// Initialize and schedule the tasks
Future<void> initializeBackgroundTasks() async {
  // Initialize the Android alarm manager.
  await AndroidAlarmManager.initialize();

  // Schedule the task to schedule period end notifications
  await AndroidAlarmManager.periodic(
    const Duration(hours: 24), // Repeat every 24 hours
    0, // Task ID for the notification task
    callbackDispatcherForScheduleNotifications,
    exact: true,
    wakeup: true,
  );

  // Schedule the task to mark missed classes at midnight
  await AndroidAlarmManager.periodic(
    const Duration(hours: 24), // Repeat every 24 hours
    1, // Task ID for the mark missed task
    callbackDispatcherForMarkMissedClasses,
    exact: true,
    wakeup: true,
  );
}

// Callback for scheduling period end notifications.
void callbackDispatcherForScheduleNotifications() async {
  final db = DatabaseHelper.instance;
  final now = DateTime.now();
  final todayKey = DateFormat('yyyy-MM-dd').format(now);

  final subjects = await db.getSubjectsByDate(todayKey);
  for (final s in subjects) {
    if (s.status != 'Pending') continue;

    final end = _parseEndTime(s.time);
    if (end == null) continue;

    final notifyAt = DateTime(
      now.year,
      now.month,
      now.day,
      end.hour,
      end.minute,
    ).subtract(const Duration(minutes: 5));

    if (notifyAt.isAfter(now)) {
      await NotificationService().schedulePeriodEndNotification(
        id: s.id!,
        title: 'Class Ending: ${s.name}',
        body: 'Tap to mark attendance',
        scheduledDate: notifyAt,
        payload: s.id.toString(),
      );
    }
  }
}

// Callback for marking missed classes.
void callbackDispatcherForMarkMissedClasses() async {
  final db = DatabaseHelper.instance;
  final now = DateTime.now();
  final todayKey = DateFormat('yyyy-MM-dd').format(now);

  final subjects = await db.getSubjectsByDate(todayKey);
  for (final s in subjects) {
    if (s.status == 'Pending') {
      await db.updateSubjectStatus(s.id!, 'Missed');
    }
  }
}

DateTime? _parseEndTime(String range) {
  try {
    final parts = range.split('-');
    if (parts.length != 2) return null;
    final raw = parts[1].trim();
    DateTime dt;
    try {
      dt = DateFormat.jm().parseLoose(raw);
    } catch (_) {
      dt = DateFormat('HH:mm').parseLoose(raw);
    }
    return dt;
  } catch (_) {
    return null;
  }
}
