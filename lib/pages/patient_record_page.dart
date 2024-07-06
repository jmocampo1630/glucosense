import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:glucolook/enums/toast_type.dart';
import 'package:glucolook/models/glucose_record.model.dart';
import 'package:glucolook/models/patient.model.dart';
import 'package:glucolook/pages/camera_page.dart';
import 'package:glucolook/pages/line_chart.dart';
import 'package:glucolook/pages/settings_page.dart';
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

  GlucoseRecordServices glucoseRecordDatabaseServices = GlucoseRecordServices();
  PatientDatabaseServices patientDatabaseServices = PatientDatabaseServices();
  // File? _selectedImage; // for testing only

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
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // // for testing only
          // if (_selectedImage != null)
          //   Expanded(
          //       child: Image(
          //     image: FileImage(_selectedImage!),
          //     width: imageSize.width,
          //     height: imageSize.height,
          //   )),
          // if (_selectedImage == null) const Text('Please select and image'),
          // const SizedBox(height: 20),
          const SizedBox(height: 10),
          LineChartSample2(records: items),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    title: Text(items[index].name),
                    subtitle: Text(DateFormat('yyyy-MM-dd hh:mm a')
                        .format(items[index].date)),
                    leading: SizedBox(
                        width: 60,
                        height: 50,
                        child: Row(
                          children: [
                            Column(
                              children: [
                                const SizedBox(height: 5),
                                Text(
                                  items[index].value.toStringAsFixed(1),
                                  style: const TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold),
                                ),
                                const Text(
                                  'mg/dL',
                                  style: TextStyle(fontSize: 12.0),
                                )
                              ],
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 5,
                              height: 50,
                              color: items[index].color,
                            )
                          ],
                        )),
                    trailing: PopupMenuButton<String>(
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                        // const PopupMenuItem<String>(
                        //   value: 'detail',
                        //   child: Text('Detail'),
                        // ),
                      ],
                      onSelected: (String value) {
                        if (value == 'delete') {
                          glucoseRecordDatabaseServices.deleteGlucoseRecord(
                              widget.patientId, items[index].id);
                          setState(() {
                            items.remove(items[index]);
                          });
                        } else if (value == 'detail') {
                          // Handle detail action
                        }
                      },
                    ),
                    onTap: () {
                      // Handle onTap event if needed
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
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  void updateRecords(File? image) async {
    GlucoseRecord? record = await generateColor(image);
    if (record != null) {
      String? id = await patientDatabaseServices.addGlucoseRecordToPatient(
          widget.patientId, record);
      if (id != null) {
        record.id = id;
        items.add(record);
      }
    }
    setState(() {
      if (record != null) {
        items.sort((a, b) => b.date.compareTo(a.date));
        showToastWarning("Scan successful!", ToastType.success);
      } else {
        showToastWarning("Scan failed. Please try again.", ToastType.error);
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
