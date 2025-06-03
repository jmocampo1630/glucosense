import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:glucolook/models/glucose_record.model.dart';
import 'package:glucolook/models/patient.model.dart';

class PatientDatabaseServices {
  final DatabaseReference _patientsRef =
      FirebaseDatabase.instance.ref().child('patients');

  Future<String?> addPatient(Patient patient) async {
    try {
      // Get current user's UID
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User not logged in');

      // Add UID to patient
      final patientWithUid = patient.copyWith(
          uid: uid); // You need a copyWith method or set patient.uid = uid

      DatabaseReference dbRef = _patientsRef.push();
      await dbRef.set(patientWithUid.toJson());
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
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User not logged in');

      var event = await _patientsRef.orderByChild('uid').equalTo(uid).once();
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

  Future<Patient?> getPatientById(String id) async {
    try {
      var event = await _patientsRef.child(id).once();
      DataSnapshot snapshot = event.snapshot;
      Map<dynamic, dynamic>? values = snapshot.value as Map<dynamic, dynamic>?;
      if (values != null) {
        return Patient.fromJson(values, id);
      }
      return null; // Return null if no patient found with the given ID
    } catch (e) {
      if (kDebugMode) {
        print('Error getting patient: $e');
      }
      return null; // Return null in case of error
    }
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

  Future<String?> addGlucoseRecordToPatient(
      String patientId, GlucoseRecord glucoseRecord) async {
    try {
      final patientReference = _patientsRef.child(patientId);
      final patientSnapshot = await patientReference.get();
      final patientData = patientSnapshot.value as Map<dynamic, dynamic>;

      // Generate a unique ID for the new glucose record
      String glucoseRecordId = FirebaseDatabase.instance.ref().push().key ?? '';

      // Add the new glucose record with its ID
      glucoseRecord.id = glucoseRecordId;
      Map<String, dynamic> glucoseRecordData = glucoseRecord.toJson();

      // Ensure glucoseRecords is initialized as a mutable map
      Map<String, dynamic> glucoseRecords =
          Map<String, dynamic>.from(patientData['glucose_records'] ?? {});

      glucoseRecords[glucoseRecordId] = glucoseRecordData;

      // Update the patient's glucose records with the new record
      await patientReference.update({'glucose_records': glucoseRecords});

      // Return the ID of the new glucose record
      return glucoseRecordId;
    } catch (e) {
      print('Error adding glucose record to patient: $e');
      return null; // Return null in case of error
    }
  }
}
