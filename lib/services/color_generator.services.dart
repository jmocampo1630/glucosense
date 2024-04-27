import 'dart:io';

import 'package:flutter/material.dart';
import 'package:glucosense/models/glucose.dart';
import 'package:intl/intl.dart';
import 'package:palette_generator/palette_generator.dart';

const threshold = 150;
final List<GlucoseLevel> metrics = [
  GlucoseLevel(value: 1, color: Colors.yellow),
  GlucoseLevel(value: 2, color: Colors.purple),
  GlucoseLevel(value: 3, color: Colors.red),
  // GlucoseLevel(value: 4, color: Colors.green),
  // GlucoseLevel(value: 5, color: Colors.blue),
];
const imageSize = Size(256, 160);
PaletteGenerator? paletteGenerator;
Color defaultColor = Colors.white;

Future<GlucoseRecord?> generateColor(File? image) async {
  if (image == null) return null;
  DateTime now = DateTime.now();
  String formattedDate = DateFormat('yyyy-MM-dd HH:mm a').format(now);

  paletteGenerator = await PaletteGenerator.fromImageProvider(FileImage(image),
      size: imageSize,
      region: Rect.fromLTRB(0, 0, imageSize.width, imageSize.height));
  Color generatedColor = paletteGenerator != null
      ? paletteGenerator!.vibrantColor != null
          ? paletteGenerator!.vibrantColor!.color
          : defaultColor
      : defaultColor;

  GlucoseLevel? glucoseLevel = getTestResult(generatedColor);
  if (glucoseLevel != null) {
    String value = glucoseLevel.value.toString();
    return GlucoseRecord(
      name: "Glucose Level: $value",
      description: formattedDate,
      date: now,
      color: glucoseLevel.color,
    );
  } else {
    return null;
  }
}

int isColorSimilar(Color color1, Color color2, int threshold) {
  int rDiff = (color1.red - color2.red).abs();
  int gDiff = (color1.green - color2.green).abs();
  int bDiff = (color1.blue - color2.blue).abs();

  int totalDiff = rDiff + gDiff + bDiff;
  return totalDiff;
}

GlucoseLevel? getTestResult(Color color, {int threshold = threshold}) {
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
