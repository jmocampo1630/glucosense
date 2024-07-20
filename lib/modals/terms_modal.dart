import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TermsModal extends StatelessWidget {
  const TermsModal({super.key});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Terms and Conditions for GlucoLook Application'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            _buildTermsText(),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Agree'),
          onPressed: () {
            Navigator.of(context).pop(true); // Return true if agreed
          },
        ),
        TextButton(
          child: const Text('Disagree'),
          onPressed: () {
            SystemNavigator.pop(); // Exit the app if disagreed
          },
        ),
      ],
    );
  }

  Widget _buildTermsText() {
    return Text.rich(
      TextSpan(
        children: [
          _buildTermSection(
            '1. Acceptance of Terms\n',
            'By downloading and using the GlucoLook application, you agree to comply with and be bound by these Terms and Conditions. If you do not agree with any part of these terms, you must not use the App.\n\n',
          ),
          _buildTermSection(
            '2. Changes to Terms\n',
            'We reserve the right to modify these Terms at any time. Any changes will be effective immediately upon posting within the App.\n\n',
          ),
          _buildTermSection(
            '3. User Responsibilities\n',
            'Users are responsible for maintaining the confidentiality of their account information and for all activities that occur under their account. You agree to notify us immediately of any unauthorized use of your account.\n\n',
          ),
          _buildTermSection(
            '4. Use of the Application\n',
            'You agree to use the App only for lawful purposes and in a manner that does not infringe the rights of others. The App is intended for personal use to assist in monitoring glucose levels non-invasively.\n\n',
          ),
          _buildTermSection(
            '5. Health Disclaimer\n',
            'The GlucoLook App is designed to provide a non-invasive method for monitoring glucose levels through saliva samples. However, it may not provide 100% accurate results and it is not intended as a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition.\n\n',
          ),
          _buildTermSection(
            '6. Limitation of Liability\n',
            'To the fullest extent permitted by law, we shall not be liable for any direct, indirect, incidental, special, consequential, or punitive damages arising from or related to your use of the App, including but not limited to any inaccuracies in glucose readings or health-related decisions made based on such readings.\n\n',
          ),
          _buildTermSection(
            '7. Data Management and Privacy\n',
            'We are committed to protecting your privacy. Any personal information collected through the App will be handled in accordance with our Privacy Policy. You consent to the collection, use, and sharing of your information as described in the Privacy Policy.\n\n',
          ),
          _buildTermSection(
            '8. Contact Information\n',
            'For any questions about these Terms, please contact us at GlucoLook@gmail.com.\n\n',
          ),
        ],
      ),
    );
  }

  TextSpan _buildTermSection(String title, String content) {
    return TextSpan(
      children: [
        TextSpan(
          text: title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        TextSpan(
          text: content,
          style: const TextStyle(fontSize: 14.0),
        ),
      ],
    );
  }
}
