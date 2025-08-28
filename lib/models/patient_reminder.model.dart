class PatientReminderModel {
  String id;
  final String patientId;
  final String patientName;
  final String title;
  final DateTime dateTime;
  final bool isEnabled;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  PatientReminderModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.title,
    required this.dateTime,
    required this.isEnabled,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PatientReminderModel.fromJson(Map<String, dynamic> json, String id) {
    return PatientReminderModel(
      id: id,
      patientId: json['patient_id'] ?? '',
      patientName: json['patient_name'] ?? '',
      title: json['title'] ?? '',
      dateTime: DateTime.fromMillisecondsSinceEpoch(json['date_time'] ?? 0),
      isEnabled: json['is_enabled'] ?? true,
      description: json['description'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updated_at'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'patient_name': patientName,
      'title': title,
      'date_time': dateTime.millisecondsSinceEpoch,
      'is_enabled': isEnabled,
      'description': description,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  PatientReminderModel copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? title,
    DateTime? dateTime,
    bool? isEnabled,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PatientReminderModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      isEnabled: isEnabled ?? this.isEnabled,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Generate a unique notification ID for this reminder
  int get notificationId {
    return id.hashCode.abs();
  }

  // Check if the reminder is in the past
  bool get isPast {
    return dateTime.isBefore(DateTime.now());
  }

  // Check if the reminder is today
  bool get isToday {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  // Format the reminder time for display
  String get formattedTime {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }

  // Format the reminder date for display
  String get formattedDate {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }
}
