import 'package:flutter/material.dart';
import 'package:glucolook/services/notification.services.dart';

class PatientRemindersWidget extends StatefulWidget {
  final String patientId;
  final String patientName;

  const PatientRemindersWidget({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientRemindersWidget> createState() => _PatientRemindersWidgetState();
}

class _PatientRemindersWidgetState extends State<PatientRemindersWidget> {
  List<PatientReminder> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reminders =
          await NotificationService.getPatientReminders(widget.patientId);
      setState(() {
        _reminders = reminders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading reminders: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addReminder() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
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

    if (time != null) {
      await _showReminderDialog(time: time);
    }
  }

  Future<void> _showReminderDialog({
    TimeOfDay? time,
    PatientReminder? existingReminder,
  }) async {
    final titleController = TextEditingController(
      text: existingReminder?.title ?? 'Glucose Check Reminder',
    );
    final messageController = TextEditingController(
      text: existingReminder?.message ??
          'Time to check glucose level for ${widget.patientName}',
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(existingReminder == null ? 'Add Reminder' : 'Edit Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.access_time, color: Color(0xFF37B5B6)),
              title: const Text('Time'),
              subtitle: Text((time ??
                      existingReminder?.time ??
                      const TimeOfDay(hour: 9, minute: 0))
                  .format(context)),
              onTap: () async {
                final newTime = await showTimePicker(
                  context: context,
                  initialTime: time ??
                      existingReminder?.time ??
                      const TimeOfDay(hour: 9, minute: 0),
                );
                if (newTime != null) {
                  Navigator.of(context).pop({
                    'time': newTime,
                    'title': titleController.text,
                    'message': messageController.text,
                    'action': 'time_changed',
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop({
                'time': time ?? existingReminder?.time,
                'title': titleController.text,
                'message': messageController.text,
                'action': 'save',
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF37B5B6),
              foregroundColor: Colors.white,
            ),
            child: Text(existingReminder == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      if (result['action'] == 'time_changed') {
        await _showReminderDialog(
          time: result['time'],
          existingReminder: existingReminder,
        );
      } else if (result['action'] == 'save') {
        await _saveReminder(
          time: result['time'],
          title: result['title'],
          message: result['message'],
          existingReminder: existingReminder,
        );
      }
    }
  }

  Future<void> _saveReminder({
    required TimeOfDay time,
    required String title,
    required String message,
    PatientReminder? existingReminder,
  }) async {
    try {
      if (existingReminder == null) {
        // Add new reminder
        await NotificationService.addPatientReminder(
          patientId: widget.patientId,
          patientName: widget.patientName,
          time: time,
          title: title.isNotEmpty ? title : 'Glucose Check Reminder',
          message: message.isNotEmpty
              ? message
              : 'Time to check glucose level for ${widget.patientName}',
        );
      } else {
        // Update existing reminder
        final updatedReminder = PatientReminder(
          id: existingReminder.id,
          patientId: existingReminder.patientId,
          patientName: existingReminder.patientName,
          time: time,
          title: title.isNotEmpty ? title : 'Glucose Check Reminder',
          message: message.isNotEmpty
              ? message
              : 'Time to check glucose level for ${widget.patientName}',
          enabled: existingReminder.enabled,
          daysOfWeek: existingReminder.daysOfWeek,
        );

        await NotificationService.updatePatientReminder(updatedReminder);
      }

      await _loadReminders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(existingReminder == null
                ? 'Reminder added!'
                : 'Reminder updated!'),
            backgroundColor: const Color(0xFF37B5B6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving reminder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleReminder(PatientReminder reminder) async {
    try {
      final updatedReminder = PatientReminder(
        id: reminder.id,
        patientId: reminder.patientId,
        patientName: reminder.patientName,
        time: reminder.time,
        title: reminder.title,
        message: reminder.message,
        enabled: !reminder.enabled,
        daysOfWeek: reminder.daysOfWeek,
      );

      await NotificationService.updatePatientReminder(updatedReminder);
      await _loadReminders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(updatedReminder.enabled
                ? 'Reminder enabled!'
                : 'Reminder disabled'),
            backgroundColor: const Color(0xFF37B5B6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating reminder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteReminder(PatientReminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: const Text('Are you sure you want to delete this reminder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await NotificationService.deletePatientReminder(
          widget.patientId,
          reminder.id,
        );
        await _loadReminders();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reminder deleted!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting reminder: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  Icons.person_pin_circle,
                  color: Color(0xFF37B5B6),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Patient Reminders',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _addReminder,
                  icon: const Icon(
                    Icons.add_circle,
                    color: Color(0xFF37B5B6),
                  ),
                  tooltip: 'Add Reminder',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Custom reminders for ${widget.patientName}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF37B5B6),
                ),
              )
            else if (_reminders.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_off,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No reminders set',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap + to add a reminder',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: _reminders
                    .map((reminder) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: reminder.enabled
                                ? const Color(0xFF37B5B6).withOpacity(0.1)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: reminder.enabled
                                  ? const Color(0xFF37B5B6)
                                  : Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: reminder.enabled
                                      ? const Color(0xFF37B5B6)
                                      : Colors.grey[400],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      reminder.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: reminder.enabled
                                            ? const Color(0xFF37B5B6)
                                            : Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      reminder.time.format(context),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: reminder.enabled
                                            ? Colors.black87
                                            : Colors.grey[500],
                                      ),
                                    ),
                                    if (reminder.message.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        reminder.message,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Switch(
                                    value: reminder.enabled,
                                    onChanged: (_) => _toggleReminder(reminder),
                                    activeColor: const Color(0xFF37B5B6),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: () => _showReminderDialog(
                                          existingReminder: reminder,
                                        ),
                                        icon: const Icon(Icons.edit, size: 16),
                                        color: const Color(0xFF37B5B6),
                                        constraints: const BoxConstraints(
                                          minHeight: 32,
                                          minWidth: 32,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            _deleteReminder(reminder),
                                        icon:
                                            const Icon(Icons.delete, size: 16),
                                        color: Colors.red,
                                        constraints: const BoxConstraints(
                                          minHeight: 32,
                                          minWidth: 32,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
