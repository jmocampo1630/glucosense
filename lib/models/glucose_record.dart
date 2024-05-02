import 'dart:ui';
import 'package:firebase_database/firebase_database.dart';

class GlucoseRecord {
  final String name;
  final String description;
  final DateTime date;
  final Color color;
  late DatabaseReference _id;

  GlucoseRecord({
    required this.name,
    required this.description,
    required this.date,
    required this.color,
  });
  void setId(DatabaseReference id) {
    _id = id;
  }

  GlucoseRecord.fromJson(Map<dynamic, dynamic> json)
      : name = json['name'],
        description = json['description'],
        date = DateTime.parse(json['date']),
        color = Color(json['color']);

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'date': date.toIso8601String(), // Convert DateTime to ISO 8601 string
      'color': color.value,
    };
  }
}
