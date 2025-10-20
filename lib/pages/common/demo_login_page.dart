import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../models/user.dart';
import '../../roles/role.dart';

class DemoLoginPage extends StatefulWidget {
  const DemoLoginPage({super.key});

  @override
  State<DemoLoginPage> createState() => _DemoLoginPageState();
}

class _DemoLoginPageState extends State<DemoLoginPage> {
  final _userCtrl = TextEditingController(text: 'Admin1234');
  final _passCtrl = TextEditingController(text: '1234');
  bool _obscure = true;
  String? _error;
  UserRole _role = UserRole.contractor; // default

  void _signIn() {
    final username = _userCtrl.text.trim();
    final pass = _passCtrl.text;
    if (username.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Please enter username and password.');
      return;
    }
    // Simple local demo gate
    if (username != 'Admin1234' || pass != '1234') {
      setState(() => _error = 'Invalid credentials. Use Admin1234 / 1234');
      return;
    }
  final displayName = _role == UserRole.contractor ? 'Demo Contractor' : 'Demo Customer';
  final user = AppUser(id: 'demo-${_role.name}', name: displayName, role: _role);
  final appState = context.read<AppState>();
  appState.signInAs(user);
  appState.enableDevBypass(_role.name);
    // Navigate to chosen dashboard
    final target = _role == UserRole.contractor ? '/admin' : '/client';
    Navigator.of(context).pushNamedAndRemoveUntil(target, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demo Login')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Sign in with demo credentials', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('User: Admin1234    Password: 1234', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _userCtrl,
                        decoration: const InputDecoration(labelText: 'Username'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Role'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<UserRole>(
                      value: _role,
                      items: const [
                        DropdownMenuItem(value: UserRole.contractor, child: Text('Contractor')),
                        DropdownMenuItem(value: UserRole.client, child: Text('Customer')),
                      ],
                      onChanged: (v) => setState(() => _role = v ?? UserRole.contractor),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _signIn,
                  icon: const Icon(Icons.login),
                  label: const Text('Sign In'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
