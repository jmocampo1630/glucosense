import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:glucolook/enums/toast_type.dart';
import 'package:glucolook/modals/pdf_export_modal.dart';
import 'package:glucolook/modals/scan_glucose_record_modal.dart';
import 'package:glucolook/modals/submit_cancel_dialog.dart';
import 'package:glucolook/models/glucose_record.model.dart';
import 'package:glucolook/models/patient.model.dart';
import 'package:glucolook/pages/camera_page.dart';
import 'package:glucolook/pages/glucose_level_detail.dart';
import 'package:glucolook/pages/line_chart.dart';
import 'package:glucolook/services/color_generator.services.dart';
import 'package:glucolook/services/error.services.dart';
import 'package:glucolook/services/patient.services.dart';
import 'package:glucolook/services/pdf_export.services.dart';
import 'package:glucolook/services/achievement.service.dart';
import 'package:intl/intl.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:glucolook/services/glucose_record.services.dart';
import 'package:printing/printing.dart';

class PatientRecordPage extends StatefulWidget {
  const PatientRecordPage({
    super.key,
    required this.title,
    required this.camera,
    required this.patientId,
    this.patient,
    this.onRecordsChanged,
  });

  final String title;
  final CameraDescription camera;
  final String patientId;
  final Patient? patient;
  final Future<void> Function()? onRecordsChanged;

  @override
  State<PatientRecordPage> createState() => _PatientRecordPageState();
}

class _PatientRecordPageState extends State<PatientRecordPage> {
  final ScrollController _listController = ScrollController();
  int? selectedIndex;
  List<GlucoseRecord> items = [];
  final imageSize = const Size(256, 160);
  PaletteGenerator? paletteGenerator;
  Color defaultColor = Colors.white;

  GlucoseRecordServices glucoseRecordDatabaseServices = GlucoseRecordServices();
  PatientDatabaseServices patientDatabaseServices = PatientDatabaseServices();
  AchievementService achievementService = AchievementService();

  Timer? _highlightTimer;

