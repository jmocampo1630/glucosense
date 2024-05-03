import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:glucosense/models/glucose_record.model.dart';
import 'package:glucosense/models/patient.model.dart';

class PatientDatabaseServices {
  final DatabaseReference _patientsRef =
      FirebaseDatabase.instance.ref().child('patients');

  Future<String?> addPatient(Patient patient) async {
    try {
      DatabaseReference dbRef = _patientsRef.push();
      await dbRef.set(patient.toJson());
      return dbRef.key;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding glucose record: $e');
      }
    }
    return null;
  }

  Future<List<Patient>> getPatients() async {
    List<Patient> records = [];
    try {
      var event = await _patientsRef.once();
      DataSnapshot snapshot = event.snapshot;

      Map<dynamic, dynamic>? values = snapshot.value as Map<dynamic, dynamic>?;
      if (values != null) {
        values.forEach((key, value) {
          records.add(Patient.fromJson(value, key)); // Pass the key (ID)
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting glucose records: $e');
      }
    }
    return records;
  }

  Future<void> updatePatient(String id, Patient updatedPatient) async {
    try {
      await _patientsRef.child(id).update(updatedPatient.toJson());
    } catch (e) {
      if (kDebugMode) {
        print('Error updating glucose record: $e');
      }
    }
  }

  Future<void> deletePatient(String id) async {
    try {
      await _patientsRef.child(id).remove();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting glucose record: $e');
      }
    }
  }

  Future<void> addGlucoseRecordToPatient(
      String patientId, GlucoseRecord glucoseRecord) async {
    final patientReference = _patientsRef.child(patientId);
    final patientSnapshot = await patientReference.get();
    final patientData = patientSnapshot.value as Map<dynamic, dynamic>;
    List<dynamic> glucoseRecords = patientData['glucose_records'] ?? [];
    glucoseRecords.add(glucoseRecord.toJson());
    await patientReference.update({'glucose_records': glucoseRecords});
  }
}
