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
            'JobScaffold Privacy Policy\n\n'
            'Last Updated: October 2025\n\n'
            '1. INFORMATION WE COLLECT\n'
            'We collect information you provide when you:\n'
            '• Create an account (name, email, role)\n'
            '• Create or manage jobs (project details, photos, updates)\n'
            '• Communicate through the app (messages, comments)\n'
            '• Use app features (calendar events, tasks, payments)\n\n'
            '2. HOW WE USE YOUR INFORMATION\n'
            '• Provide and maintain JobScaffold services\n'
            '• Send notifications about job updates\n'
            '• Improve app functionality and user experience\n'
            '• Prevent fraud and ensure security\n'
            '• Comply with legal obligations\n\n'
            '3. DATA SHARING\n'
            '• We DO NOT sell your personal information\n'
            '• Job data is shared only with project collaborators you invite\n'
            '• We use Firebase for hosting (Google Cloud Platform)\n'
            '• We use Stripe for payment processing\n\n'
            '4. DATA SECURITY\n'
            '• All data is encrypted in transit and at rest\n'
            '• Regular security audits and updates\n'
            '• Access controls and authentication\n\n'
            '5. YOUR RIGHTS\n'
            '• Access your data at any time\n'
            '• Request data deletion\n'
            '• Export your data\n'
            '• Opt-out of non-essential notifications\n\n'
            '6. CONTACT US\n'
            'For privacy questions or data requests:\n'
            'Email: privacy@jobscaffold.com\n\n'
            'By using JobScaffold, you agree to this Privacy Policy.',
            style: TextStyle(height: 1.5),
          ),
        ],
      ),
    );
  }
}
