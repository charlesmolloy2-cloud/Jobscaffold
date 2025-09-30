import 'package:flutter/material.dart';

// Entry point for the Auth feature
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: const Center(child: Text('Login, logout, and account management here.')),
    );
  }
}

enum UserRole { contractor, client }

typedef OnLogin = void Function(UserRole role);

class LoginScreen extends StatefulWidget {
  final OnLogin onLogin;
  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  UserRole? _selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select your role:'),
            ListTile(
              title: const Text('Contractor / Admin'),
              leading: Radio<UserRole>(
                value: UserRole.contractor,
                groupValue: _selectedRole,
                onChanged: (UserRole? value) {
                  setState(() {
                    _selectedRole = value;
                  });
                },
              ),
            ),
            ListTile(
              title: const Text('Client / Customer'),
              leading: Radio<UserRole>(
                value: UserRole.client,
                groupValue: _selectedRole,
                onChanged: (UserRole? value) {
                  setState(() {
                    _selectedRole = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _selectedRole == null
                  ? null
                  : () => widget.onLogin(_selectedRole!),
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
