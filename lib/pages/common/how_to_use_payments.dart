import 'package:flutter/material.dart';

class HowToUsePaymentsPage extends StatelessWidget {
  const HowToUsePaymentsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('How to Use Payments & Invoicing')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'How to Use Payments & Invoicing',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _step('1. Tap “Payments & Invoicing” in the More tab to view payment options.'),
            _step('2. See outstanding invoices and payment history.'),
            _step('3. To send an invoice, select a job and tap “Send Invoice.”'),
            _step('4. Enter the amount and details, then send to your client.'),
            _step('5. Clients can pay securely through the app.'),
            _step('6. Track payment status and get notified when paid.'),
            const SizedBox(height: 24),
            const Text(
              'Tips:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            _tip('• Always review invoice details before sending.'),
            _tip('• Use clear descriptions for each invoice.'),
            _tip('• Check payment history to track your earnings.'),
            _tip('• For payment issues, contact support.'),
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
