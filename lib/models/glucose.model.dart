import 'dart:ui';

class ColorMetrics {
  String name;
  ColorRange range;
  final Color color;
  final double value;

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
