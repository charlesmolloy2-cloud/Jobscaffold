import 'package:flutter/material.dart';

// Entry point for the Schedule feature
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule')),
      body: const Center(child: Text('Milestones, deadlines, and reminders here.')),
    );
  }
}
