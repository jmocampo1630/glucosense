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
import 'package:glucolook/pages/line_chart.dart'; // Add this import
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
  List<GlucoseRecord> items = [];
  final imageSize = const Size(256, 160);
  PaletteGenerator? paletteGenerator;
  Color defaultColor = Colors.white;
  bool isLoading = true;

  GlucoseRecordServices glucoseRecordDatabaseServices = GlucoseRecordServices();
  PatientDatabaseServices patientDatabaseServices = PatientDatabaseServices();

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

    setState(() {
      if (patient != null) {
        items = patient.glucoseRecords;
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title.toUpperCase()),
      ),
      body: Column(
        children: [
          if (!isLoading && items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                height: 220,
                child: LineChartGraph(records: items),
              ),
            ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.analytics_outlined,
                                size: 64, color: Colors.black26),
                            SizedBox(height: 16),
                            Text(
                              'No glucose records found.',
                              style: TextStyle(
                                  fontSize: 18, color: Colors.black54),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 8.0),
                              title: Text(items[index].name,
                                  style: const TextStyle(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  DateFormat('yyyy-MM-dd hh:mm a')
                                      .format(items[index].date),
                                  style: const TextStyle(fontSize: 14.0)),
                              leading: SizedBox(
                                width: 80,
                                height: 50,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 60,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            items[index]
                                                .value
                                                .toStringAsFixed(1),
                                            style: TextStyle(
                                              fontSize: 17.0,
                                              fontWeight: FontWeight.w900,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              letterSpacing: 0.5,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'mg/dL',
                                            style: TextStyle(
                                              fontSize: 11.0,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: 0.2,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      width: 5,
                                      height: 45,
                                      decoration: BoxDecoration(
                                        color: items[index].color,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: PopupMenuButton<String>(
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
                                            widget.patientId, items[index].id);
                                    setState(() {
                                      items.remove(items[index]);
                                    });
                                  }
                                },
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => GlucoseLevelDetail(
                                          glucoseRecord: items[index])),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          openCamera();
        },
        tooltip: 'Scan',
        child: const Icon(Icons.add),
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
