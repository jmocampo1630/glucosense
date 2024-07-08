import 'dart:ui';

class ColorMetrics {
  String name;
  final ColorRange range;
  final Color color;
  final double value;
  final List<String> recommendations;

  ColorMetrics({
    required this.name,
    required this.range,
    required this.color,
    required this.value,
    required this.recommendations,
  });
}

class ColorRange {
  final Range red;
  final Range blue;
  final Range green;

  ColorRange({
    required this.red,
    required this.blue,
    required this.green,
  });

  // Factory constructor to compute ranges automatically
  factory ColorRange.fromColor(Color color, {int tolerance = 10}) {
    int red = color.red;
    int green = color.green;
    int blue = color.blue;

    return ColorRange(
      red: Range(red - tolerance, red + tolerance),
      blue: Range(blue - tolerance, blue + tolerance),
      green: Range(green - tolerance, green + tolerance),
    );
  }
}

class Range {
  final int min;
  final int max;

  Range(int min, int max)
      : min = min.clamp(0, 255),
        max = max.clamp(0, 255),
        assert(min <= max, 'Min should be less than or equal to max');
}
