import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text(
            'Privacy Policy',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          Text(
            'This is a placeholder privacy policy for the Project Bridge web app.\n\n'
            '• We collect profile information you provide (name, email).\n'
            '• We process project data you create (jobs, updates, files).\n'
            '• We use Firebase for authentication and data storage.\n'
            '• Payments are processed via Stripe.\n\n'
            'Replace this text with your actual policy before launch.',
          ),
        ],
      ),
    );
  }
}
