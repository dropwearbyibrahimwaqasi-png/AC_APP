import 'package:flutter/material.dart';
import '../models/reminder.dart';
import '../services/api_service.dart';
import '../services/alarm_service.dart';
import '../theme.dart';
import 'add_reminder_screen.dart';
import 'follow_up_screen.dart';

class ReminderListScreen extends StatefulWidget {
  const ReminderListScreen({super.key});

  @override
  State<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends State<ReminderListScreen> {
  final ApiService _api = ApiService();
  late Future<List<Reminder>> _remindersFuture;
  String _filter = 'upcoming'; // upcoming | completed | all

  @override
  void initState() {
    super.initState();
    _remindersFuture = _api.fetchReminders();
  }

  void _refresh() {
    setState(() {
      _remindersFuture = _api.fetchReminders();
    });
  }

  List<Reminder> _applyFilter(List<Reminder> reminders) {
    switch (_filter) {
      case 'completed':
        return reminders.where((r) => r.status == 'completed').toList();
      case 'upcoming':
        return reminders.where((r) => r.status == 'pending').toList();
      default:
        return reminders;
    }
  }

  Map<String, List<Reminder>> _groupByDay(List<Reminder> reminders) {
    final sorted = [...reminders]..sort((a, b) => a.remindAt.compareTo(b.remindAt));
    final today = DateTime.now();
    final groups = <String, List<Reminder>>{};

    for (final r in sorted) {
      final d = r.remindAt;
      final isToday = d.year == today.year && d.month == today.month && d.day == today.day;
      final tomorrow = today.add(const Duration(days: 1));
      final isTomorrow = d.year == tomorrow.year && d.month == tomorrow.month && d.day == tomorrow.day;
      final label = isToday
          ? 'Today - ${_longDate(d)}'
          : isTomorrow
              ? 'Tomorrow - ${_longDate(d)}'
              : _longDate(d);
      groups.putIfAbsent(label, () => []).add(r);
    }
    return groups;
  }

  String _longDate(DateTime d) {
    const months = ['', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'upcoming', label: Text('Upcoming')),
                ButtonSegment(value: 'completed', label: Text('Completed')),
                ButtonSegment(value: 'all', label: Text('All')),
              ],
              selected: {_filter},
              onSelectionChanged: (s) => setState(() => _filter = s.first),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Reminder>>(
              future: _remindersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final reminders = _applyFilter(snapshot.data ?? []);
                if (reminders.isEmpty) {
                  return const Center(child: Text('Nothing here.'));
                }

                final groups = _groupByDay(reminders);
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final entry in groups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 6),
                        child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                      ),
                      for (final r in entry.value)
                        Card(
                          child: ListTile(
                            leading: Icon(
                              r.status == 'completed' ? Icons.check_circle : Icons.notifications_active_outlined,
                              color: r.status == 'completed' ? AppColors.visited : AppColors.accent,
                            ),
                            title: Text(r.description),
                            subtitle: Text(
                              '${_two(r.remindAt.hour)}:${_two(r.remindAt.minute)}'
                              '${r.location != null ? '  •  ${r.location}' : ''}',
                            ),
                            onTap: r.status == 'pending'
                                ? () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => FollowUpScreen(reminder: r)),
                                    );
                                    _refresh();
                                  }
                                : null,
                          ),
                        ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push<Reminder>(
            context,
            MaterialPageRoute(builder: (_) => const AddReminderScreen()),
          );
          if (created != null) {
            await AlarmService.scheduleForReminder(created);
            _refresh();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
