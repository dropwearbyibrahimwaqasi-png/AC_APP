import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/reminder.dart';
import '../theme.dart';
import 'add_reminder_screen.dart';
import 'daily_summary_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _api = ApiService();
  late Future<_DashboardData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  Future<_DashboardData> _load() async {
    final today = DateTime.now();
    final dateStr = '${today.year}-${_two(today.month)}-${_two(today.day)}';
    final reminders = await _api.fetchReminders();
    final summary = await _api.fetchDaySummary(dateStr);

    final todayReminders = reminders
        .where((r) =>
            r.remindAt.year == today.year &&
            r.remindAt.month == today.month &&
            r.remindAt.day == today.day)
        .toList()
      ..sort((a, b) => a.remindAt.compareTo(b.remindAt));

    return _DashboardData(todayReminders: todayReminders, locationsVisited: summary.stays.length);
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  void _refresh() => setState(() => _dataFuture = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: FutureBuilder<_DashboardData>(
            future: _dataFuture,
            builder: (context, snapshot) {
              final data = snapshot.data;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Good Morning!',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const Text('Have a productive day ahead.', style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: "Today's Meetings",
                          value: '${data?.todayReminders.length ?? '-'}',
                          icon: Icons.event,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Locations Visited',
                          value: '${data?.locationsVisited ?? '-'}',
                          icon: Icons.location_on,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Upcoming Reminders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DailySummaryScreen()),
                        ),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  if (data == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (data.todayReminders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('No reminders for today.'),
                    )
                  else
                    ...data.todayReminders.map((r) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.notifications_active_outlined, color: AppColors.accent),
                            title: Text(r.description),
                            subtitle: Text(
                              '${_two(r.remindAt.hour)}:${_two(r.remindAt.minute)}'
                              '${r.location != null ? '  •  ${r.location}' : ''}',
                            ),
                          ),
                        )),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final created = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddReminderScreen()),
                      );
                      if (created != null) _refresh();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Reminder'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                Icon(icon, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardData {
  final List<Reminder> todayReminders;
  final int locationsVisited;
  _DashboardData({required this.todayReminders, required this.locationsVisited});
}
