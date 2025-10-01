import 'package:flutter/material.dart';

class ContractorSignInPage extends StatelessWidget {
  const ContractorSignInPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contractor Sign In')),
      body: Center(
        child: ElevatedButton(
          child: const Text('Continue to Contractor Home'),
          onPressed: () => Navigator.pushReplacementNamed(context, '/admin'),
        ),
      ),
    );
  }
}
