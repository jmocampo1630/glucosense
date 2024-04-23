import 'dart:ui';

class GlucoseLevel {
  final int value;
  final Color color;

  GlucoseLevel({required this.value, required this.color});
}

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
