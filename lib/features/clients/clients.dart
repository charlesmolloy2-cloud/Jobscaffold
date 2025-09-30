import 'package:flutter/material.dart';

// Entry point for the Clients feature
class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      body: const Center(child: Text('Client profiles and contact info here.')),
    );
  }
}
