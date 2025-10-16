import 'package:flutter/material.dart';

class HowToUseJobsPage extends StatelessWidget {
  const HowToUseJobsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('How to Use Jobs')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'How to Use Jobs',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _step('1. Tap “Create Job” or “Request a Job” to start a new job.'),
            _step('2. Fill in the job title, address, and description. Only the title is required.'),
            _step('3. (Optional) Add budget, start date, or due date.'),
            _step('4. Tap “Submit” to create the job. You’ll see it listed on your Jobs page.'),
            _step('5. To edit a job, tap the job and choose “Edit.”'),
            _step('6. To delete a job, tap the job and choose “Delete.”'),
            _step('7. Track job status and updates from the Jobs page.'),
            const SizedBox(height: 24),
            const Text(
              'Tips:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            _tip('• Use clear job titles so contractors/clients know what’s needed.'),
            _tip('• You can add more details or edit jobs later.'),
            _tip('• For quick jobs, just fill in the title and address.'),
            _tip('• If you need help, check the “How to Create a Job” page in More.'),
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
