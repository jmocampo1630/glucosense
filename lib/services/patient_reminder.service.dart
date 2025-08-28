import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glucolook/models/patient_reminder.model.dart';
import 'package:glucolook/services/notification.services.dart';

class PatientReminderService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Database reference for patient reminders
  static DatabaseReference get _remindersRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not authenticated');
    }
    return _database.ref().child('users').child(uid).child('patient_reminders');
  }

  // Add a new patient reminder
  static Future<String> addPatientReminder({
    required String patientId,
    required String patientName,
    required String title,
    required DateTime dateTime,
    String? description,
  }) async {
    try {
      final now = DateTime.now();
      final newRef = _remindersRef.push();
      final reminderId = newRef.key!;

      final reminder = PatientReminderModel(
        id: reminderId,
        patientId: patientId,
        patientName: patientName,
        title: title,
        dateTime: dateTime,
        isEnabled: true,
        description: description,
        createdAt: now,
        updatedAt: now,
      );

      await newRef.set(reminder.toJson());

      // Schedule the local notification
      await NotificationService.scheduleOneTimePatientReminder(reminder);

      return reminderId;
    } catch (e) {
      throw Exception('Failed to add patient reminder: $e');
    }
  }

  // Get all reminders for a specific patient
  static Future<List<PatientReminderModel>> getPatientReminders(
      String patientId) async {
    try {
      final snapshot = await _remindersRef.get();

      if (!snapshot.exists) return [];

      final reminders = <PatientReminderModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        final reminderData = Map<String, dynamic>.from(value as Map);
        final reminder = PatientReminderModel.fromJson(reminderData, key);
        // Filter by patient_id in memory
        if (reminder.patientId == patientId) {
          reminders.add(reminder);
        }
      });

      // Sort by date_time
      reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return reminders;
    } catch (e) {
      throw Exception('Failed to get patient reminders: $e');
    }
  }

  // Get all reminders for all patients
  static Future<List<PatientReminderModel>> getAllPatientReminders() async {
    try {
      final snapshot = await _remindersRef.get();

      if (!snapshot.exists) return [];

      final reminders = <PatientReminderModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        final reminderData = Map<String, dynamic>.from(value as Map);
        reminders.add(PatientReminderModel.fromJson(reminderData, key));
      });

      // Sort by date_time
      reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return reminders;
    } catch (e) {
      throw Exception('Failed to get all patient reminders: $e');
    }
  }

  // Update a patient reminder
  static Future<void> updatePatientReminder(
      PatientReminderModel reminder) async {
    try {
      final updatedReminder = reminder.copyWith(updatedAt: DateTime.now());
      await _remindersRef.child(reminder.id).update(updatedReminder.toJson());

      // Cancel the old notification and schedule the new one
      await NotificationService.cancelNotification(reminder.notificationId);
      if (updatedReminder.isEnabled && !updatedReminder.isPast) {
        await NotificationService.scheduleOneTimePatientReminder(
            updatedReminder);
      }
    } catch (e) {
      throw Exception('Failed to update patient reminder: $e');
    }
  }

  // Toggle reminder enabled/disabled status
  static Future<void> toggleReminderStatus(
      String reminderId, bool isEnabled) async {
    try {
      await _remindersRef.child(reminderId).update({
        'is_enabled': isEnabled,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });

      // Handle notification scheduling
      if (isEnabled) {
        // Get the updated reminder and schedule notification
        final snapshot = await _remindersRef.child(reminderId).get();
        if (snapshot.exists) {
          final reminderData = Map<String, dynamic>.from(snapshot.value as Map);
          final reminder =
              PatientReminderModel.fromJson(reminderData, reminderId);
          if (!reminder.isPast) {
            await NotificationService.scheduleOneTimePatientReminder(reminder);
          }
        }
      } else {
        // Cancel the notification
        final notificationId = reminderId.hashCode.abs();
        await NotificationService.cancelNotification(notificationId);
      }
    } catch (e) {
      throw Exception('Failed to toggle reminder status: $e');
    }
  }

  // Delete a patient reminder
  static Future<void> deletePatientReminder(String reminderId) async {
    try {
      // Cancel the notification first
      final notificationId = reminderId.hashCode.abs();
      await NotificationService.cancelNotification(notificationId);

      // Delete from Realtime Database
      await _remindersRef.child(reminderId).remove();
    } catch (e) {
      throw Exception('Failed to delete patient reminder: $e');
    }
  }

  // Delete all reminders for a specific patient
  static Future<void> deleteAllPatientReminders(String patientId) async {
    try {
      final snapshot = await _remindersRef.get();

      if (!snapshot.exists) return;

      final data = snapshot.value as Map<dynamic, dynamic>;
      final updates = <String, dynamic>{};

      data.forEach((key, value) {
        final reminderData = Map<String, dynamic>.from(value as Map);
        final reminder = PatientReminderModel.fromJson(reminderData, key);
        // Filter by patient_id in memory
        if (reminder.patientId == patientId) {
          // Cancel the notification
          NotificationService.cancelNotification(reminder.notificationId);
          // Mark for deletion
          updates[key] = null;
        }
      });

      if (updates.isNotEmpty) {
        await _remindersRef.update(updates);
      }
    } catch (e) {
      throw Exception('Failed to delete all patient reminders: $e');
    }
  }

  // Sync reminders with local notifications
  static Future<void> syncNotifications() async {
    try {
      final reminders = await getAllPatientReminders();

      // Cancel all existing notifications
      await NotificationService.cancelAllNotifications();

      // Schedule enabled reminders that are not in the past
      for (final reminder in reminders) {
        if (reminder.isEnabled && !reminder.isPast) {
          await NotificationService.scheduleOneTimePatientReminder(reminder);
        }
      }
    } catch (e) {
      throw Exception('Failed to sync notifications: $e');
    }
  }

  // Get reminders for today
  static Future<List<PatientReminderModel>> getTodaysReminders() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final allReminders = await getAllPatientReminders();

      return allReminders.where((reminder) {
        return reminder.isEnabled &&
            reminder.dateTime.isAfter(startOfDay) &&
            reminder.dateTime.isBefore(endOfDay);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get today\'s reminders: $e');
    }
  }

  // Get upcoming reminders (next 7 days)
  static Future<List<PatientReminderModel>> getUpcomingReminders() async {
    try {
      final now = DateTime.now();
      final nextWeek = now.add(const Duration(days: 7));

      final allReminders = await getAllPatientReminders();

      return allReminders.where((reminder) {
        return reminder.isEnabled &&
            reminder.dateTime.isAfter(now) &&
            reminder.dateTime.isBefore(nextWeek);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get upcoming reminders: $e');
    }
  }

  // Listen to reminders changes in real-time
  static Stream<List<PatientReminderModel>> getPatientRemindersStream(
      String patientId) {
    return _remindersRef.onValue.map((event) {
      if (!event.snapshot.exists) return <PatientReminderModel>[];

      final reminders = <PatientReminderModel>[];
      final data = event.snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        final reminderData = Map<String, dynamic>.from(value as Map);
        final reminder = PatientReminderModel.fromJson(reminderData, key);
        // Filter by patient_id in memory
        if (reminder.patientId == patientId) {
          reminders.add(reminder);
        }
      });

      // Sort by date_time
      reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return reminders;
    });
  }

  // Listen to all reminders changes in real-time
  static Stream<List<PatientReminderModel>> getAllPatientRemindersStream() {
    return _remindersRef.onValue.map((event) {
      if (!event.snapshot.exists) return <PatientReminderModel>[];

      final reminders = <PatientReminderModel>[];
      final data = event.snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        final reminderData = Map<String, dynamic>.from(value as Map);
        reminders.add(PatientReminderModel.fromJson(reminderData, key));
      });

      // Sort by date_time
      reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return reminders;
    });
  }
}
