import 'package:flutter/material.dart';
// ...existing code...
import 'features/home/homepage.dart';
import 'theme/app_theme.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Project Bridge',
      theme: AppTheme.light,
      home: const HomePage(),
    );
  }
}
