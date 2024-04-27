import 'dart:ui';

class GlucoseRecord {
  final String name;
  final String description;
  final DateTime date;
  final Color color;

  GlucoseRecord({
    required this.name,
    required this.description,
    required this.date,
    required this.color,
  });
}

class ColorMetrics {
  String name;
  ColorRange range;
  final Color color;
  final int value;

  ColorMetrics(this.name, this.range, this.color, this.value);
}

class ColorRange {
  Range red;
  Range blue;
  Range green;

  ColorRange(this.red, this.blue, this.green);
}

class Range {
  int min;
  int max;
  Range(this.min, this.max);
}
