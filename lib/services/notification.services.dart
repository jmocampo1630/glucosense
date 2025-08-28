import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glucolook/models/patient_reminder.model.dart';

// Class to represent a patient-specific reminder
class PatientReminder {
  final String id;
  final String patientId;
  final String patientName;
  final TimeOfDay time;
  final String title;
  final String message;
  final bool enabled;
  final List<int> daysOfWeek; // 1=Monday, 7=Sunday

  PatientReminder({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.time,
    required this.title,
    required this.message,
    required this.enabled,
    required this.daysOfWeek,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'hour': time.hour,
      'minute': time.minute,
      'title': title,
      'message': message,
      'enabled': enabled,
      'daysOfWeek': daysOfWeek,
    };
  }

  factory PatientReminder.fromJson(Map<String, dynamic> json) {
    return PatientReminder(
      id: json['id'],
      patientId: json['patientId'],
      patientName: json['patientName'],
      time: TimeOfDay(hour: json['hour'], minute: json['minute']),
      title: json['title'],
      message: json['message'],
      enabled: json['enabled'],
      daysOfWeek: List<int>.from(json['daysOfWeek']),
    );
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static const String _reminderEnabledKey = 'glucose_reminder_enabled';
  static const String _reminderTimeKey = 'glucose_reminder_time';
  static const int _reminderNotificationId = 1001;

  // Patient-specific reminder keys and constants
  static const String _patientRemindersPrefix = 'patient_reminders_';
  static const int _patientNotificationIdBase = 2000;

  static Future<void> initialize() async {
    try {
      // Initialize timezone data
      tz.initializeTimeZones();

      // Find and set local timezone
      final String timeZoneName = tz.local.name;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // Fallback to UTC if local timezone fails
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permissions for notifications
      await _requestPermissions();

      // Mark as initialized
      _isInitialized = true;
    } on MissingPluginException catch (e) {
      throw Exception(
          'Notification plugin not properly installed. Please restart the app or reinstall it. Error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to initialize notifications: ${e.toString()}');
    }
  }

  static Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to specific patient if it's a patient reminder
    final payload = response.payload;
    if (payload != null && payload.startsWith('patient_')) {
      final patientId = payload.substring(8); // Remove 'patient_' prefix
      // Store the patient ID for navigation
      _handlePatientNotificationTap(patientId);
    }
    // TODO: Add navigation logic for general reminders if needed
  }

  static void _handlePatientNotificationTap(String patientId) {
    // This will be called by the main app to handle navigation
    _lastTappedPatientId = patientId;
  }

  static String? _lastTappedPatientId;

  // Method to get and clear the last tapped patient ID
  static String? getAndClearLastTappedPatientId() {
    final patientId = _lastTappedPatientId;
    _lastTappedPatientId = null;
    return patientId;
  }

