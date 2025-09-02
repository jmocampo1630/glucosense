import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:glucolook/enums/toast_type.dart';
import 'package:glucolook/modals/scan_glucose_record_modal.dart';
import 'package:glucolook/modals/submit_cancel_dialog.dart';
import 'package:glucolook/models/glucose_record.model.dart';
import 'package:glucolook/models/patient.model.dart';
import 'package:glucolook/models/achievement.model.dart';
import 'package:glucolook/models/badge.model.dart' as BadgeModel;
import 'package:glucolook/pages/camera_page.dart';
import 'package:glucolook/pages/achievements_page.dart';
import 'package:glucolook/pages/badges_page.dart';
import 'package:glucolook/widgets/achievement_widgets.dart';
import 'package:glucolook/widgets/badge_widgets.dart';
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

    List<Widget> pages = [
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
      AchievementsPage(
        patientId: widget.patientId,
      ),
      BadgesPage(
        patientId: widget.patientId,
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
        type: BottomNavigationBarType.fixed,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Achievements',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.military_tech),
            label: 'Badges',
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

        // Refresh patient data to update both Dashboard and PatientRecord pages
        await loadPatient();

        // Check for new achievements and badges
        final result = await patientDatabaseServices
            .checkForNewAchievementsAndBadges(widget.patientId);
        final newAchievements = result['achievements'] as List<Achievement>;
        final newBadges = result['badges'] as List<BadgeModel.Badge>;

        if (mounted) {
          // Show achievement dialog first if any
          if (newAchievements.isNotEmpty) {
            AchievementUnlockedDialog.show(context, newAchievements.first);
          }

          // Show badge dialog after a short delay if any badges were earned
          if (newBadges.isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) {
                showBadgeUnlockedDialog(context, newBadges.first);
              }
            });
          }
        }

        showToastWarning("Scan successful!", ToastType.success);
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
  }
}
