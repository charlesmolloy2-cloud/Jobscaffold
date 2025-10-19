import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/blueprint_background.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlueprintBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('JobScaffold', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('Plan. Build. Deliver — Together.', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
                    icon: const Icon(Icons.public),
                    label: const Text('Explore Site'),
                    style: FilledButton.styleFrom(backgroundColor: kGreen, foregroundColor: kWhite),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed('/demo_login'),
                    icon: const Icon(Icons.login),
                    label: const Text('Demo Login'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
