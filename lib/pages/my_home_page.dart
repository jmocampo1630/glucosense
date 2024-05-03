import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:glucosense/modals/add_patient_modal.dart';
import 'package:glucosense/models/patient.model.dart';
import 'package:glucosense/pages/patient_record_page.dart';
import 'package:glucosense/services/patient.services.dart';
import 'package:intl/intl.dart';

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
}
