import 'package:shared_preferences/shared_preferences.dart';
import 'package:glucolook/services/patient_reminder.service.dart';
import 'package:glucolook/services/notification.services.dart';
import 'package:flutter/material.dart';

class ReminderMigrationService {
  static const String _migrationKey = 'reminders_migrated_to_realtime_db';
  static const String _patientRemindersPrefix = 'patient_reminder_';

  /// Check if migration has already been completed
  static Future<bool> isMigrationCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_migrationKey) ?? false;
  }

  /// Mark migration as completed
  static Future<void> markMigrationCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_migrationKey, true);
  }

  /// Get all existing patient reminders from SharedPreferences
  static Future<List<Map<String, dynamic>>> getExistingReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final reminderKeys = prefs
        .getKeys()
        .where((key) => key.startsWith(_patientRemindersPrefix))
        .toList();

    List<Map<String, dynamic>> reminders = [];
    for (String key in reminderKeys) {
      final dataString = prefs.getString(key);
      if (dataString != null) {
        try {
          // Parse the URL-encoded data
          final data = <String, String>{};
          for (final pair in dataString.split('&')) {
            final parts = pair.split('=');
            if (parts.length == 2) {
              data[parts[0]] = Uri.decodeComponent(parts[1]);
            }
          }

          // Convert old format to new format
          if (data.containsKey('patientId') &&
              data.containsKey('patientName')) {
            final oldReminder = PatientReminder.fromJson(data);
            reminders.add({
              'patientId': oldReminder.patientId,
              'patientName': oldReminder.patientName,
              'title': oldReminder.title,
              'message': oldReminder.message,
              'time': oldReminder.time,
              'enabled': oldReminder.enabled,
              'daysOfWeek': oldReminder.daysOfWeek,
            });
          }
        } catch (e) {
          print('Error parsing reminder data: $e');
        }
      }
    }

    return reminders;
  }

  /// Migrate all existing reminders to Firestore
  static Future<int> migrateRemindersToFirestore() async {
    try {
      final existingReminders = await getExistingReminders();
      int migratedCount = 0;

      for (final reminderData in existingReminders) {
        try {
          // Convert recurring reminders to one-time reminders for the next occurrence
          final nextOccurrence = _getNextOccurrence(
            reminderData['time'] as TimeOfDay,
            reminderData['daysOfWeek'] as List<int>,
          );

          if (nextOccurrence != null) {
            await PatientReminderService.addPatientReminder(
              patientId: reminderData['patientId'],
              patientName: reminderData['patientName'],
              title: reminderData['title'] ?? 'Reminder',
              dateTime: nextOccurrence,
              description: reminderData['message'],
            );
            migratedCount++;
          }
        } catch (e) {
          print('Error migrating individual reminder: $e');
        }
      }

      if (migratedCount > 0) {
        await markMigrationCompleted();
        await _clearOldReminders();
      }

      return migratedCount;
    } catch (e) {
      print('Error during migration: $e');
      return 0;
    }
  }

  /// Clear old reminders from SharedPreferences
  static Future<void> _clearOldReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final reminderKeys = prefs
        .getKeys()
        .where((key) => key.startsWith(_patientRemindersPrefix))
        .toList();

    for (final key in reminderKeys) {
      await prefs.remove(key);
    }
  }

  /// Get the next occurrence of a recurring reminder
  static DateTime? _getNextOccurrence(TimeOfDay time, List<int> daysOfWeek) {
    if (daysOfWeek.isEmpty) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Sort days of week
    final sortedDays = List<int>.from(daysOfWeek)..sort();

    // Try to find next occurrence in the current week
    for (int i = 0; i < 7; i++) {
      final checkDate = today.add(Duration(days: i));
      final dayOfWeek = checkDate.weekday; // 1=Monday, 7=Sunday

      if (sortedDays.contains(dayOfWeek)) {
        final scheduledTime = DateTime(
          checkDate.year,
          checkDate.month,
          checkDate.day,
          time.hour,
          time.minute,
        );

        // If it's today, make sure the time hasn't passed
        if (i == 0 && scheduledTime.isBefore(now)) {
          continue;
        }

        return scheduledTime;
      }
    }

    // If no occurrence found in current week, find first occurrence in next week
    for (int day in sortedDays) {
      final daysToAdd = (day - today.weekday + 7) % 7;
      if (daysToAdd == 0) continue; // Already checked today

      final nextDate = today.add(Duration(days: daysToAdd + 7));
      return DateTime(
        nextDate.year,
        nextDate.month,
        nextDate.day,
        time.hour,
        time.minute,
      );
    }

    return null;
  }

  /// Show migration dialog to user
  static Future<bool> showMigrationDialog(BuildContext context) async {
    final existingReminders = await getExistingReminders();

    if (existingReminders.isEmpty) {
      await markMigrationCompleted();
      return false;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Migrate Reminders'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We found ${existingReminders.length} existing reminder(s) on this device.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Would you like to migrate them to Firebase Realtime Database so you can access them on all your devices?',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700], size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Migration Details:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Recurring reminders will be converted to one-time reminders for their next occurrence',
                    style: TextStyle(fontSize: 12),
                  ),
                  const Text(
                    '• Original local reminders will be safely removed',
                    style: TextStyle(fontSize: 12),
                  ),
                  const Text(
                    '• You can create new reminders after migration',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await markMigrationCompleted();
              Navigator.pop(context, false);
            },
            child: const Text('Skip Migration'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Migrate Reminders'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Perform migration with progress indicator
  static Future<void> performMigrationWithProgress(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Migrating reminders to cloud...'),
          ],
        ),
      ),
    );

    try {
      final migratedCount = await migrateRemindersToFirestore();

      if (context.mounted) {
        Navigator.pop(context); // Close progress dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              migratedCount > 0
                  ? 'Successfully migrated $migratedCount reminder(s)'
                  : 'No reminders to migrate',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close progress dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Migration failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
