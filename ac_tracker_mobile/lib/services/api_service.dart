import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/reminder.dart';
import '../models/day_summary.dart';
import '../config.dart';

class ApiService {
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-API-Key': apiKey,
      };

  Future<List<Reminder>> fetchReminders({String? status}) async {
    final uri = Uri.parse('$apiBaseUrl/reminders').replace(
      queryParameters: status != null ? {'status': status} : null,
    );
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to load reminders');
    }

    final List data = jsonDecode(response.body);
    return data.map((json) => Reminder.fromJson(json)).toList();
  }

  Future<Reminder> createReminder(
    String description,
    DateTime remindAt, {
    String? location,
  }) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/reminders'),
      headers: _headers,
      body: jsonEncode({
        'description': description,
        'location': location,
        'remind_at': remindAt.toIso8601String(),
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create reminder');
    }

    return Reminder.fromJson(jsonDecode(response.body));
  }

  /// Submits a follow-up after a reminder happens. If [nextReminderAt] is
  /// given, the backend auto-creates the next reminder and chains it.
  Future<void> submitFollowUp({
    required int reminderId,
    String? note,
    String? photoPath,
    DateTime? nextReminderAt,
    String? nextReminderDescription,
  }) async {
    final uri = Uri.parse('$apiBaseUrl/reminders/$reminderId/follow-up');
    final request = http.MultipartRequest('POST', uri);
    request.headers['X-API-Key'] = apiKey;

    if (note != null) request.fields['follow_up_note'] = note;
    if (nextReminderAt != null) {
      request.fields['next_reminder_at'] = nextReminderAt.toIso8601String();
    }
    if (nextReminderDescription != null) {
      request.fields['next_reminder_description'] = nextReminderDescription;
    }
    if (photoPath != null) {
      request.files.add(await http.MultipartFile.fromPath('follow_up_photo', photoPath));
    }

    final response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('Failed to submit follow-up');
    }
  }

  /// Fetches the day's activity: clustered "stays" plus distance/duration
  /// stats. [date] is 'YYYY-MM-DD'.
  Future<DaySummary> fetchDaySummary(String date) async {
    final uri = Uri.parse('$apiBaseUrl/location-logs/summary')
        .replace(queryParameters: {'date': date});
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to load day summary');
    }

    return DaySummary.fromJson(jsonDecode(response.body));
  }
}
