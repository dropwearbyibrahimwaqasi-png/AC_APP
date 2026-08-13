class Reminder {
  final int id;
  final String description;
  final String? location;
  final DateTime remindAt;
  final String status;
  final String? followUpNote;
  final String? followUpPhotoPath;
  final int? nextReminderId;

  Reminder({
    required this.id,
    required this.description,
    this.location,
    required this.remindAt,
    required this.status,
    this.followUpNote,
    this.followUpPhotoPath,
    this.nextReminderId,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      description: json['description'],
      location: json['location'],
      remindAt: DateTime.parse(json['remind_at']),
      status: json['status'],
      followUpNote: json['follow_up_note'],
      followUpPhotoPath: json['follow_up_photo_path'],
      nextReminderId: json['next_reminder_id'],
    );
  }
}
