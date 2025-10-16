import 'package:flutter/material.dart';

class HowToUseProfilePage extends StatelessWidget {
  const HowToUseProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('How to Use Profile & Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'How to Use Profile & Settings',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _step('1. Tap “Profile & Settings” in the More tab to view your account.'),
            _step('2. Update your name, contact info, and profile photo.'),
            _step('3. Change notification preferences and privacy settings.'),
            _step('4. Review your job history and ratings.'),
            _step('5. Log out or delete your account if needed.'),
            const SizedBox(height: 24),
            const Text(
              'Tips:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            _tip('• Keep your contact info up to date for job notifications.'),
            _tip('• Adjust privacy settings to control what others see.'),
            _tip('• Review your ratings to improve your service.'),
            _tip('• For account issues, contact support.'),
          ],
        ),
      ),
    );
  }

  Widget _step(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
          ],
        ),
      );

  Widget _tip(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
          ],
        ),
      );
}
