import 'package:flutter/material.dart';

// Entry point for the Invoices feature
class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoices')),
      body: const Center(child: Text('Invoice tracking and logs here.')),
    );
  }
}
