import 'package:flutter/material.dart';

class HowToUseJobScaffoldPage extends StatelessWidget {
  const HowToUseJobScaffoldPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  appBar: AppBar(title: const Text('How to Use JobScaffold')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Section 1: Getting Started',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _step('1. Open JobScaffold on your device or browser.'),
            _step('2. Sign in as a contractor or client using your email or phone.'),
            _step('3. Use the navigation bar or More tab to explore features like Jobs, Messaging, Calendar, and more.'),
            const SizedBox(height: 24),
            const Text(
              'Tips:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            _tip('• If you’re new, start with the Home page for a quick overview.'),
            _tip('• Use big buttons and clear labels to find what you need.'),
            _tip('• The More tab has extra features and help.'),
            const Divider(height: 40),
            const Text(
              'Section 2: Creating and Managing Jobs',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _step('1. Tap “Create Job” or “Request a Job” to start.'),
            _step('2. Fill in the job title, address, and description. Only the title is required.'),
            _step('3. (Optional) Add budget, start date, or due date.'),
            _step('4. Tap “Submit” to create the job. You’ll see it listed on your Jobs page.'),
            _step('5. To edit or update a job, tap the job and choose “Edit.”'),
            _step('6. To delete a job, tap the job and choose “Delete.”'),
            const SizedBox(height: 24),
            const Text(
              'Tips:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            _tip('• You can add more details later if needed.'),
            _tip('• Use clear job titles so contractors/clients know what’s needed.'),
            _tip('• If you need help, check the “How to Create a Job” page in More.'),
            const Divider(height: 40),
            const Text(
              'Section 3: Messaging, Notifications, and Support',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _step('1. Use the Messaging feature (in More tab) to chat with clients or contractors.'),
            _step('2. Check Notifications for updates about jobs, approvals, and payments.'),
            _step('3. If you need help, tap the Help or Support option in the More tab.'),
            _step('4. For urgent issues, contact support@jobscaffold.com.'),
            const SizedBox(height: 24),
            const Text(
              'Tips:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            _tip('• Enable notifications to stay updated on job progress.'),
            _tip('• Use messaging for quick questions or clarifications.'),
            _tip('• Support is always available if you get stuck.'),
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
