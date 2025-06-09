import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glucolook/modals/add_patient_modal.dart';
import 'package:glucolook/modals/submit_cancel_dialog.dart';
import 'package:glucolook/modals/terms_modal.dart';
import 'package:glucolook/models/patient.model.dart';
import 'package:glucolook/pages/main_nav_page.dart';
import 'package:glucolook/pages/settings_page.dart';
import 'package:glucolook/services/patient.services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.camera});
  final String title;
  final CameraDescription camera;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PatientDatabaseServices patientDatabaseServices = PatientDatabaseServices();
  List<Patient> patients = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTermsAccepted();
    });
    _loadPatients(); // Load patients when the page initializes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          PopupMenuButton<String>(
            icon: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            itemBuilder: (BuildContext context) {
              final user = FirebaseAuth.instance.currentUser;
              return [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        child: Icon(Icons.person, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          user?.email ?? 'No user',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings, size: 20),
                      SizedBox(width: 20),
                      Text('Settings'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20),
                      SizedBox(width: 20),
                      Text('Logout'),
                    ],
                  ),
                ),
              ];
            },
            onSelected: (String value) async {
              if (value == 'logout') {
                await FirebaseAuth.instance.signOut();
              } else if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : patients.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline,
                                  size: 64, color: Colors.black26),
                              SizedBox(height: 16),
                              Text(
                                'No patients found.',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.black54),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            await _loadPatients();
                          },
                          child: ListView.separated(
                            itemCount: patients.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 2),
                            itemBuilder: (context, index) {
                              return Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue.shade100,
                                    child: Text(
                                      _getInitials(patients[index].name),
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.blue),
                                    ),
                                  ),
                                  title: Text(
                                    patients[index].name.toUpperCase(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18),
                                  ),
                                  subtitle: patients[index]
                                          .glucoseRecords
                                          .isNotEmpty
                                      ? Text(
                                          'Last record: ${DateFormat('MM/dd/yyyy hh:mm a').format(
                                            patients[index]
                                                .glucoseRecords
                                                .map((r) => r.date)
                                                .reduce((a, b) =>
                                                    a.isAfter(b) ? a : b),
                                          )}',
                                          style: const TextStyle(fontSize: 12),
                                        )
                                      : const Text(
                                          'No records',
                                          style: TextStyle(
                                              color: Colors.black54,
                                              fontSize: 12),
                                        ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MainNavPage(
                                          title: patients[index].name,
                                          patientId: patients[index].id,
                                          camera: widget.camera,
                                        ),
                                      ),
                                    );
                                  },
                                  trailing: PopupMenuButton<String>(
                                    itemBuilder: (BuildContext context) =>
                                        <PopupMenuEntry<String>>[
                                      const PopupMenuItem<String>(
                                        value: 'edit',
                                        child: Text('Edit'),
                                      ),
                                      const PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Text('Delete'),
                                      ),
                                    ],
                                    onSelected: (String value) async {
                                      if (value == 'edit') {
                                        final result = await showDialog<bool>(
                                          context: context,
                                          builder: (context) =>
                                              AddPatientDialog(
                                            patient: patients[
                                                index], // Pass the patient to edit
                                          ),
                                        );
                                        if (result == true) {
                                          _loadPatients();
                                        }
                                      } else if (value == 'delete') {
                                        deleteDialog(
                                            context, patients[index].id);
                                      }
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
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Patient',
        onPressed: () async {
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => _buildFormModal(context),
          );
          if (result == true) {
            _loadPatients();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // Method to load patients from Firebase
  Future<void> _loadPatients() async {
    setState(() {
      isLoading = true;
    });
    List<Patient> loadedPatients = await patientDatabaseServices.getPatients();
    setState(() {
      patients = loadedPatients;
      isLoading = false;
    });
  }

  String _getInitials(String name) {
    List<String> nameSplit = name.split(' ');
    String initials = '';
    int numWords =
        nameSplit.length > 1 ? 2 : 1; // Take first two words as initials
    for (int i = 0; i < numWords; i++) {
      initials += nameSplit[i][0];
    }
    return initials.toUpperCase();
  }

  Widget _buildFormModal(BuildContext context) {
    return const AddPatientDialog();
  }

  void deleteDialog(BuildContext context, String patientId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SubmitCancelDialog(
          title: 'Delete Patient',
          content: 'Are you sure you want to delete this patient?',
          onSubmit: () {
            patientDatabaseServices.deletePatient(patientId);
            Navigator.of(context).pop();
            _loadPatients();
          },
          onCancel: () {
            // Handle cancel action
            Navigator.of(context).pop();
          },
          submitText: 'Proceed',
        );
      },
    );
  }

  Future<void> _checkTermsAccepted() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? termsAccepted = prefs.getBool('termsAccepted') ?? false;

    if (!termsAccepted) {
      if (!mounted) return;
      bool? agreed = await _showTermsPopup(context);

      if (agreed != null && agreed) {
        await prefs.setBool('termsAccepted', true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You agreed to the terms')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You disagreed to the terms')),
        );
      }
    }
  }

  Future<bool?> _showTermsPopup(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const TermsModal();
      },
    );
  }
}
