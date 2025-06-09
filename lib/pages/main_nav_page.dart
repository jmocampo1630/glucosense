import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dashboard_page.dart';
import 'patient_record_page.dart';

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

  @override
  Widget build(BuildContext context) {
    final pages = [
      const DashboardPage(),
      PatientRecordPage(
        title: widget.title,
        patientId: widget.patientId,
        camera: widget.camera,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title.toUpperCase()),
      ),
      body: pages[_selectedIndex],
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
