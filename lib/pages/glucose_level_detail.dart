import 'package:flutter/material.dart';
import 'package:glucolook/models/glucose_record.model.dart';
import 'package:glucolook/resources/components/bullet_list.dart';
import 'package:glucolook/services/color_generator.services.dart';

class GlucoseLevelDetail extends StatefulWidget {
  const GlucoseLevelDetail({super.key, required this.glucoseRecord});
  final GlucoseRecord glucoseRecord;

  @override
  State<GlucoseLevelDetail> createState() => _GlucoseLevelDetailState();
}

class _GlucoseLevelDetailState extends State<GlucoseLevelDetail> {
  @override
  Widget build(BuildContext context) {
    List<String> recommendations =
        getRecommendations(widget.glucoseRecord.value);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Glucose Record"),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: 50),
          ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: Container(
              width: 100,
              height: 100,
              color: widget.glucoseRecord.color,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Glucose Level:',
            style: TextStyle(fontSize: 18.0),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${widget.glucoseRecord.value} mg/dL',
                  style: const TextStyle(
                      fontSize: 20.0, fontWeight: FontWeight.bold)),
            ],
          ),
          Text(widget.glucoseRecord.name,
              style: const TextStyle(fontSize: 18.0)),
          const SizedBox(height: 20),
          Card(
            margin: const EdgeInsets.symmetric(
                horizontal:
                    16.0), // Adjusts the horizontal margin to make the card smaller
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Recommendations/Suggestions',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(
                      height:
                          16.0), // Adds space between the title and the list
                  BulletList(
                    sentences: recommendations,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
