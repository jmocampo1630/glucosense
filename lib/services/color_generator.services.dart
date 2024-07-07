import 'dart:io';

import 'package:flutter/material.dart';
import 'package:glucolook/models/glucose_record.model.dart';
import 'package:glucolook/models/glucose.model.dart';
import 'package:glucolook/services/preferences.services.dart';
import 'package:intl/intl.dart';
import 'package:palette_generator/palette_generator.dart';

// default values
int defaultThreshold = 150;
int defaultType = 2;
List<ColorMetrics> colorRanges = [
  ColorMetrics(
    name: 'Very low = Hypoglycemia',
    range: ColorRange.fromColor(const Color(0xFFFDFDBA)),
    color: const Color(0xFFFDFDBA),
    value: 0.15,
    recommendations: [
      'Recognize symptoms such as shakiness, headache, and cold sweat.',
      'Promptly treat low blood glucose with glucagon if necessary, and ensure caregivers are trained in its administration.'
    ],
  ),
  ColorMetrics(
    name: 'Very low = Hypoglycemia',
    range: ColorRange.fromColor(const Color(0xFFF8EAB2)),
    color: const Color(0xFFF8EAB2),
    value: 0.31,
    recommendations: [
      'Recognize symptoms such as shakiness, headache, and cold sweat.',
      'Promptly treat low blood glucose with glucagon if necessary, and ensure caregivers are trained in its administration.'
    ],
  ),
  ColorMetrics(
    name: 'Very low = Hypoglycemia',
    range: ColorRange.fromColor(const Color(0xFFF3D8AA)),
    color: const Color(0xFFF3D8AA),
    value: 0.61,
    recommendations: [
      'Recognize symptoms such as shakiness, headache, and cold sweat.',
      'Promptly treat low blood glucose with glucagon if necessary, and ensure caregivers are trained in its administration.'
    ],
  ),
  ColorMetrics(
    name: 'Very low = Hypoglycemia',
    range: ColorRange.fromColor(const Color(0xFFEEC5A3)),
    color: const Color(0xFFEEC5A3),
    value: 1.22,
    recommendations: [
      'Recognize symptoms such as shakiness, headache, and cold sweat.',
      'Promptly treat low blood glucose with glucagon if necessary, and ensure caregivers are trained in its administration.'
    ],
  ),
  ColorMetrics(
    name: 'Very low = Hypoglycemia',
    range: ColorRange.fromColor(const Color(0xFFE9B29B)),
    color: const Color(0xFFE9B29B),
    value: 2.44,
    recommendations: [
      'Recognize symptoms such as shakiness, headache, and cold sweat.',
      'Promptly treat low blood glucose with glucagon if necessary, and ensure caregivers are trained in its administration.'
    ],
  ),
  ColorMetrics(
    name: 'Very low = Hypoglycemia',
    range: ColorRange.fromColor(const Color(0xFFE4A093)),
    color: const Color(0xFFE4A093),
    value: 4.88,
    recommendations: [
      'Recognize symptoms such as shakiness, headache, and cold sweat.',
      'Promptly treat low blood glucose with glucagon if necessary, and ensure caregivers are trained in its administration.'
    ],
  ),
  ColorMetrics(
    name: 'Very low = Hypoglycemia',
    range: ColorRange.fromColor(const Color(0xFFDF8D8B)),
    color: const Color(0xFFDF8D8B),
    value: 9.77,
    recommendations: [
      'Recognize symptoms such as shakiness, headache, and cold sweat.',
      'Promptly treat low blood glucose with glucagon if necessary, and ensure caregivers are trained in its administration.'
    ],
  ),
  ColorMetrics(
    name: 'Very low = Hypoglycemia',
    range: ColorRange.fromColor(const Color(0xFFDA7B83)),
    color: const Color(0xFFDA7B83),
    value: 19.53,
    recommendations: [
      'Recognize symptoms such as shakiness, headache, and cold sweat.',
      'Promptly treat low blood glucose with glucagon if necessary, and ensure caregivers are trained in its administration.'
    ],
  ),
  ColorMetrics(
    name: 'Low = Hypoglycemia',
    range: ColorRange.fromColor(const Color(0xFFD5687B)),
    color: const Color(0xFFD5687B),
    value: 39.06,
    recommendations: [
      'Recognize symptoms such as shakiness, headache, and cold sweat.',
      'Promptly treat low blood glucose with glucagon if necessary, and ensure caregivers are trained in its administration.'
    ],
  ),
  ColorMetrics(
    name: 'Normal',
    range: ColorRange.fromColor(const Color(0xFFD05574)),
    color: const Color(0xFFD05574),
    value: 78.13,
    recommendations: [
      'Maintain a proper diet, drink plenty of water, good exercise, and sleep at least 8 hours a day.',
      'Proper monitoring of glucose.'
    ],
  ),
  ColorMetrics(
    name: 'High = Hyperglycemia',
    range: ColorRange.fromColor(const Color(0xFFCB436E)),
    color: const Color(0xFFCB436E),
    value: 156.25,
    recommendations: [
      'Recognize symptoms such as fatigue, thirst, blurry vision, and frequent urination.',
      'Adjust diabetes management strategies, including meal plans, physical activity, or medications, as advised by healthcare providers.'
    ],
  ),
  ColorMetrics(
    name: 'Very High = Severe Hyperglycemia',
    range: ColorRange.fromColor(const Color(0xFFC63064)),
    color: const Color(0xFFC63064),
    value: 312.5,
    recommendations: [
      'Seek immediate medical attention if signs of diabetic ketoacidosis or hyperosmolar hyperglycemic state are present.',
      'Emergency treatment typically involves fluid and electrolyte replacement, along with insulin therapy.'
    ],
  ),
];

