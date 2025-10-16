import 'package:flutter/material.dart';

class HowToCreateJobPage extends StatelessWidget {
  const HowToCreateJobPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('How to Create a Job')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Step-by-Step: Creating a Job',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _step('1. Tap the “Create Job” or “Request a Job” button.'),
            _step('2. Enter a clear job title (e.g., “Mow front lawn” or “Install kitchen tiles”).'),
            _step('3. Add the job address. If not sure, type “TBD” or your city.'),
            _step('4. Describe the work needed. Be as specific as you like.'),
            _step('5. (Optional) Enter your budget or leave blank.'),
            _step('6. (Optional) Pick a start date if you know it.'),
            _step('7. Review your info and tap “Submit” or “Create.”'),
            const SizedBox(height: 24),
            const Text(
              'Tips:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            _tip('• You can always edit or add details later.'),
            _tip('• If you get stuck, look for “?” icons or help buttons.'),
            _tip('• For quick jobs, just fill in the title and address.'),
            _tip('• Contact support if you need help.'),
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
