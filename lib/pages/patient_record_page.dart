import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:glucolook/enums/toast_type.dart';
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
import 'package:glucolook/services/preferences.services.dart';
import 'package:intl/intl.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:glucolook/services/glucose_record.services.dart';

class PatientRecordPage extends StatefulWidget {
  const PatientRecordPage(
      {super.key,
      required this.title,
      required this.camera,
      required this.patientId});
  final String title;
  final CameraDescription camera;
  final String patientId;

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
  bool isLoading = true;

  GlucoseRecordServices glucoseRecordDatabaseServices = GlucoseRecordServices();
  PatientDatabaseServices patientDatabaseServices = PatientDatabaseServices();

  Timer? _highlightTimer;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    String? thresholdDefault = await getData('threshold');
    String? typeDefault = await getData('type');
    Patient? patient =
        await patientDatabaseServices.getPatientById(widget.patientId);

    if (!mounted) return;

    setState(() {
      if (patient != null) {
        items = patient.glucoseRecords;
        items.sort((a, b) => b.date.compareTo(a.date));
      }
      isLoading = false;
    });

    if (thresholdDefault != null) {
      setDefaultThreshold(int.parse(thresholdDefault));
    }
    if (typeDefault != null) setDefaultType(int.parse(typeDefault));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (!isLoading && items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                height: 220,
                child: LineChartGraph(
                  records: items.reversed.toList(), // ASC for chart
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
          if (!isLoading && items.isNotEmpty)
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
                ],
              ),
            ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? Center(
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
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await loadData();
                        },
                        child: ListView.separated(
                          controller: _listController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(
                              left: 16, right: 16, top: 8, bottom: 90),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final isSelected = index == selectedIndex;
                            final record = items[index];
                            return AnimatedContainer(
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
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
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
                                          borderRadius:
                                              BorderRadius.circular(4),
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
                                      icon:
                                          const Icon(Icons.more_vert, size: 20),
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
                                        builder: (context) =>
                                            GlucoseLevelDetail(
                                                glucoseRecord: record),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          openCamera();
        },
        label: const Text('Scan'),
        icon: const Icon(Icons.add),
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
      // // for testing only
      // setState(() {
      //   _selectedImage = File(imagePath);
      // });
      updateRecords(File(imagePath));
    }
  }

  void updateRecords(File? image) async {
    if (image == null) return;
    GlucoseRecord? record = await generateColor(image);
    if (!mounted) return;
    if (record != null) {
      final isSave = await showDialog<bool>(
          context: context,
          builder: (context) => ScanGlucoseRecordModal(
                glucoseRecord: record,
                image: image,
              ));

      if (!(isSave != null && isSave)) {
        openCamera();
        return;
      }

      String? id = await patientDatabaseServices.addGlucoseRecordToPatient(
          widget.patientId, record);
      if (id != null) {
        record.id = id;
        items.add(record);
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
              // Handle cancel action
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
      } else {
        // showToastWarning("Scan failed. Please try again.", ToastType.error);
      }
    });
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _listController.dispose();
    super.dispose();
  }

  // Future _pickImageFromGallery() async {
  //   final returnImage =
  //       await ImagePicker().pickImage(source: ImageSource.gallery);
  //   if (returnImage == null) return;
  //   generateColor(File(returnImage.path));
  // }

  // Future _pickImageFromCamera() async {
  //   final returnImage =
  //       await ImagePicker().pickImage(source: ImageSource.camera);
  //   if (returnImage == null) return;
  //   generateColor(File(returnImage.path));
  // }
}
