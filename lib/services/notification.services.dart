import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static const String _reminderEnabledKey = 'glucose_reminder_enabled';
  static const String _reminderTimeKey = 'glucose_reminder_time';
  static const int _reminderNotificationId = 1001;

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
    // Handle notification tap - could navigate to camera page
    // TODO: Add navigation logic if needed
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
        'This is a test notification for glucose reminder',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Test notifications for debugging',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFF37B5B6),
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } on MissingPluginException catch (e) {
      throw Exception(
          'Notification feature is not available. Please restart the app. Error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to show test notification: ${e.toString()}');
    }
  }
}
