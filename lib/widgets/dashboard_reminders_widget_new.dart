import 'package:flutter/material.dart';
import 'package:glucolook/services/patient_reminder.service.dart';
import 'package:glucolook/models/patient_reminder.model.dart';

class DashboardRemindersWidget extends StatefulWidget {
  final String patientId;
  final String patientName;

  const DashboardRemindersWidget({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<DashboardRemindersWidget> createState() =>
      _DashboardRemindersWidgetState();
}

class _DashboardRemindersWidgetState extends State<DashboardRemindersWidget> {
  List<PatientReminderModel> _reminders = [];
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
          await PatientReminderService.getPatientReminders(widget.patientId);
      setState(() {
        _reminders = reminders;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reminders: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddReminderDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddReminderDialog(patientName: widget.patientName),
    );

    if (result != null) {
      try {
        await PatientReminderService.addPatientReminder(
          patientId: widget.patientId,
          patientName: widget.patientName,
          title: result['title'],
          dateTime: result['dateTime'],
          description: result['description'],
        );
        _loadReminders(); // Reload the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reminder added successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding reminder: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleReminder(PatientReminderModel reminder) async {
    try {
      await PatientReminderService.toggleReminderStatus(
        reminder.id,
        !reminder.isEnabled,
      );
      _loadReminders(); // Reload the list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating reminder: $e')),
        );
      }
    }
  }

  Future<void> _deleteReminder(PatientReminderModel reminder) async {
    try {
      await PatientReminderService.deletePatientReminder(reminder.id);
      _loadReminders(); // Reload the list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting reminder: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.teal[700]),
                const SizedBox(width: 8),
                Text(
                  'Patient Reminders',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[700],
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _showAddReminderDialog,
                  icon: Icon(Icons.add, color: Colors.teal[700]),
                  tooltip: 'Add Reminder',
                ),
                IconButton(
                  onPressed: _loadReminders,
                  icon: Icon(Icons.refresh, color: Colors.teal[700]),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.teal),
              )
            else if (_reminders.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.notification_add,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No reminders set',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap + to add a reminder',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _reminders.length,
                itemBuilder: (context, index) {
                  final reminder = _reminders[index];
                  return _buildReminderItem(reminder);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderItem(PatientReminderModel reminder) {
    final isOverdue = reminder.isPast && reminder.isEnabled;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOverdue
            ? Colors.red[50]
            : reminder.isEnabled
                ? Colors.teal[50]
                : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOverdue
              ? Colors.red[200]!
              : reminder.isEnabled
                  ? Colors.teal[200]!
                  : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOverdue
                ? Icons.warning
                : reminder.isEnabled
                    ? Icons.schedule
                    : Icons.schedule_outlined,
            color: isOverdue
                ? Colors.red[600]
                : reminder.isEnabled
                    ? Colors.teal[600]
                    : Colors.grey[500],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      reminder.formattedTime,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isOverdue
                            ? Colors.red[700]
                            : reminder.isEnabled
                                ? Colors.teal[700]
                                : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      reminder.formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (reminder.title.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    reminder.title,
                    style: TextStyle(
                      fontSize: 13,
                      color: reminder.isEnabled
                          ? Colors.grey[700]
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: reminder.isEnabled,
            onChanged: (_) => _toggleReminder(reminder),
            activeColor: Colors.teal,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          IconButton(
            onPressed: () => _deleteReminder(reminder),
            icon: Icon(Icons.delete, color: Colors.red[400]),
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddReminderDialog extends StatefulWidget {
  final String patientName;

  const _AddReminderDialog({required this.patientName});

  @override
  State<_AddReminderDialog> createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<_AddReminderDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Reminder for ${widget.patientName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Reminder Title *',
                hintText: 'e.g., Take Medicine, Check Blood Sugar',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Additional details...',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    ),
                    onTap: _selectDate,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.access_time),
                    title: Text('Time: ${_selectedTime.format(context)}'),
                    onTap: _selectTime,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _titleController.text.trim().isEmpty
              ? null
              : () {
                  final dateTime = DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    _selectedTime.hour,
                    _selectedTime.minute,
                  );

                  Navigator.pop(context, {
                    'title': _titleController.text.trim(),
                    'description': _descriptionController.text.trim().isEmpty
                        ? null
                        : _descriptionController.text.trim(),
                    'dateTime': dateTime,
                  });
                },
          child: const Text('Add Reminder'),
        ),
      ],
    );
  }
}
