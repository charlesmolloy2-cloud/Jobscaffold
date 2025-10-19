import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kSteelBlue, kDarkBg],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        width: double.infinity,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('JobScaffold', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('Plan. Build. Deliver — Together.', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
                icon: const Icon(Icons.login),
                label: const Text('Enter App'),
                style: FilledButton.styleFrom(backgroundColor: kGreen, foregroundColor: kWhite),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
