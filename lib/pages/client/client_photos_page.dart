import 'package:flutter/material.dart';

class ClientPhotosPage extends StatelessWidget {
  const ClientPhotosPage({super.key});

  @override
  Widget build(BuildContext context) {
    // In a real app, this would fetch files from backend or state
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('Photos & Files shared by your contractor will appear here.'),
          // TODO: List files for download/view
        ],
      ),
    );
  }
}
