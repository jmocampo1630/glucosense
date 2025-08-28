import 'package:flutter/material.dart';
import 'package:glucolook/models/glucose_record.model.dart';
import '../models/patient.model.dart';
import '../widgets/summary_card.dart';
import '../widgets/dashboard_reminders_widget.dart';
import '../services/reminder_migration.service.dart';

class DashboardPage extends StatefulWidget {
  final Patient? patient;
  final Future<void> Function()? onRecordsChanged;

  const DashboardPage({
    super.key,
    required this.patient,
    this.onRecordsChanged,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const double cardSpacing = 8;
  static const double cardPadding = 14;

  @override
  void initState() {
    super.initState();
    _checkForMigration();
  }

  Future<void> _checkForMigration() async {
    // Only check for migration if user is authenticated and has a patient
    if (widget.patient != null) {
      try {
        final isCompleted =
            await ReminderMigrationService.isMigrationCompleted();
        if (!isCompleted && mounted) {
          final shouldMigrate =
              await ReminderMigrationService.showMigrationDialog(context);
          if (shouldMigrate && mounted) {
            await ReminderMigrationService.performMigrationWithProgress(
                context);
          }
        }
      } catch (e) {
        print('Error during migration check: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRecordsChanged ?? () async {},
      child: ListView(
        padding: const EdgeInsets.all(cardPadding),
        children: [
          Card(
            elevation: 0,
            color: Colors.blue.shade50,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: cardPadding, horizontal: 8),
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.blue.shade100,
                        width: 3,
                      ),
                    ),
                    child: const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child:
                          Icon(Icons.person, size: 32, color: Colors.blueGrey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (widget.patient?.name ?? 'Patient Name')
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.cake,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'Age: ${widget.patient?.dateOfBirth != null ? calculateAge(widget.patient!.dateOfBirth).toString() : '--'}',
                              style: const TextStyle(
                                  fontSize: 15, color: Colors.grey),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.wc, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'Sex: ${widget.patient?.gender ?? '--'}',
                              style: const TextStyle(
                                  fontSize: 15, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'Last Record: ${(widget.patient?.glucoseRecords.isNotEmpty ?? false) ? getLatestRecord(widget.patient!.glucoseRecords)!.date.toString().split(' ').first : '--'}',
                              style: const TextStyle(
                                  fontSize: 15, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: cardSpacing),
          Row(
            children: [
              SummaryCard(
                title: 'Latest',
                value: (widget.patient?.glucoseRecords.isNotEmpty ?? false)
                    ? getLatestRecord(widget.patient!.glucoseRecords)!
                        .value
                        .toString()
                    : '--',
                unit: 'mg/dL',
                color: Colors.blue.shade50,
                icon: Icons.bolt,
                iconColor: Colors.blue,
              ),
              const SizedBox(width: cardSpacing),
              SummaryCard(
                title: 'Avg (7d)',
                value: (widget.patient?.glucoseRecords.isNotEmpty ?? false)
                    ? (calculate7DayAverage(widget.patient!.glucoseRecords)
                            ?.toStringAsFixed(1) ??
                        '--')
                    : '--',
                unit: 'mg/dL',
                color: Colors.green.shade50,
                icon: Icons.show_chart,
                iconColor: Colors.green,
              ),
              const SizedBox(width: cardSpacing),
              SummaryCard(
                title: 'Records',
                value: (widget.patient?.glucoseRecords.length ?? 0).toString(),
                unit: '',
                color: Colors.grey.shade100,
                icon: Icons.list_alt,
                iconColor: Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: cardSpacing),
          Row(
            children: [
              SummaryCard(
                title: 'High',
                value: (widget.patient?.glucoseRecords.isNotEmpty ?? false)
                    ? widget.patient!.glucoseRecords
                        .map((e) => e.value)
                        .fold<double>(
                            double.negativeInfinity, (a, b) => a > b ? a : b)
                        .toStringAsFixed(1)
                    : '--',
                unit: 'mg/dL',
                color: Colors.red.shade50,
                icon: Icons.arrow_upward,
                iconColor: Colors.red,
              ),
              const SizedBox(width: cardSpacing),
              SummaryCard(
                title: 'Low',
                value: (widget.patient?.glucoseRecords.isNotEmpty ?? false)
                    ? widget.patient!.glucoseRecords
                        .map((e) => e.value)
                        .fold<double>(double.infinity, (a, b) => a < b ? a : b)
                        .toStringAsFixed(1)
                    : '--',
                unit: 'mg/dL',
                color: Colors.orange.shade50,
                icon: Icons.arrow_downward,
                iconColor: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: cardSpacing),
          // Patient Reminders Widget
          if (widget.patient != null)
            DashboardRemindersWidget(
              patientId: widget.patient!.id,
              patientName: widget.patient!.name,
            ),
        ],
      ),
    );
  }

  GlucoseRecord? getLatestRecord(List<GlucoseRecord> records) {
    if (records.isEmpty) return null;
    records.sort((a, b) => b.date.compareTo(a.date));
    return records.first;
  }
}

int calculateAge(DateTime dob) {
  DateTime today = DateTime.now();
  int age = today.year - dob.year;

  // Adjust age if birthday hasn't occurred yet this year
  if (today.month < dob.month ||
      (today.month == dob.month && today.day < dob.day)) {
    age--;
  }

  return age;
}

double? calculate7DayAverage(List<GlucoseRecord> records) {
  if (records.isEmpty) return null;
  final now = DateTime.now();
  final sevenDaysAgo =
      DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
  final filtered = records.where((e) {
    final date = DateTime(e.date.year, e.date.month, e.date.day);
    return date.isAtSameMomentAs(sevenDaysAgo) ||
        (date.isAfter(sevenDaysAgo) &&
            date.isBefore(now.add(const Duration(days: 1))));
  }).toList();
  if (filtered.isEmpty) return null;
  final avg = filtered.map((e) => e.value).fold<double>(0, (a, b) => a + b) /
      filtered.length;
  return avg;
}
