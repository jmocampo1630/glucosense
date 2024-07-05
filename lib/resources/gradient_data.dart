// Linear interpolation: https://en.wikipedia.org/wiki/Linear_interpolation
import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';

double lerp(num a, num b, double t) {
  return a.toDouble() * (1.0 - t) + b.toDouble() * t;
}

// Inverse lerp: https://www.gamedev.net/articles/programming/general-and-gameplay-programming/inverse-lerp-a-super-useful-yet-often-overlooked-function-r5230/
double invlerp(num a, num b, num x) {
  return (x - a.toDouble()) / (b.toDouble() - a.toDouble());
}

// For interpolating between colors
Color lerpColor(Color a, Color b, double t) {
  int lerpInt(int a, int b, double t) => lerp(a, b, t).round();
  return Color.fromARGB(
    lerpInt(a.alpha, b.alpha, t),
    lerpInt(a.red, b.red, t),
    lerpInt(a.green, b.green, t),
    lerpInt(a.blue, b.blue, t),
  );
}

// Data class for gradient data
class GradientData {
  final List<double> stops;
  final List<Color> colors;

  GradientData(this.stops, this.colors) : assert(stops.length == colors.length);

  // Get the color value at any point in a gradient
  Color getColor(double t) {
    assert(stops.length == colors.length);
    if (t <= 0) return colors.first;
    if (t >= 1) return colors.last;

    for (int i = 0; i < stops.length - 1; i++) {
      final stop = stops[i];
      final nextStop = stops[i + 1];
      final color = colors[i];
      final nextColor = colors[i + 1];
      if (t >= stop && t < nextStop) {
        final lerpT = invlerp(stop, nextStop, t);
        return lerpColor(color, nextColor, lerpT);
      }
    }

    return colors.last;
  }

  // Calculate a new gradient for a subset of this gradient
  GradientData getConstrainedGradient(
      double dataYMin, // Min y-value of the data set
      double dataYMax, // Max y-value of the data set
      double graphYMin, // Min value of the y-axis
      double graphYMax, // Max value of the y-axis
      {double opacity = 1.0}) {
    // The "new" beginning and end stop positions for the gradient
    final tMin = invlerp(graphYMin, graphYMax, dataYMin);
    final tMax = invlerp(graphYMin, graphYMax, dataYMax);

    final newStops = <double>[];
    final newColors = <Color>[];

    newStops.add(0);
    newColors.add(getColor(tMin));

    for (int i = 0; i < stops.length; i++) {
      final stop = stops[i];
      final color = colors[i].withOpacity(opacity);
      if (stop <= tMin || stop >= tMax) continue;
      final stopT = invlerp(tMin, tMax, stop);
      newStops.add(stopT);
      newColors.add(color);
    }

    newStops.add(1);
    newColors.add(getColor(tMax));

    return GradientData(newStops, newColors);
  }
}

class GraphHelper {
  double findMaxValue(List<FlSpot> spots) {
    double maxY = 0;
    for (FlSpot spot in spots) {
      if (spot.y > maxY) {
        maxY = spot.y;
      }
    }
    return maxY;
  }

  double findMinValue(List<FlSpot> spots) {
    double minY = double.infinity;
    for (FlSpot spot in spots) {
      if (spot.y < minY) {
        minY = spot.y;
      }
    }
    return minY;
  }
}
