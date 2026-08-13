import 'stay.dart';

class DaySummary {
  final String date;
  final List<Stay> stays;
  final double distanceKm;
  final int trackedMinutes;

  DaySummary({
    required this.date,
    required this.stays,
    required this.distanceKm,
    required this.trackedMinutes,
  });

  factory DaySummary.fromJson(Map<String, dynamic> json) {
    return DaySummary(
      date: json['date'],
      stays: (json['stays'] as List).map((s) => Stay.fromJson(s)).toList(),
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      trackedMinutes: json['tracked_minutes'] ?? 0,
    );
  }
}
