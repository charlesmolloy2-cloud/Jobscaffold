import 'package:flutter/material.dart';

class HowToUseFeedbackPage extends StatelessWidget {
  const HowToUseFeedbackPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('How to Use Feedback & Ratings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'How to Use Feedback & Ratings',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _step('1. Tap “Feedback & Ratings” in the More tab to view or leave feedback.'),
            _step('2. Select a job or contact to rate your experience.'),
            _step('3. Leave a star rating and write a short review.'),
            _step('4. Submit your feedback to help others and improve service.'),
            _step('5. View feedback you’ve received from clients or contractors.'),
            const SizedBox(height: 24),
            const Text(
              'Tips:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            _tip('• Be honest and constructive in your feedback.'),
            _tip('• Use ratings to choose reliable contractors or clients.'),
            _tip('• Check your own ratings to improve your service.'),
            _tip('• For feedback issues, contact support.'),
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
