import 'package:flutter/material.dart';
import 'package:glucolook/services/notification.services.dart';

class ReminderSettingsWidget extends StatefulWidget {
  const ReminderSettingsWidget({super.key});

  @override
  State<ReminderSettingsWidget> createState() => _ReminderSettingsWidgetState();
}

class _ReminderSettingsWidgetState extends State<ReminderSettingsWidget> {
  bool _isReminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminderSettings();
  }

  Future<void> _loadReminderSettings() async {
    try {
      final settings = await NotificationService.getReminderSettings();
      setState(() {
        _isReminderEnabled = settings['enabled'] as bool;
        _reminderTime = TimeOfDay(
          hour: settings['hour'] as int,
          minute: settings['minute'] as int,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading reminder settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleReminder(bool enabled) async {
    // Don't allow rapid toggling
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (enabled) {
        await NotificationService.scheduleGlucoseReminder(
          hour: _reminderTime.hour,
          minute: _reminderTime.minute,
        );
        setState(() {
          _isReminderEnabled = true;
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Daily glucose reminder enabled! Note: Reminders may be approximate on Android 12+'),
              backgroundColor: Color(0xFF37B5B6),
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        await NotificationService.cancelGlucoseReminder();
        setState(() {
          _isReminderEnabled = false;
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Daily glucose reminder disabled'),
              backgroundColor: Colors.grey,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isReminderEnabled = !enabled; // Revert on error
        _isLoading = false;
      });
      if (mounted) {
        String errorMessage = 'Error updating reminder: ${e.toString()}';
        if (e.toString().contains('MissingPluginException') ||
            e.toString().contains('No implementation found')) {
          errorMessage =
              'Notification feature needs app restart. Please close and reopen the app, then try again.';
        } else if (e.toString().contains('exact_alarms_not_permitted')) {
          errorMessage =
              'Exact alarm permission not granted. Reminders will work but may be less precise.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
            action: e.toString().contains('MissingPluginException') ||
                    e.toString().contains('No implementation found')
                ? SnackBarAction(
                    label: 'Restart App',
                    textColor: Colors.white,
                    onPressed: () {
                      // User should manually restart the app
                    },
                  )
                : null,
          ),
        );
      }
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF37B5B6),
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });

      // If reminder is enabled, reschedule with new time
      if (_isReminderEnabled) {
        try {
          await NotificationService.scheduleGlucoseReminder(
            hour: _reminderTime.hour,
            minute: _reminderTime.minute,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Reminder time updated to ${_reminderTime.format(context)}',
                ),
                backgroundColor: const Color(0xFF37B5B6),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error updating reminder time: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _testNotification() async {
    try {
      await NotificationService.showTestNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test notification sent!'),
            backgroundColor: Color(0xFF37B5B6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage =
            'Error sending test notification: ${e.toString()}';
        if (e.toString().contains('MissingPluginException') ||
            e.toString().contains('No implementation found')) {
          errorMessage =
              'Notification feature needs app restart. Please close and reopen the app.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(
              color: Color(0xFF37B5B6),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.notifications_active,
                  color: Color(0xFF37B5B6),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Daily Reminder',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Color(0xFF37B5B6),
                          strokeWidth: 2,
                        ),
                      )
                    : Switch(
                        value: _isReminderEnabled,
                        onChanged: _toggleReminder,
                        activeColor: const Color(0xFF37B5B6),
                      ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Get reminded to check your glucose level daily',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            if (_isReminderEnabled) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Color(0xFF37B5B6),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Reminder Time:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _selectTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF37B5B6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF37B5B6),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _reminderTime.format(context),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF37B5B6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // const SizedBox(height: 16),
              // Center(
              //   child: TextButton.icon(
              //     onPressed: _testNotification,
              //     icon: const Icon(
              //       Icons.notifications_outlined,
              //       size: 18,
              //       color: Color(0xFF37B5B6),
              //     ),
              //     label: const Text(
              //       'Test Notification',
              //       style: TextStyle(
              //         color: Color(0xFF37B5B6),
              //         fontWeight: FontWeight.w500,
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ],
        ),
      ),
    );
  }
}
