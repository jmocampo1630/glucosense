import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glucosense/enums/toast_type.dart';
import 'package:glucosense/models/glucose.dart';
import 'package:glucosense/services/error.services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:palette_generator/palette_generator.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

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
        onPressed: () {
          _pickImageFromCamera();
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  void generateColor(File? image) async {
    if (image == null) return;
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm a').format(now);

    paletteGenerator = await PaletteGenerator.fromImageProvider(
        FileImage(image),
        size: imageSize,
        region: Rect.fromLTRB(0, 0, imageSize.width, imageSize.height));
    setState(() {
      Color generatedColor = paletteGenerator != null
          ? paletteGenerator!.dominantColor != null
              ? paletteGenerator!.dominantColor!.color
              : defaultColor
          : defaultColor;

      GlucoseLevel? glucoseLevel = getTestResult(generatedColor);
      if (glucoseLevel != null) {
        String value = glucoseLevel.value.toString();
        items.add(GlucoseRecord(
          name: "Glucose Level: $value",
          description: formattedDate,
          date: now,
          color: glucoseLevel.color,
        ));
        showToastWarning("Scan successful!", ToastType.success);
      } else {
        showToastWarning("Scan failed. Please try again.", ToastType.error);
      }
    });
  }

  GlucoseLevel? getTestResult(Color color, {int threshold = 100}) {
    if (metrics.isEmpty) {
      return null;
    }
    int minDiff = isColorSimilar(color, metrics[0].color, threshold);
    GlucoseLevel? closestGlucoseLevel = metrics[0];

    for (var metric in metrics) {
      int diff = isColorSimilar(color, metric.color, threshold);
      if (diff < minDiff) {
        minDiff = diff;
        closestGlucoseLevel = metric;
      }
    }
    if (minDiff > threshold) {
      return null;
    }

    return closestGlucoseLevel;
  }

  int isColorSimilar(Color color1, Color color2, int threshold) {
    int rDiff = (color1.red - color2.red).abs();
    int gDiff = (color1.green - color2.green).abs();
    int bDiff = (color1.blue - color2.blue).abs();

    int totalDiff = rDiff + gDiff + bDiff;
    return totalDiff;
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
