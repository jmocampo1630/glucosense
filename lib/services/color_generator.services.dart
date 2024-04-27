import 'dart:io';

import 'package:flutter/material.dart';
import 'package:glucosense/models/glucose.dart';
import 'package:intl/intl.dart';
import 'package:palette_generator/palette_generator.dart';

// default values
const int threshold = 150;
const int type = 2;
List<ColorMetrics> colorRanges = [
  ColorMetrics(
      'Yellow',
      ColorRange(Range(200, 255), Range(0, 100), Range(150, 255)),
      Colors.yellow,
      1),
  ColorMetrics(
      'Purple',
      ColorRange(Range(100, 255), Range(100, 255), Range(0, 150)),
      Colors.purple,
      2),
  ColorMetrics('Red', ColorRange(Range(150, 255), Range(0, 100), Range(0, 100)),
      Colors.red, 3),
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

  ColorMetrics? glucoseLevel = getTestResult(generatedColor);
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

ColorMetrics? getTestResult(Color color) {
  if (colorRanges.isEmpty) {
    return null;
  }

  switch (type) {
    case 2:
      ColorMetrics? rangeResult = classifyColor(color);
      return rangeResult;
    default:
      return diffMethod(color);
  }
}

ColorMetrics? diffMethod(Color color) {
  if (colorRanges.isEmpty) {
    return null;
  }
  int minDiff = isColorSimilar(color, colorRanges[0].color, threshold);
  ColorMetrics? closestGlucoseLevel = colorRanges[0];

  for (var metric in colorRanges) {
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

ColorMetrics? classifyColor(Color dominantColor) {
  int red = dominantColor.red;
  int green = dominantColor.green;
  int blue = dominantColor.blue;

  // Check if dominant color falls within any color range
  double minDistance = double.infinity;
  ColorMetrics? closestColor;

  for (ColorMetrics colorRange in colorRanges) {
    if (_isInRange(red, colorRange.range.red.min, colorRange.range.red.max) &&
        _isInRange(
            blue, colorRange.range.blue.min, colorRange.range.blue.max) &&
        _isInRange(
            green, colorRange.range.green.min, colorRange.range.green.max)) {
      return colorRange;
    }

    // Calculate distance between the dominant color and the color range
    double distance = _calculateDistance(red, green, blue, colorRange);
    if (distance < minDistance) {
      minDistance = distance;
      closestColor = colorRange;
    }
  }

  // If the closest color is within threshold, return it, else return null
  if (closestColor == null) return null;
  return minDistance <= threshold ? closestColor : null;
}

bool _isInRange(int value, int min, int max) {
  return value >= min && value <= max;
}

// ColorCategory _getColorCategory(String categoryName) {
//   switch (categoryName) {
//     case 'Purple':
//       return ColorCategory.Purple;
//     case 'Yellow':
//       return ColorCategory.Yellow;
//     case 'Red':
//       return ColorCategory.Red;
//     default:
//       return ColorCategory.Other;
//   }
// }

double _calculateDistance(
    int red, int green, int blue, ColorMetrics colorRange) {
  int rangeRed = (colorRange.range.red.min + colorRange.range.red.max) ~/ 2;
  int rangeGreen =
      (colorRange.range.green.min + colorRange.range.green.max) ~/ 2;
  int rangeBlue = (colorRange.range.blue.min + colorRange.range.blue.max) ~/ 2;

  return ((red - rangeRed).abs() +
          (green - rangeGreen).abs() +
          (blue - rangeBlue).abs())
      .toDouble();
}
