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
            'JobScaffold Terms of Service\n\n'
            'Last Updated: October 2025\n\n'
            '1. ACCEPTANCE OF TERMS\n'
            'By accessing or using JobScaffold, you agree to these Terms of Service. If you do not agree, do not use the service.\n\n'
            '2. USER ACCOUNTS\n'
            '• You must provide accurate information\n'
            '• You are responsible for account security\n'
            '• One person per account\n'
            '• You must be 18+ to use JobScaffold\n\n'
            '3. PERMITTED USE\n'
            '• JobScaffold is for managing construction and home improvement projects\n'
            '• You may not use the service for illegal activities\n'
            '• You may not harass or spam other users\n'
            '• You may not attempt to hack or disrupt the service\n\n'
            '4. CONTENT AND DATA\n'
            '• You retain ownership of content you create\n'
            '• You grant JobScaffold license to host and display your content\n'
            '• You are responsible for backing up important data\n'
            '• We may remove content that violates these terms\n\n'
            '5. PAYMENTS\n'
            '• Payments are processed through Stripe\n'
            '• Fees are set by contractors, not JobScaffold\n'
            '• Refunds are subject to contractor policies\n'
            '• JobScaffold may charge service fees in the future\n\n'
            '6. TERMINATION\n'
            '• You may close your account at any time\n'
            '• We may suspend accounts that violate terms\n'
            '• Data may be deleted after account closure\n\n'
            '7. DISCLAIMERS\n'
            '• Service provided "as is" without warranties\n'
            '• We are not liable for disputes between users\n'
            '• We are not responsible for contractor work quality\n\n'
            '8. CHANGES TO TERMS\n'
            'We may update these terms. Continued use means acceptance of updated terms.\n\n'
            '9. CONTACT\n'
            'For questions about these terms:\n'
            'Email: legal@jobscaffold.com',
            style: TextStyle(height: 1.5),
          ),
        ],
      ),
    );
  }
}
