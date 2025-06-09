import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:glucolook/models/patient.model.dart';
import 'package:glucolook/pages/camera_page.dart';
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
          final imagePath = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CameraPage(camera: widget.camera),
            ),
          );
          if (imagePath != null) {
            // Handle the scanned image path if needed
          }
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
}
