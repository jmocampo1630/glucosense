import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:glucolook/enums/toast_type.dart';
import 'package:glucolook/modals/scan_glucose_record_modal.dart';
import 'package:glucolook/modals/submit_cancel_dialog.dart';
import 'package:glucolook/models/glucose_record.model.dart';
import 'package:glucolook/models/patient.model.dart';
import 'package:glucolook/pages/camera_page.dart';
import 'package:glucolook/services/color_generator.services.dart';
import 'package:glucolook/services/error.services.dart';
import 'dashboard_page.dart';
import 'patient_record_page.dart';
import '../services/patient.services.dart';

class MainNavPage extends StatefulWidget {
  final String title;
  final String patientId;
  final CameraDescription camera;

  const MainNavPage({
    super.key,
    required this.title,
    required this.patientId,
    required this.camera,
  });

  @override
  State<MainNavPage> createState() => _MainNavPageState();
}

class _MainNavPageState extends State<MainNavPage> {
  int _selectedIndex = 0;
  bool isLoading = true;
  Patient? patient;
  List<GlucoseRecord> items = [];

  PatientDatabaseServices patientDatabaseServices = PatientDatabaseServices();

  @override
  void initState() {
    super.initState();
    loadPatient();
  }

  Future<void> loadPatient() async {
    setState(() {
      isLoading = true;
    });
    final loadedPatient =
        await patientDatabaseServices.getPatientById(widget.patientId);
    if (!mounted) return;
    setState(() {
      patient = loadedPatient;
      items = List<GlucoseRecord>.from(patient!.glucoseRecords);
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title.toUpperCase()),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final pages = [
      DashboardPage(
        patient: patient,
        onRecordsChanged: loadPatient,
      ),
      PatientRecordPage(
        title: widget.title,
        patientId: widget.patientId,
        camera: widget.camera,
        patient: patient,
        onRecordsChanged: loadPatient,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title.toUpperCase()),
      ),
      body: pages[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          openCamera();
        },
        tooltip: 'Scan Glucose',
        child: const Icon(Icons.camera_enhance),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Records',
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
}
