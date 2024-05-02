import 'package:firebase_database/firebase_database.dart';
import 'package:glucosense/models/glucose_record.dart';

final DatabaseReference _glucoseRecordsRef =
    FirebaseDatabase.instance.ref().child('glucoseRecords');

Future<void> addGlucoseRecord(GlucoseRecord record) async {
  try {
    await _glucoseRecordsRef.push().set(record.toJson());
  } catch (e) {
    print('Error adding glucose record: $e');
  }
}

Future<List<GlucoseRecord>> getGlucoseRecords() async {
  List<GlucoseRecord> records = [];
  try {
    var event = await _glucoseRecordsRef.once();
    DataSnapshot snapshot = event.snapshot;

    // Cast snapshot.value to Map<dynamic, dynamic>
    Map<dynamic, dynamic>? values = snapshot.value as Map<dynamic, dynamic>?;

    if (values != null) {
      values.forEach((key, value) {
        records.add(GlucoseRecord.fromJson(value));
      });
    }
  } catch (e) {
    print('Error getting glucose records: $e');
  }
  return records;
}

Future<void> updateGlucoseRecord(String id, GlucoseRecord updatedRecord) async {
  try {
    await _glucoseRecordsRef.child(id).update(updatedRecord.toJson());
  } catch (e) {
    print('Error updating glucose record: $e');
  }
}

Future<void> deleteGlucoseRecord(String id) async {
  try {
    await _glucoseRecordsRef.child(id).remove();
  } catch (e) {
    print('Error deleting glucose record: $e');
  }
}