  @override
  void initState() {
    super.initState();
    if (widget.patient != null) {
      items = List<GlucoseRecord>.from(widget.patient!.glucoseRecords);
      items.sort((a, b) => b.date.compareTo(a.date));
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRecordsChanged ?? () async {},
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SizedBox(
              height: 220,
              child: LineChartGraph(
                records: items.reversed.toList(),
                onSpotTapped: (int idx) {
                  final listIndex = items.length - 1 - idx;
                  setState(() {
                    selectedIndex = listIndex;
                  });
                  _listController.animateTo(
                    (listIndex * 90.0) - 100.0 < 0
                        ? 0
                        : (listIndex * 90.0) - 100.0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                  _highlightTimer?.cancel();
                  _highlightTimer = Timer(const Duration(seconds: 1), () {
                    if (mounted) {
                      setState(() {
                        selectedIndex = null;
                      });
                    }
                  });
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.list_alt, color: Colors.blueGrey, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Glucose Records",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[700],
                      ),
                ),
                const Spacer(),
                // Export to PDF Button
                IconButton(
                  onPressed: _openPdfExportModal,
                  icon: const Icon(Icons.file_upload),
                  color: const Color(0xFF37B5B6),
                  tooltip: 'Export to PDF',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.analytics_outlined,
                                  size: 80, color: Colors.blueGrey[200]),
                              const SizedBox(height: 20),
                              Text(
                                'No glucose records found.',
                                style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.blueGrey[400],
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Tap the + button to add your first record.',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.blueGrey[300]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    controller: _listController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                        left: 0, right: 0, top: 0, bottom: 90),
                    children: [
                      ...List.generate(items.length, (index) {
                        final isSelected = index == selectedIndex;
                        final record = items[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            height: 84,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blue.withOpacity(0.08)
                                  : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: isSelected
                                  ? Border.all(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      width: 2)
                                  : Border.all(
                                      color: Colors.grey.withOpacity(0.15),
                                      width: 1),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                leading: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 56,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            record.value.toStringAsFixed(1),
                                            style: TextStyle(
                                              fontSize: 20.0,
                                              fontWeight: FontWeight.w900,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'mg/dL',
                                            style: TextStyle(
                                              fontSize: 12.0,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      width: 7,
                                      height: 45,
                                      decoration: BoxDecoration(
                                        color: record.color,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ],
                                ),
                                title: Text(
                                  record.name,
                                  style: const TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  DateFormat('yyyy-MM-dd hh:mm a')
                                      .format(record.date),
                                  style: const TextStyle(fontSize: 14.0),
                                ),
                                trailing: SizedBox(
                                  width: 32,
                                  child: PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 20),
                                    itemBuilder: (BuildContext context) =>
                                        <PopupMenuEntry<String>>[
                                      const PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Text('Delete'),
                                      ),
                                    ],
                                    onSelected: (String value) {
                                      if (value == 'delete') {
                                        glucoseRecordDatabaseServices
                                            .deleteGlucoseRecord(
                                                widget.patientId, record.id);
                                        setState(() {
                                          items.remove(record);
                                        });
                                      }
                                    },
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GlucoseLevelDetail(
                                          glucoseRecord: record),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> openCamera() async {
    final imagePath = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => CameraPage(camera: widget.camera)),
    );
    if (imagePath != null) {
      updateRecords(File(imagePath));
    }
  }

  void updateRecords(File? image) async {
    if (image == null) return;
    GlucoseRecord? record = await generateColor(image);
    if (!mounted) return;
    if (record != null) {
      final result = await showDialog<Object?>(
          context: context,
          builder: (context) => ScanGlucoseRecordModal(
                glucoseRecord: record,
                image: image,
              ));

      // Handle the result - if it's false or null, retry
      if (result == false || result == null) {
        openCamera();
        return;
      }

      // If result is a GlucoseRecord, use it; otherwise use original record
      GlucoseRecord recordToSave = result is GlucoseRecord ? result : record;

      String? id = await patientDatabaseServices.addGlucoseRecordToPatient(
          widget.patientId, recordToSave);
      if (id != null) {
        recordToSave.id = id;
        items.add(recordToSave);
        items.sort((a, b) => b.date.compareTo(a.date));
        setState(() {}); // Refresh the UI

        // Call the refresh callback to update parent data
        if (widget.onRecordsChanged != null) {
          await widget.onRecordsChanged!();
        }
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return SubmitCancelDialog(
            title: 'Scan Failed',
            content: 'Do you want to try again?',
            onSubmit: () {
              Navigator.of(context).pop();
              openCamera();
            },
            onCancel: () {
              Navigator.of(context).pop();
            },
            submitText: 'Yes',
          );
        },
      );
    }
    setState(() {
      if (record != null) {
        items.sort((a, b) => b.date.compareTo(a.date));
        showToastWarning("Scan successful!", ToastType.success);
      }
    });
  }

  void _openPdfExportModal() {
    showDialog(
      context: context,
      builder: (context) => PdfExportModal(
        onExport: _exportToPdf,
      ),
    );
  }

  void _exportToPdf(DateTime startDate, DateTime endDate) async {
    // Filter records based on date range
    final filteredRecords = items.where((record) {
      final recordDate =
          DateTime(record.date.year, record.date.month, record.date.day);
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);

      return (recordDate.isAtSameMomentAs(start) ||
              recordDate.isAfter(start)) &&
          (recordDate.isAtSameMomentAs(end) || recordDate.isBefore(end));
    }).toList();

    // Sort by date (oldest first for PDF)
    filteredRecords.sort((a, b) => a.date.compareTo(b.date));

    if (filteredRecords.isEmpty) {
      showToastWarning(
          "No records found in the selected date range.", ToastType.error);
      return;
    }

    try {
      // Show loading
      showToastWarning("Generating PDF...", ToastType.success);

      // Generate PDF
      final pdfResult = await PdfExportService.generateGlucoseRecordsPdf(
        records: filteredRecords,
        startDate: startDate,
        endDate: endDate,
        patient: widget.patient,
      );

      // Share the PDF
      await Printing.sharePdf(
        bytes: pdfResult['bytes'],
        filename: pdfResult['filename'],
      );

      final fileName = pdfResult['filename'];

      // Track export for achievements
      await achievementService.incrementExportCount(widget.patient!.id);

      // Show success message
      showToastWarning(
        "PDF generated and ready to share: $fileName",
        ToastType.success,
      );
    } catch (e) {
      showToastWarning(
        "Failed to export PDF: ${e.toString()}",
        ToastType.error,
      );
    }
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _listController.dispose();
    super.dispose();
  }
}
