import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class GlucoseRecordServices {
  final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();

  Future<void> deleteGlucoseRecord(
      String patientId, String glucoseRecordId) async {
    try {
      await databaseReference
          .child('patients/$patientId/glucose_records/$glucoseRecordId')
          .remove();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting glucose record: $e');
      }
    }
  }
}
