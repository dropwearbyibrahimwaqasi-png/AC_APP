import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/reminder.dart';
import '../models/day_summary.dart';
import '../theme.dart';

class DailySummaryScreen extends StatefulWidget {
  const DailySummaryScreen({super.key});

  @override
  State<DailySummaryScreen> createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends State<DailySummaryScreen> {
  final ApiService _api = ApiService();
  DateTime _selectedDate = DateTime.now();
  late Future<_DayData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  Future<_DayData> _load() async {
    final dateStr = '${_selectedDate.year}-${_two(_selectedDate.month)}-${_two(_selectedDate.day)}';
    final reminders = await _api.fetchReminders();
    final summary = await _api.fetchDaySummary(dateStr);

    final dayReminders = reminders
        .where((r) =>
            r.remindAt.year == _selectedDate.year &&
            r.remindAt.month == _selectedDate.month &&
            r.remindAt.day == _selectedDate.day)
        .toList();

    return _DayData(reminders: dayReminders, summary: summary);
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  void _changeDate(int deltaDays) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: deltaDays));
      _dataFuture = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_selectedDate.year}-${_two(_selectedDate.month)}-${_two(_selectedDate.day)}'),
        actions: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeDate(-1)),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeDate(1)),
        ],
      ),
      body: FutureBuilder<_DayData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final entries = _buildTimeline(data);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(child: _statCard('Meetings', '${data.reminders.length}', Icons.event)),
                  const SizedBox(width: 12),
                  Expanded(child: _statCard('Locations Visited', '${data.summary.stays.length}', Icons.location_on)),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              if (entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Nothing recorded for this day.'),
                )
              else
                ...entries,
            ],
          );
        },
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Icon(icon, color: AppColors.primary, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTimeline(_DayData data) {
    final items = <MapEntry<String, _TimelineRow>>[];

    for (final r in data.reminders) {
      final time = '${_two(r.remindAt.hour)}:${_two(r.remindAt.minute)}';
      items.add(MapEntry(
        time,
        _TimelineRow(
          time: time,
          title: r.description,
          subtitle: r.location ?? '',
          tag: 'Meeting',
          tagColor: AppColors.accent,
        ),
      ));
    }

    for (final s in data.summary.stays) {
      items.add(MapEntry(
        s.from,
        _TimelineRow(
          time: s.from,
          title: 'Site Visit',
          subtitle: '${s.latitude.toStringAsFixed(4)}, ${s.longitude.toStringAsFixed(4)}',
          tag: 'Visited',
          tagColor: AppColors.visited,
        ),
      ));
    }

    items.sort((a, b) => a.key.compareTo(b.key));
    return items.map((e) => e.value).toList();
  }
}

class _TimelineRow extends StatelessWidget {
  final String time;
  final String title;
  final String subtitle;
  final String tag;
  final Color tagColor;

  const _TimelineRow({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.tagColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(time, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ),
          Column(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: tagColor, shape: BoxShape.circle)),
              Container(width: 2, height: 30, color: Colors.grey.shade300),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tagColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(tag, style: TextStyle(color: tagColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayData {
  final List<Reminder> reminders;
  final DaySummary summary;
  _DayData({required this.reminders, required this.summary});
}
