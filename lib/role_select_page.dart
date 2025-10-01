import 'package:flutter/material.dart';
import 'home_page.dart';

class RoleSelectPage extends StatelessWidget {
  const RoleSelectPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFFAF3),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome to Project Bridge',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_outline),
                label: const Text('Client'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(220, 48),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                onPressed: () => Navigator.pushReplacementNamed(context, '/client_signin'),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                icon: const Icon(Icons.engineering_outlined),
                label: const Text('Contractor'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(220, 48),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                onPressed: () => Navigator.pushReplacementNamed(context, '/contractor_signin'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