const imageSize = Size(256, 160);
PaletteGenerator? paletteGenerator;
Color defaultColor = Colors.white;

// Getter for defaultThreshold
Future<int> getDefaultThreshold() async {
  String? threshold = await getData('threshold');
  if (threshold != null) {
    return int.parse(threshold);
  } else {
    return defaultThreshold;
  }
}

// Setter for defaultThreshold
void setDefaultThreshold(int value) {
  defaultThreshold = value;
}

// Getter for defaultType
Future<int> getDefaultType() async {
  String? type = await getData('type');
  if (type != null) {
    return int.parse(type);
  } else {
    return defaultType;
  }
}

// Setter for defaultType
void setDefaultType(int value) {
  defaultType = value;
}

Future<GlucoseRecord?> generateColor(File? image) async {
  if (image == null) return null;
  DateTime now = DateTime.now();
  String formattedDate = DateFormat('yyyy-MM-dd hh:mm a').format(now);

  paletteGenerator = await PaletteGenerator.fromImageProvider(FileImage(image),
      size: imageSize,
      region: Rect.fromLTRB(0, 0, imageSize.width, imageSize.height));
  Color generatedColor = paletteGenerator != null
      ? paletteGenerator!.dominantColor != null
          ? paletteGenerator!.dominantColor!.color
          : defaultColor
      : defaultColor;

  ColorMetrics? glucoseLevel = await getTestResult(generatedColor);
  if (glucoseLevel != null) {
    return GlucoseRecord(
      id: '',
      name: glucoseLevel.name,
      value: glucoseLevel.value,
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

Future<ColorMetrics?> getTestResult(Color color) async {
  if (colorRanges.isEmpty) {
    return null;
  }
  int dtype = await getDefaultType();
  switch (dtype) {
    case 2:
      ColorMetrics? rangeResult = await classifyColor(color);
      return rangeResult;
    default:
      return diffMethod(color);
  }
}

Future<ColorMetrics?> diffMethod(Color color) async {
  if (colorRanges.isEmpty) {
    return null;
  }
  int thold = await getDefaultThreshold();
  int minDiff = isColorSimilar(color, colorRanges[0].color, thold);
  ColorMetrics? closestGlucoseLevel = colorRanges[0];

  for (var metric in colorRanges) {
    int diff = isColorSimilar(color, metric.color, thold);
    if (diff < minDiff) {
      minDiff = diff;
      closestGlucoseLevel = metric;
    }
  }
  if (minDiff > thold) {
    return null;
  }

  return closestGlucoseLevel;
}

Future<ColorMetrics?> classifyColor(Color dominantColor) async {
  int red = dominantColor.red;
  int green = dominantColor.green;
  int blue = dominantColor.blue;

  // Check if dominant color falls within any color range
  double minDistance = double.infinity;
  ColorMetrics? closestColor;
  int thold = await getDefaultThreshold();

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
  return minDistance <= thold ? closestColor : null;
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

List<String> getRecommendations(double glucoseValue) {
  // Assuming colorRanges is defined in the same scope
  ColorMetrics? matchingMetric;

  // Find the ColorMetrics corresponding to the given glucoseValue
  for (var metric in colorRanges) {
    if (glucoseValue <= metric.value) {
      matchingMetric = metric;
      break;
    }
  }

  // If no specific recommendation is found, use the last available one
  matchingMetric ??= colorRanges.last;

  // Return the recommendations
  return matchingMetric.recommendations;
}
