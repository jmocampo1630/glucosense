import 'package:flutter/material.dart';

@immutable
class BulletList extends StatelessWidget {
  final List<String> sentences;

  const BulletList({super.key, required this.sentences});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          sentences.map((sentence) => BulletPoint(sentence: sentence)).toList(),
    );
  }
}

class BulletPoint extends StatelessWidget {
  final String sentence;

  const BulletPoint({super.key, required this.sentence});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(fontSize: 20)),
        Expanded(child: Text(sentence)),
      ],
    );
  }
}
