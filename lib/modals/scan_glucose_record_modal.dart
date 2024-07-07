import 'package:flutter/material.dart';
import 'package:glucolook/models/glucose_record.model.dart';
import 'package:glucolook/services/color_generator.services.dart';

class ScanGlucoseRecordModal extends StatefulWidget {
  const ScanGlucoseRecordModal({super.key, required this.glucoseRecord});
  final GlucoseRecord glucoseRecord;

  @override
  State<ScanGlucoseRecordModal> createState() => _ScanGlucoseRecordModalState();
}

class _ScanGlucoseRecordModalState extends State<ScanGlucoseRecordModal> {
  @override
  Widget build(BuildContext context) {
    // final recommendations = getRecommendations(widget.glucoseRecord.value);
    return AlertDialog(
      title: const Center(child: Text('Glucose Record')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 100,
            height: 100,
            color: widget.glucoseRecord.color,
          ),
          const Text(
            'Glucose Level:',
            style: TextStyle(fontSize: 16.0),
          ),
          Text('${widget.glucoseRecord.value} mg/dL',
              style:
                  const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
          Text(widget.glucoseRecord.name,
              style: const TextStyle(fontSize: 16.0)),
        ],
      ),
      actions: <Widget>[
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                child: const Text('Retry'),
                onPressed: () {
                  Navigator.pop(context, false);
                },
              ),
              const SizedBox(width: 16), // Optional spacing between buttons
              ElevatedButton(
                child: const Text('Submit'),
                onPressed: () {
                  Navigator.pop(context, true);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
