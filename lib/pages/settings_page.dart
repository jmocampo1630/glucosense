import 'package:flutter/material.dart';
import 'package:glucosense/enums/toast_type.dart';
import 'package:glucosense/models/settings.model.dart';
import 'package:glucosense/services/color_generator.services.dart';
import 'package:glucosense/services/error.services.dart';
import 'package:glucosense/services/preferences.services.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Settings'),
      ),
      body: const MyForm(),
    );
  }
}

class MyForm extends StatefulWidget {
  const MyForm({super.key});

  @override
  State<MyForm> createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  int _type = 1;
  int _threshold = 0;
  List<ColorFinderType> listOfValue = [
    ColorFinderType('Type 1', 1),
    ColorFinderType('Type 2', 2),
  ];
  late TextEditingController _thresholdController;

  void _submitForm() {
    // Check if the form is valid
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      saveData('threshold', _threshold.toString());
      saveData('type', _type.toString());
      showToastWarning("Save successful!", ToastType.success);
      Navigator.pop(context);
    } else {
      showToastWarning("Save failed!", ToastType.error);
    }
  }

  Future<void> loadData() async {
    int thresholdDefault = await getDefaultThreshold();
    int typeDefault = await getDefaultType();
    setState(() {
      _threshold = thresholdDefault;
      _type = typeDefault;
      _thresholdController.text = _threshold.toString();
    });
  }

  @override
  void initState() {
    super.initState();
    _thresholdController = TextEditingController(text: _threshold.toString());
    loadData();
  }

  @override
  void dispose() {
    _thresholdController.dispose(); // Dispose the controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _thresholdController,
                decoration: const InputDecoration(labelText: 'Threshold'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your threshold.';
                  }
                  return null;
                },
                onSaved: (value) {
                  if (value != null) {
                    setState(() {
                      _threshold = int.parse(value);
                    });
                  }
                },
              ),
              DropdownButtonFormField(
                value: _type,
                hint: const Text(
                  'choose one',
                ),
                isExpanded: true,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _type = value;
                    });
                  }
                },
                onSaved: (value) {
                  if (value != null) {
                    setState(() {
                      _type = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null) {
                    return "can't empty";
                  } else {
                    return null;
                  }
                },
                items: listOfValue.map((ColorFinderType item) {
                  return DropdownMenuItem<int>(
                    value: item.value,
                    child: Text(item.name),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
