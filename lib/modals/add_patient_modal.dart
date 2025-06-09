import 'package:flutter/material.dart';
import 'package:glucolook/models/patient.model.dart';
import 'package:glucolook/services/patient.services.dart';

class AddPatientDialog extends StatefulWidget {
  final Patient? patient; // <-- Add this

  const AddPatientDialog({super.key, this.patient}); // <-- Accept patient

  @override
  AddPatientDialogState createState() => AddPatientDialogState();
}

class AddPatientDialogState extends State<AddPatientDialog> {
  final _formKey = GlobalKey<FormState>();
  DateTime? selectedDate;
  String? _selectedGender = 'Male';
  String? _patientName = '';
  bool isLoading = false;

  PatientDatabaseServices patientDatabaseServices = PatientDatabaseServices();

  @override
  void initState() {
    super.initState();
    // If editing, prefill fields
    if (widget.patient != null) {
      _patientName = widget.patient!.name;
      _selectedGender = widget.patient!.gender;
      selectedDate = widget.patient!.dateOfBirth;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            widget.patient == null ? Icons.person_add_alt_1 : Icons.edit,
            color: const Color(0xFF37B5B6),
          ),
          const SizedBox(width: 8),
          Text(widget.patient == null ? 'Add Patient' : 'Edit Patient'),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    initialValue: _patientName,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _patientName = value;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    validator: (value) {
                      if (selectedDate == null) {
                        return 'Please select a Date of Birth';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Date of Birth',
                      prefixIcon: const Icon(Icons.cake_outlined),
                      border: const OutlineInputBorder(),
                      hintText: selectedDate != null
                          ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'
                          : 'Select date',
                    ),
                    controller: TextEditingController(
                      text: selectedDate != null
                          ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'
                          : '',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select gender:',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Male'),
                          value: 'Male',
                          groupValue: _selectedGender,
                          onChanged: (value) {
                            setState(() {
                              _selectedGender = value;
                            });
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Female'),
                          value: 'Female',
                          groupValue: _selectedGender,
                          onChanged: (value) {
                            setState(() {
                              _selectedGender = value;
                            });
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: TextButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    Navigator.of(context).pop(false);
                                  },
                            child: const Text('Cancel'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            icon: isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.check),
                            label: Text(
                                widget.patient == null ? 'Submit' : 'Save'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF37B5B6),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 12),
                            ),
                            onPressed: isLoading
                                ? null
                                : () async {
                                    if (_formKey.currentState!.validate()) {
                                      _formKey.currentState!.save();
                                      setState(() => isLoading = true);
                                      if (widget.patient == null) {
                                        // Add new patient
                                        Patient patient = Patient(
                                          id: '',
                                          name: _patientName!,
                                          gender: _selectedGender!,
                                          dateOfBirth: selectedDate!,
                                          glucoseRecords: [],
                                        );
                                        await patientDatabaseServices
                                            .addPatient(patient);
                                      } else {
                                        // Edit existing patient
                                        Patient updated = Patient(
                                          id: widget.patient!.id,
                                          name: _patientName!,
                                          gender: _selectedGender!,
                                          dateOfBirth: selectedDate!,
                                          glucoseRecords:
                                              widget.patient!.glucoseRecords,
                                        );
                                        await patientDatabaseServices
                                            .updatePatient(updated.id, updated);
                                      }
                                      setState(() => isLoading = false);
                                      Navigator.of(context).pop(true);
                                    }
                                  },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }
}
