import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import '../models/reminder.dart';
import '../services/api_service.dart';
import '../services/alarm_service.dart';
import '../theme.dart';
import 'follow_up_screen.dart';

class ReminderAlertScreen extends StatefulWidget {
  final int reminderId;
  const ReminderAlertScreen({super.key, required this.reminderId});

  @override
  State<ReminderAlertScreen> createState() => _ReminderAlertScreenState();
}

class _ReminderAlertScreenState extends State<ReminderAlertScreen> {
  final ApiService _api = ApiService();
  Reminder? _reminder;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final reminders = await _api.fetchReminders();
      final match = reminders.where((r) => r.id == widget.reminderId);
      if (match.isNotEmpty && mounted) {
        setState(() => _reminder = match.first);
      }
    } catch (_) {
      // Offline — the alarm still rings and can still be dismissed/snoozed,
      // it just won't have the description/location to show until the
      // network's back.
    }
  }

  Future<void> _dismiss() async {
    await Alarm.stop(widget.reminderId);
    if (!mounted) return;
    final reminder = _reminder;
    Navigator.of(context).pop();
    if (reminder != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => FollowUpScreen(reminder: reminder)),
      );
    }
  }

  Future<void> _snooze() async {
    await Alarm.stop(widget.reminderId);
    if (_reminder != null) {
      await AlarmService.snooze(widget.reminderId, _reminder!.description, const Duration(minutes: 10));
    }
    if (mounted) Navigator.of(context).pop();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final time = _reminder != null
        ? '${_two(_reminder!.remindAt.hour)}:${_two(_reminder!.remindAt.minute)}'
        : '';

    return PopScope(
      canPop: false, // back button shouldn't silently dismiss an active alarm
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(time, style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),
                Container(
                  width: 140,
                  height: 140,
                  decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                  child: const Icon(Icons.notifications, color: Colors.white, size: 64),
                ),
                const SizedBox(height: 40),
                Text(
                  _reminder?.description ?? 'Reminder',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                ),
                if (_reminder?.location != null) ...[
                  const SizedBox(height: 8),
                  Text(_reminder!.location!, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                ],
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _snooze,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Column(children: [
                          Icon(Icons.snooze),
                          SizedBox(height: 4),
                          Text('Snooze 10 min'),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _dismiss,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Column(children: [
                          Icon(Icons.check),
                          SizedBox(height: 4),
                          Text('Dismiss'),
                        ]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
