import 'package:flutter/material.dart';

class HowToUseNotificationsPage extends StatelessWidget {
  const HowToUseNotificationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('How to Use Notifications')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'How to Use Notifications',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _step('1. Tap “Notifications” in the More tab to view alerts and updates.'),
            _step('2. See new messages, job status changes, approvals, and payments.'),
            _step('3. Tap a notification to view details or take action.'),
            _step('4. Clear notifications after reading them to stay organized.'),
            const SizedBox(height: 24),
            const Text(
              'Tips:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            _tip('• Enable push notifications to get real-time updates.'),
            _tip('• Check notifications regularly to avoid missing important info.'),
            _tip('• For notification settings, visit Profile & Settings.'),
            _tip('• Contact support if you’re not receiving notifications.'),
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
