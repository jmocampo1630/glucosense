import 'package:flutter/material.dart';
import 'package:glucolook/models/patient.model.dart';
import 'package:glucolook/services/patient.services.dart';

class AddPatientDialog extends StatefulWidget {
  const AddPatientDialog({super.key});

  @override
  AddPatientDialogState createState() => AddPatientDialogState();
}

class AddPatientDialogState extends State<AddPatientDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime? selectedDate = DateTime.now();
  String? _selectedGender = 'Male';
  String? _patientName = '';

  PatientDatabaseServices patientDatabaseServices = PatientDatabaseServices();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Patient'),
      content: Padding(
        padding: const EdgeInsets.all(8),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
                onSaved: (value) {
                  setState(() {
                    _patientName = value;
                  });
                },
              ),
              TextFormField(
                readOnly: true,
                onTap: () {
                  _selectDate(context);
                },
                validator: (value) {
                  if (selectedDate == null) {
                    return 'Please enter a Date of Birth';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Date of Birth',
                  hintText: selectedDate != null
                      ? '${selectedDate!.year}-${selectedDate!.month}-${selectedDate!.day}'
                      : 'Select date',
                ),
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Select your gender:',
                    style: TextStyle(fontSize: 16.0),
                  ),
                  RadioListTile(
                    title: const Text('Male'),
                    value: 'Male',
                    groupValue: _selectedGender,
                    onChanged: (value) {
                      setState(() {
                        _selectedGender =
                            value as String; // Cast value to String
                      });
                    },
                  ),
                  RadioListTile(
                    title: const Text('Female'),
                    value: 'Female',
                    groupValue: _selectedGender,
                    onChanged: (value) {
                      setState(() {
                        _selectedGender =
                            value as String; // Cast value to String
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ElevatedButton(
                    child: const Text('Submit'),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        Patient patient = Patient(
                            id: '',
                            name: _patientName!,
                            gender: _selectedGender!,
                            dateOfBirth: selectedDate!,
                            glucoseRecords: []);
                        patientDatabaseServices.addPatient(patient);
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  const SizedBox(width: 8.0),
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }
}
