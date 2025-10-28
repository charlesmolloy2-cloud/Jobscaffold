import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MoreMenu extends StatelessWidget {
  const MoreMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.chat),
          title: const Text('Messaging'),
          onTap: () => Navigator.pushNamed(context, '/messaging'),
        ),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Notifications'),
          onTap: () => Navigator.pushNamed(context, '/notifications'),
        ),
        ListTile(
          leading: const Icon(Icons.check_box),
          title: const Text('Tasks & Checklists'),
          onTap: () => Navigator.pushNamed(context, '/tasks'),
        ),
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: const Text('Calendar'),
          onTap: () => Navigator.pushNamed(context, '/calendar'),
        ),
        ListTile(
          leading: const Icon(Icons.edit),
          title: const Text('E-signature & Approvals'),
          onTap: () => Navigator.pushNamed(context, '/esignature'),
        ),
        ListTile(
          leading: const Icon(Icons.payment),
          title: const Text('Payments & Invoicing'),
          onTap: () => Navigator.pushNamed(context, '/payments'),
        ),
        ListTile(
          leading: const Icon(Icons.feedback),
          title: const Text('Feedback & Ratings'),
          onTap: () => Navigator.pushNamed(context, '/feedback'),
        ),
        ListTile(
          leading: const Icon(Icons.archive),
          title: const Text('Project Archive'),
          onTap: () => Navigator.pushNamed(context, '/archive'),
        ),
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Profile & Settings'),
          onTap: () => Navigator.pushNamed(context, '/profile'),
        ),
        ListTile(
          leading: const Icon(Icons.language, color: kGreen),
          title: const Text('Localization'),
          onTap: () => Navigator.pushNamed(context, '/localization'),
        ),
        ListTile(
          leading: const Icon(Icons.analytics),
          title: const Text('Analytics & Reporting'),
          onTap: () => Navigator.pushNamed(context, '/analytics'),
        ),
        ListTile(
          leading: const Icon(Icons.attach_file),
          title: const Text('File Sharing'),
          onTap: () => Navigator.pushNamed(context, '/files'),
        ),
        ListTile(
          leading: const Icon(Icons.admin_panel_settings, color: Colors.orange),
          title: const Text('Leads Admin'),
          onTap: () => Navigator.pushNamed(context, '/leads_admin'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Privacy Policy'),
          onTap: () => Navigator.pushNamed(context, '/privacy'),
        ),
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('How to Create a Job'),
          onTap: () => Navigator.pushNamed(context, '/how_to_create_job'),
        ),
        ListTile(
          leading: const Icon(Icons.work_outline),
          title: const Text('How to Use Jobs'),
          onTap: () => Navigator.pushNamed(context, '/how_to_use_jobs'),
        ),
        ListTile(
          leading: const Icon(Icons.chat_bubble_outline),
          title: const Text('How to Use Messaging'),
          onTap: () => Navigator.pushNamed(context, '/how_to_use_messaging'),
        ),
        ListTile(
          leading: const Icon(Icons.calendar_today_outlined),
          title: const Text('How to Use Calendar'),
          onTap: () => Navigator.pushNamed(context, '/how_to_use_calendar'),
        ),
        ListTile(
          leading: const Icon(Icons.payment_outlined),
          title: const Text('How to Use Payments & Invoicing'),
          onTap: () => Navigator.pushNamed(context, '/how_to_use_payments'),
        ),
        ListTile(
          leading: const Icon(Icons.check_box_outlined),
          title: const Text('How to Use Tasks & Checklists'),
          onTap: () => Navigator.pushNamed(context, '/how_to_use_tasks'),
        ),
        ListTile(
          leading: const Icon(Icons.notifications_outlined),
          title: const Text('How to Use Notifications'),
          onTap: () => Navigator.pushNamed(context, '/how_to_use_notifications'),
        ),
        ListTile(
          leading: const Icon(Icons.attach_file_outlined),
          title: const Text('How to Use File Sharing'),
          onTap: () => Navigator.pushNamed(context, '/how_to_use_files'),
        ),
        ListTile(
          leading: const Icon(Icons.feedback_outlined),
          title: const Text('How to Use Feedback & Ratings'),
          onTap: () => Navigator.pushNamed(context, '/how_to_use_feedback'),
        ),
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text('How to Use Profile & Settings'),
          onTap: () => Navigator.pushNamed(context, '/how_to_use_profile'),
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('Terms of Service'),
          onTap: () => Navigator.pushNamed(context, '/terms'),
        ),
      ],
    );
  }
}
