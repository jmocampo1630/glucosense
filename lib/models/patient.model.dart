import 'package:glucosense/models/glucose_record.model.dart';

class Patient {
  String id;
  final String name;
  final String gender;
  final DateTime dateOfBirth;
  final List<GlucoseRecord> glucoseRecords;

  Patient({
    required this.id,
    required this.name,
    required this.gender,
    required this.dateOfBirth,
    required this.glucoseRecords,
  });

  factory Patient.fromJson(Map<dynamic, dynamic> json, String id) {
    List<GlucoseRecord> glucoseRecords = [];
    if (json['glucose_records'] != null) {
      json['glucose_records'].forEach((recordJson) {
        GlucoseRecord record = GlucoseRecord.fromJson(recordJson, '');
        glucoseRecords.add(record);
      });
    }
    return Patient(
      id: id,
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
      'name': name,
      'gender': gender,
      'date_of_birth': dateOfBirth.toIso8601String(),
      'glucose_records': glucoseRecordsJson,
    };
  }
}
