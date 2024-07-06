import 'dart:ui';

class GlucoseRecord {
  final String name;
  final double value;
  final String description;
  final DateTime date;
  final Color color;
  String id;

  GlucoseRecord({
    required this.id,
    required this.name,
    required this.value,
    required this.description,
    required this.date,
    required this.color,
  });

  factory GlucoseRecord.fromJson(Map<dynamic, dynamic> json, String id) {
    return GlucoseRecord(
      id: id,
      name: json['name'],
      value: json['value'].toDouble(),
      description: json['description'],
      date: DateTime.parse(json['date']).toLocal(),
      color: Color(json['color']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'description': description,
      'date': date.toIso8601String(), // Convert DateTime to ISO 8601 string
      'color': color.value,
      'id': id,
    };
  }
}
