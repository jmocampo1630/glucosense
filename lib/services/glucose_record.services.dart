import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:glucolook/models/glucose_record.model.dart';

class GlucoseRecordServices {
  final DatabaseReference _glucoseRecordsRef =
      FirebaseDatabase.instance.ref().child('glucoseRecords');

  Future<String?> addGlucoseRecord(GlucoseRecord record) async {
    try {
      DatabaseReference dbRef = _glucoseRecordsRef.push();
      await dbRef.set(record.toJson());
      return dbRef.key;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding glucose record: $e');
      }
    }
    return null;
  }

  Future<List<GlucoseRecord>> getGlucoseRecords() async {
    List<GlucoseRecord> records = [];
    try {
      var event = await _glucoseRecordsRef.once();
      DataSnapshot snapshot = event.snapshot;

      Map<dynamic, dynamic>? values = snapshot.value as Map<dynamic, dynamic>?;
      if (values != null) {
        values.forEach((key, value) {
          records.add(GlucoseRecord.fromJson(value, key)); // Pass the key (ID)
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting glucose records: $e');
      }
    }
    return records;
  }

  Future<void> updateGlucoseRecord(
      String id, GlucoseRecord updatedRecord) async {
    try {
      await _glucoseRecordsRef.child(id).update(updatedRecord.toJson());
    } catch (e) {
      if (kDebugMode) {
        print('Error updating glucose record: $e');
      }
    }
  }

  Future<void> deleteGlucoseRecord(String id) async {
    try {
      await _glucoseRecordsRef.child(id).remove();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting glucose record: $e');
      }
    }
  }
}
