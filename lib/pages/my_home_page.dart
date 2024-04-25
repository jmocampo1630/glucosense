import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:glucosense/enums/toast_type.dart';
import 'package:glucosense/models/glucose.dart';
import 'package:glucosense/pages/camera_page.dart';
import 'package:glucosense/services/color_generator.services.dart';
import 'package:glucosense/services/error.services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette_generator/palette_generator.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.camera});
  final String title;
  final CameraDescription camera;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<GlucoseRecord> items = [];
  final List<GlucoseLevel> metrics = [
    GlucoseLevel(value: 1, color: Colors.yellow),
    GlucoseLevel(value: 2, color: Colors.purple),
    GlucoseLevel(value: 3, color: Colors.red),
    GlucoseLevel(value: 4, color: Colors.green),
    GlucoseLevel(value: 5, color: Colors.blue),
  ];
  final imageSize = const Size(256, 160);
  PaletteGenerator? paletteGenerator;
  Color defaultColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              title: Text(items[index].name),
              subtitle: Text(items[index].description),
              trailing: Container(
                width: 20,
                height: 20,
                color: items[index].color,
              ),
              onTap: () {
                // Handle onTap event if needed
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final imagePath = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CameraPage(camera: widget.camera)),
          );
          if (imagePath != null) {
            updateRecords(File(imagePath));
          }
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  void updateRecords(File? image) async {
    GlucoseRecord? record = await generateColor(image);
    setState(() {
      if (record != null) {
        items.add(record);
        items.sort((a, b) => b.date.compareTo(a.date));
        showToastWarning("Scan successful!", ToastType.success);
      } else {
        showToastWarning("Scan failed. Please try again.", ToastType.error);
      }
    });
  }

  Future _pickImageFromGallery() async {
    final returnImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (returnImage == null) return;
    generateColor(File(returnImage.path));
  }

  Future _pickImageFromCamera() async {
    final returnImage =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (returnImage == null) return;
    generateColor(File(returnImage.path));
  }
}
