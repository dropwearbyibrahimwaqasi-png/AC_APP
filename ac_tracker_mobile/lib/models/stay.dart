class Stay {
  final double latitude;
  final double longitude;
  final String from;
  final String to;
  final int durationMinutes;

  Stay({
    required this.latitude,
    required this.longitude,
    required this.from,
    required this.to,
    required this.durationMinutes,
  });

  factory Stay.fromJson(Map<String, dynamic> json) {
    return Stay(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      from: json['from'],
      to: json['to'],
      durationMinutes: json['duration_minutes'],
    );
  }
}
