// submit_cancel_dialog.dart

import 'package:flutter/material.dart';

class SubmitCancelDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  final String submitText;
  final String cancelText;

  const SubmitCancelDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onSubmit,
    required this.onCancel,
    this.submitText = 'Submit',
    this.cancelText = 'Cancel',
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: onSubmit,
          child: Text(submitText),
        ),
      ],
    );
  }
}
