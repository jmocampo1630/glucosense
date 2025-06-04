import 'package:flutter/material.dart';
import 'package:glucolook/enums/toast_type.dart';
import 'package:glucolook/models/settings.model.dart';
import 'package:glucolook/services/color_generator.services.dart';
import 'package:glucolook/services/error.services.dart';
import 'package:glucolook/services/preferences.services.dart';

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
      body: Center(
        child: Card(
          elevation: 5,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 22),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    "App Settings",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF37B5B6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _thresholdController,
                    decoration: InputDecoration(
                      labelText: 'Threshold',
                      prefixIcon: const Icon(Icons.speed),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
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
                  const SizedBox(height: 18),
                  DropdownButtonFormField(
                    value: _type,
                    decoration: InputDecoration(
                      labelText: 'Type',
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
                        return "Please select a type.";
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
                  const SizedBox(height: 28.0),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      // Removed the icon
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF37B5B6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _submitForm,
                      // Removed the icon
                      child: const Text(
                        'Save Settings',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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
}
