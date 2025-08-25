import 'dart:io';

import 'package:flutter/material.dart';
import 'package:glucolook/models/glucose_record.model.dart';
import 'package:glucolook/widgets/tags_input_widget.dart';

class ScanGlucoseRecordModal extends StatefulWidget {
  const ScanGlucoseRecordModal(
      {super.key, required this.glucoseRecord, required this.image});
  final GlucoseRecord glucoseRecord;
  final File image;

  @override
  State<ScanGlucoseRecordModal> createState() => _ScanGlucoseRecordModalState();
}

class _ScanGlucoseRecordModalState extends State<ScanGlucoseRecordModal> {
  final TextEditingController _notesController = TextEditingController();
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.glucoseRecord.description;
    _tags = List.from(widget.glucoseRecord.tags);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bloodtype, color: Color(0xFF37B5B6)),
          SizedBox(width: 8),
          Text('Glucose Record'),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image(
                  image: FileImage(widget.image),
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Glucose Level',
                style: TextStyle(fontSize: 16.0, color: Colors.black54),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipOval(
                    child: Container(
                      width: 20,
                      height: 20,
                      color: widget.glucoseRecord.color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.glucoseRecord.value} mg/dL',
                    style: const TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF37B5B6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                widget.glucoseRecord.name,
                style: const TextStyle(
                    fontSize: 16.0, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Notes (optional):',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints:
                    const BoxConstraints(minHeight: 80, maxHeight: 120),
                child: TextField(
                  controller: _notesController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: 'Add notes...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tags (optional):',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
              TagsInputWidget(
                initialTags: _tags,
                onTagsChanged: (tags) {
                  setState(() {
                    _tags = tags;
                  });
                },
                hintText: 'Add tags',
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Retry'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF37B5B6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  // Update the glucose record with the notes and tags
                  final updatedRecord = GlucoseRecord(
                    id: widget.glucoseRecord.id,
                    name: widget.glucoseRecord.name,
                    value: widget.glucoseRecord.value,
                    description: _notesController.text.trim(),
                    date: widget.glucoseRecord.date,
                    color: widget.glucoseRecord.color,
                    tags: _tags,
                  );
                  Navigator.pop(context, updatedRecord);
                },
                child: const Text('Submit'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
