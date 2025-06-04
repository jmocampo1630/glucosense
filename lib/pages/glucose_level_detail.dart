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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 24),
          child: Center(
            child: Card(
              elevation: 5,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: Container(
                        width: 90,
                        height: 90,
                        color: widget.glucoseRecord.color,
                        child: const Icon(Icons.bloodtype,
                            size: 54, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      widget.glucoseRecord.name,
                      style: const TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF37B5B6),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${widget.glucoseRecord.value} mg/dL',
                      style: TextStyle(
                        fontSize: 26.0,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Glucose Level',
                      style: TextStyle(fontSize: 15.0, color: Colors.black54),
                    ),
                    const SizedBox(height: 28),
                    Divider(thickness: 1.2, color: Colors.grey[300]),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Icon(Icons.tips_and_updates,
                            color: Color(0xFF37B5B6)),
                        const SizedBox(width: 8),
                        Text(
                          'Recommendations',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    BulletList(sentences: recommendations),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
