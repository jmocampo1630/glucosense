import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glucolook/modals/add_patient_modal.dart';
import 'package:glucolook/modals/submit_cancel_dialog.dart';
import 'package:glucolook/modals/terms_modal.dart';
import 'package:glucolook/models/patient.model.dart';
import 'package:glucolook/pages/patient_record_page.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
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
          Expanded(
            child: ListView.builder(
              itemCount: patients.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        _getInitials(patients[index].name),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    title: Text('Name: ${patients[index].name}'),
                    subtitle: Text(
                        'Birthday: ${DateFormat('MMMM dd, yyyy').format(patients[index].dateOfBirth)}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PatientRecordPage(
                                  title: patients[index].name,
                                  patientId: patients[index].id,
                                  camera: widget.camera,
                                )),
                      );
                    },
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
                          deleteDialog(context, patients[index].id);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showDialog<void>(
              context: context, builder: (context) => _buildFormModal(context));
          _loadPatients();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTermsAccepted();
    });
    _loadPatients(); // Load patients when the page initializes
  }

  // Method to load patients from Firebase
  void _loadPatients() async {
    List<Patient> loadedPatients = await patientDatabaseServices.getPatients();
    setState(() {
      patients = loadedPatients;
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
