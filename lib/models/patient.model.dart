import 'package:glucolook/models/glucose_record.model.dart';

class Patient {
  String id;
  final String? uid;
  final String name;
  final String gender;
  final DateTime dateOfBirth;
  final List<GlucoseRecord> glucoseRecords;

  Patient({
    required this.id,
    this.uid,
    required this.name,
    required this.gender,
    required this.dateOfBirth,
    required this.glucoseRecords,
  });

  factory Patient.fromJson(Map<dynamic, dynamic> json, String id) {
    List<GlucoseRecord> glucoseRecords = [];
    if (json['glucose_records'] != null) {
      if (json['glucose_records'] is List) {
        // If stored as a List
        for (var recordJson in json['glucose_records']) {
          glucoseRecords.add(GlucoseRecord.fromJson(recordJson, ''));
        }
      } else if (json['glucose_records'] is Map) {
        // If stored as a Map
        (json['glucose_records'] as Map).forEach((key, value) {
          glucoseRecords.add(GlucoseRecord.fromJson(value, key));
        });
      }
    }
    return Patient(
      id: id,
      uid: json['uid'],
      name: json['name'],
      gender: json['gender'],
      dateOfBirth: DateTime.parse(json['date_of_birth']).toLocal(),
      glucoseRecords: glucoseRecords,
    );
  }

  Map<String, dynamic> toJson() {
    List<dynamic> glucoseRecordsJson = [];
    for (var record in glucoseRecords) {
      glucoseRecordsJson.add(record.toJson());
    }
    return {
      'uid': uid,
      'name': name,
      'gender': gender,
      'date_of_birth': dateOfBirth.toIso8601String(),
      'glucose_records': glucoseRecordsJson,
    };
  }

  Patient copyWith({
    String? id,
    String? uid,
    String? name,
    String? gender,
    DateTime? dateOfBirth,
    List<GlucoseRecord>? glucoseRecords,
  }) {
    return Patient(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      glucoseRecords: glucoseRecords ?? this.glucoseRecords,
    );
  }
}
