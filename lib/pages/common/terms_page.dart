import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text(
            'Terms of Service',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          Text(
            'This is a placeholder Terms of Service for the Site bench web app.\n\n'
            '• Use of the service is subject to these terms.\n'
            '• You agree to provide accurate information.\n'
            '• Payments and refunds are processed via Stripe.\n\n'
            'Replace this text with your actual terms before launch.',
          ),
        ],
      ),
    );
  }
}
