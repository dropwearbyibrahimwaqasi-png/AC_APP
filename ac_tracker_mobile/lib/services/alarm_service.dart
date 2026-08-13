import 'dart:async';
import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import '../models/reminder.dart';

/// Schedules reminders as real alarms — full-screen, looping sound and
/// vibration that continue until dismissed, and works even in silent mode —
/// instead of a normal notification that's easy to miss in the field.
class AlarmService {
  static Future<void> init() async {
    await Alarm.init();
  }

  static Future<void> scheduleAlarm({
    required int id,
    required String description,
    required DateTime dateTime,
  }) async {
    final settings = AlarmSettings(
      id: id,
      dateTime: dateTime,
      // Add your own alarm sound at mobile/assets/alarm.mp3 and register it
      // under `flutter: assets:` in pubspec.yaml.
      assetAudioPath: 'assets/alarm.mp3',
      loopAudio: true,
      vibrate: true,
      androidFullScreenIntent: true,
      volumeSettings: VolumeSettings.fade(
        volume: 0.9,
        fadeDuration: const Duration(seconds: 5),
        volumeEnforced: true,
      ),
      notificationSettings: NotificationSettings(
        title: 'Reminder',
        body: description,
        stopButton: 'Dismiss',
      ),
    );

    await Alarm.set(alarmSettings: settings);
  }

  static Future<void> scheduleForReminder(Reminder reminder) {
    return scheduleAlarm(
      id: reminder.id,
      description: reminder.description,
      dateTime: reminder.remindAt,
    );
  }

  /// Re-schedules the same alarm id to ring again after [by] — used for
  /// the Snooze button on the alert screen.
  static Future<void> snooze(int id, String description, Duration by) {
    return scheduleAlarm(
      id: id,
      description: description,
      dateTime: DateTime.now().add(by),
    );
  }

  static Future<void> cancel(int reminderId) async {
    await Alarm.stop(reminderId);
  }

  /// Calls [callback] with the reminder id whenever a scheduled alarm
  /// starts ringing, so the UI can jump to the full-screen alert screen
  /// regardless of which tab is currently open.
  static StreamSubscription<AlarmSet> onRing(void Function(int reminderId) callback) {
    return Alarm.ringing.listen((alarmSet) {
      for (final alarm in alarmSet.alarms) {
        callback(alarm.id);
      }
    });
  }
}