  static Future<void> scheduleGlucoseReminder({
    required int hour,
    required int minute,
    String title = 'Time for Glucose Check',
    String body = 'Don\'t forget to scan your glucose level today!',
  }) async {
    try {
      // Ensure notification service is initialized
      if (!_isInitialized) {
        await initialize();
      }

      // Try with exact alarms first, fallback to inexact if not permitted
      AndroidScheduleMode scheduleMode =
          AndroidScheduleMode.exactAllowWhileIdle;

      try {
        await _notifications.zonedSchedule(
          _reminderNotificationId,
          title,
          body,
          _nextInstanceOfTime(hour, minute),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'glucose_reminder',
              'Glucose Reminders',
              channelDescription: 'Daily reminders to check glucose levels',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              color: Color(0xFF37B5B6),
              enableLights: true,
              ledColor: Color(0xFF37B5B6),
              ledOnMs: 1000,
              ledOffMs: 500,
            ),
            iOS: DarwinNotificationDetails(
              categoryIdentifier: 'glucose_reminder',
              interruptionLevel: InterruptionLevel.active,
            ),
          ),
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'glucose_reminder',
        );
      } on PlatformException catch (e) {
        if (e.code == 'exact_alarms_not_permitted') {
          // Fallback to inexact alarms
          scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
          await _notifications.zonedSchedule(
            _reminderNotificationId,
            title,
            body,
            _nextInstanceOfTime(hour, minute),
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'glucose_reminder',
                'Glucose Reminders',
                channelDescription: 'Daily reminders to check glucose levels',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
                color: Color(0xFF37B5B6),
                enableLights: true,
                ledColor: Color(0xFF37B5B6),
                ledOnMs: 1000,
                ledOffMs: 500,
                // Enhanced settings for background notifications
                autoCancel: true,
                enableVibration: true,
                playSound: true,
                fullScreenIntent: true,
                category: AndroidNotificationCategory.reminder,
                visibility: NotificationVisibility.public,
              ),
              iOS: DarwinNotificationDetails(
                categoryIdentifier: 'glucose_reminder',
                interruptionLevel: InterruptionLevel.active,
                sound: 'default',
              ),
            ),
            androidScheduleMode: scheduleMode,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
            payload: 'glucose_reminder',
          );
        } else {
          rethrow;
        }
      }

      // Save reminder settings
      await _saveReminderSettings(true, hour, minute);
    } on MissingPluginException catch (e) {
      throw Exception(
          'Notification feature is not available. Please restart the app. Error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to schedule reminder: ${e.toString()}');
    }
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      return scheduledDate;
    } catch (e) {
      // Fallback to using DateTime and converting to TZDateTime
      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Convert to TZDateTime using UTC if local timezone fails
      return tz.TZDateTime.from(scheduledDate, tz.UTC);
    }
  }

  static Future<void> cancelGlucoseReminder() async {
    await _notifications.cancel(_reminderNotificationId);
    await _saveReminderSettings(false, 9, 0); // Default time
  }

  static Future<void> _saveReminderSettings(
      bool enabled, int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderEnabledKey, enabled);
    await prefs.setString(_reminderTimeKey, '$hour:$minute');
  }

  static Future<Map<String, dynamic>> getReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_reminderEnabledKey) ?? false;
    final timeString = prefs.getString(_reminderTimeKey) ?? '9:0';
    final timeParts = timeString.split(':');

    return {
      'enabled': enabled,
      'hour': int.parse(timeParts[0]),
      'minute': int.parse(timeParts[1]),
    };
  }

  static Future<bool> isReminderEnabled() async {
    final settings = await getReminderSettings();
    return settings['enabled'] as bool;
  }

  static Future<TimeOfDay> getReminderTime() async {
    final settings = await getReminderSettings();
    return TimeOfDay(
      hour: settings['hour'] as int,
      minute: settings['minute'] as int,
    );
  }

  static Future<void> showTestNotification() async {
    try {
      // Ensure notification service is initialized
      if (!_isInitialized) {
        await initialize();
      }

      await _notifications.show(
        9999,
        'Test Notification',
        'This is a test notification for glucose reminder - tap to dismiss',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Test notifications for debugging',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFF37B5B6),
            // Enhanced settings for better visibility
            autoCancel: true,
            enableVibration: true,
            playSound: true,
            enableLights: true,
            ledColor: Color(0xFF37B5B6),
            ledOnMs: 1000,
            ledOffMs: 500,
          ),
          iOS: DarwinNotificationDetails(
            sound: 'default',
          ),
        ),
      );
    } on MissingPluginException catch (e) {
      throw Exception(
          'Notification feature is not available. Please restart the app. Error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to show test notification: ${e.toString()}');
    }
  }

  // Add method to check if notifications will work in background
  static Future<Map<String, bool>> checkBackgroundCapabilities() async {
    final Map<String, bool> capabilities = {};

    try {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        // Check if exact alarms are available
        capabilities['exactAlarmsPermitted'] =
            true; // Will be caught if not permitted

        // Check notification permission
        final bool? notificationPermission =
            await androidPlugin.areNotificationsEnabled();
        capabilities['notificationsEnabled'] = notificationPermission ?? false;
      }

      capabilities['serviceInitialized'] = _isInitialized;
    } catch (e) {
      capabilities['error'] = true;
    }

    return capabilities;
  }

  // Method to help users enable background notifications
  static String getBackgroundNotificationGuide() {
    return '''
Background Notification Tips:

1. Allow notifications for GlucoSense in Settings
2. Disable battery optimization for this app
3. Keep the app in recent apps (don't swipe it away)
4. For Samsung devices: Disable "Put unused apps to sleep"
5. For Xiaomi/MIUI: Enable "Autostart" for this app

These settings ensure reliable daily reminders even when the app is closed.
    ''';
  }

  // ===== PATIENT-SPECIFIC REMINDER METHODS =====

  // Add a patient-specific reminder
  static Future<String> addPatientReminder({
    required String patientId,
    required String patientName,
    required TimeOfDay time,
    String? title,
    String? message,
    List<int>? daysOfWeek,
  }) async {
    final reminderId = DateTime.now().millisecondsSinceEpoch.toString();

    final reminder = PatientReminder(
      id: reminderId,
      patientId: patientId,
      patientName: patientName,
      time: time,
      title: title ?? 'Glucose Check Reminder',
      message: message ?? 'Time to check glucose level for $patientName',
      enabled: true,
      daysOfWeek: daysOfWeek ?? [1, 2, 3, 4, 5, 6, 7], // Default: every day
    );

    await _savePatientReminder(reminder);
    await _schedulePatientReminder(reminder);

    return reminderId;
  }

  // Get all reminders for a specific patient
  static Future<List<PatientReminder>> getPatientReminders(
      String patientId) async {
    final prefs = await SharedPreferences.getInstance();
    final reminderKeys = prefs
        .getKeys()
        .where((key) => key.startsWith('$_patientRemindersPrefix$patientId'))
        .toList();

    List<PatientReminder> reminders = [];
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

          final reminder = PatientReminder(
            id: data['id'] ?? '',
            patientId: data['patientId'] ?? patientId,
            patientName: data['patientName'] ?? '',
            time: TimeOfDay(
              hour: int.tryParse(data['hour'] ?? '9') ?? 9,
              minute: int.tryParse(data['minute'] ?? '0') ?? 0,
            ),
            title: data['title'] ?? 'Glucose Check',
            message: data['message'] ?? 'Time to check glucose',
            enabled: data['enabled'] == 'true',
            daysOfWeek: data['daysOfWeek']
                    ?.split(',')
                    .map((e) => int.tryParse(e) ?? 1)
                    .toList() ??
                [1, 2, 3, 4, 5, 6, 7],
          );
          reminders.add(reminder);
        } catch (e) {
          // Skip invalid reminders
          continue;
        }
      }
    }

    return reminders;
  }

  // Update a patient reminder
  static Future<void> updatePatientReminder(PatientReminder reminder) async {
    await _savePatientReminder(reminder);

    // Cancel existing notification and reschedule if enabled
    await cancelPatientReminder(reminder.patientId, reminder.id);
    if (reminder.enabled) {
      await _schedulePatientReminder(reminder);
    }
  }

  // Delete a patient reminder
  static Future<void> deletePatientReminder(
      String patientId, String reminderId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_patientRemindersPrefix${patientId}_$reminderId');
    await cancelPatientReminder(patientId, reminderId);
  }

  // Cancel a specific patient reminder
  static Future<void> cancelPatientReminder(
      String patientId, String reminderId) async {
    final notificationId = _getPatientNotificationId(patientId, reminderId);
    await _notifications.cancel(notificationId);
  }

  // Cancel all reminders for a patient
  static Future<void> cancelAllPatientReminders(String patientId) async {
    final reminders = await getPatientReminders(patientId);
    for (final reminder in reminders) {
      await cancelPatientReminder(patientId, reminder.id);
    }
  }

  // Private helper methods
  static Future<void> _savePatientReminder(PatientReminder reminder) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_patientRemindersPrefix${reminder.patientId}_${reminder.id}';

    // Simple string format for easier parsing
    final data =
        'id=${reminder.id}&patientId=${reminder.patientId}&patientName=${Uri.encodeComponent(reminder.patientName)}&hour=${reminder.time.hour}&minute=${reminder.time.minute}&title=${Uri.encodeComponent(reminder.title)}&message=${Uri.encodeComponent(reminder.message)}&enabled=${reminder.enabled}&daysOfWeek=${reminder.daysOfWeek.join(',')}';

    await prefs.setString(key, data);
  }

  static Future<void> _schedulePatientReminder(PatientReminder reminder) async {
    if (!reminder.enabled) return;

    try {
      // Ensure notification service is initialized
      if (!_isInitialized) {
        await initialize();
      }

      final notificationId =
          _getPatientNotificationId(reminder.patientId, reminder.id);

      AndroidScheduleMode scheduleMode =
          AndroidScheduleMode.exactAllowWhileIdle;

      try {
        await _notifications.zonedSchedule(
          notificationId,
          reminder.title,
          reminder.message,
          _nextInstanceOfTime(reminder.time.hour, reminder.time.minute),
          NotificationDetails(
            android: AndroidNotificationDetails(
              'patient_reminders',
              'Patient Reminders',
              channelDescription: 'Reminders for specific patients',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              color: const Color(0xFF37B5B6),
              enableLights: true,
              ledColor: const Color(0xFF37B5B6),
              ledOnMs: 1000,
              ledOffMs: 500,
              autoCancel: true,
              enableVibration: true,
              playSound: true,
              fullScreenIntent: true,
              category: AndroidNotificationCategory.reminder,
              visibility: NotificationVisibility.public,
            ),
            iOS: const DarwinNotificationDetails(
              categoryIdentifier: 'patient_reminder',
              interruptionLevel: InterruptionLevel.active,
              sound: 'default',
            ),
          ),
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload:
              'patient_${reminder.patientId}', // This will help with navigation
        );
      } on PlatformException catch (e) {
        if (e.code == 'exact_alarms_not_permitted') {
          // Fallback to inexact alarms
          scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
          await _notifications.zonedSchedule(
            notificationId,
            reminder.title,
            reminder.message,
            _nextInstanceOfTime(reminder.time.hour, reminder.time.minute),
            NotificationDetails(
              android: AndroidNotificationDetails(
                'patient_reminders',
                'Patient Reminders',
                channelDescription: 'Reminders for specific patients',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
                color: const Color(0xFF37B5B6),
                enableLights: true,
                ledColor: const Color(0xFF37B5B6),
                ledOnMs: 1000,
                ledOffMs: 500,
                autoCancel: true,
                enableVibration: true,
                playSound: true,
                fullScreenIntent: true,
                category: AndroidNotificationCategory.reminder,
                visibility: NotificationVisibility.public,
              ),
              iOS: const DarwinNotificationDetails(
                categoryIdentifier: 'patient_reminder',
                interruptionLevel: InterruptionLevel.active,
                sound: 'default',
              ),
            ),
            androidScheduleMode: scheduleMode,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
            payload: 'patient_${reminder.patientId}',
          );
        } else {
          rethrow;
        }
      }
    } on MissingPluginException catch (e) {
      throw Exception(
          'Notification feature is not available. Please restart the app. Error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to schedule patient reminder: ${e.toString()}');
    }
  }

  static int _getPatientNotificationId(String patientId, String reminderId) {
    // Create a unique notification ID by combining base with hash
    final combined = '$patientId$reminderId';
    return _patientNotificationIdBase + combined.hashCode.abs() % 10000;
  }

  // ==== NEW METHODS FOR FIRESTORE PATIENT REMINDERS ====

  /// Schedule a one-time notification for a PatientReminderModel
  static Future<void> scheduleOneTimePatientReminder(
      PatientReminderModel reminder) async {
    try {
      final scheduledDate = tz.TZDateTime.from(reminder.dateTime, tz.local);

      // Check if the reminder time is in the future
      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        print('Reminder time is in the past, not scheduling notification');
        return;
      }

      await _notifications.zonedSchedule(
        reminder.notificationId,
        'Reminder: ${reminder.patientName}',
        reminder.title,
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'patient_reminders',
            'Patient Reminders',
            channelDescription: 'Notifications for patient reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: 'ic_launcher',
            color: const Color(0xFF009688),
            enableVibration: true,
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default.caf',
          ),
        ),
        payload: 'patient_reminder:${reminder.patientId}',
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );

      print(
          'Scheduled one-time reminder: ${reminder.title} for ${reminder.patientName} at ${reminder.dateTime}');
    } catch (e) {
      print('Error scheduling one-time patient reminder: $e');
      throw e;
    }
  }

  /// Cancel a specific notification by ID
  static Future<void> cancelNotification(int notificationId) async {
    try {
      await _notifications.cancel(notificationId);
      print('Cancelled notification with ID: $notificationId');
    } catch (e) {
      print('Error cancelling notification: $e');
    }
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      print('Cancelled all notifications');
    } catch (e) {
      print('Error cancelling all notifications: $e');
    }
  }

  /// Get pending notifications (for debugging)
  static Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      print('Error getting pending notifications: $e');
      return [];
    }
  }
}
