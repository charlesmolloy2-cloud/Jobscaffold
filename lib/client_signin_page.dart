import 'package:flutter/material.dart';

class ClientSignInPage extends StatelessWidget {
  const ClientSignInPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Client Sign In')),
      body: Center(
        child: ElevatedButton(
          child: const Text('Continue to Client Home'),
          onPressed: () => Navigator.pushReplacementNamed(context, '/client'),
        ),
      ),
    );
  }
}
