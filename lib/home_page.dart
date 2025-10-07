// lib/home_page.dart
// Flutter Home Page for Project Bridge
// - Admin sign-in
// - Client sign-in
// - Programmer bypass for Customer and Contractor
// Drop this file into your lib/ folder and wire routes '/admin' and '/client' to your existing screens.
// Replace the TODOs with your actual authentication and app-state logic.

import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  static const routeName = '/home';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Admin form controllers
  final _adminEmail = TextEditingController();
  final _adminPassword = TextEditingController();
  final _adminFormKey = GlobalKey<FormState>();

  // Client form controllers
  final _clientEmail = TextEditingController();
  final _clientPassword = TextEditingController();
  final _clientFormKey = GlobalKey<FormState>();

  // Programmer bypass controllers
  final _devPinController = TextEditingController();
  final _bypassIdController = TextEditingController();
  String _bypassType = 'Customer'; // 'Customer' or 'Contractor'
  bool _showBypass = false;
  bool _adminSigningIn = false;
  bool _clientSigningIn = false;
  bool _bypassProcessing = false;

  // Replace this with secure config / env retrieval for real use.
  // static const _devPinSecret = '1234'; // For demo only

  @override
  void dispose() {
    _adminEmail.dispose();
    _adminPassword.dispose();
    _clientEmail.dispose();
    _clientPassword.dispose();
    _devPinController.dispose();
    _bypassIdController.dispose();
    super.dispose();
  }

  // ===== Integration hooks =====
  Future<void> _handleAdminSignIn() async {
    if (!_adminFormKey.currentState!.validate()) return;
    setState(() => _adminSigningIn = true);
    try {
  // final email = _adminEmail.text.trim();
  // final password = _adminPassword.text;
      // TODO: Replace with your Auth call (Firebase/Auth or AppState)
      // Example:
      // await AuthService.signInAsAdmin(email, password);
      await Future.delayed(const Duration(milliseconds: 700)); // simulate
      // On success:
      if (!mounted) return;
      Navigator.pushNamed(context, '/admin');
    } catch (e) {
      _showError('Admin sign-in failed: $e');
    } finally {
      setState(() => _adminSigningIn = false);
    }
  }

  Future<void> _handleClientSignIn() async {
    if (!_clientFormKey.currentState!.validate()) return;
    setState(() => _clientSigningIn = true);
    try {
  // final email = _clientEmail.text.trim();
  // final password = _clientPassword.text;
      // TODO: Replace with your Auth call (Firebase/Auth or AppState)
      // Example:
      // await AuthService.signInAsClient(email, password);
      await Future.delayed(const Duration(milliseconds: 700)); // simulate
      if (!mounted) return;
      Navigator.pushNamed(context, '/client');
    } catch (e) {
      _showError('Client sign-in failed: $e');
    } finally {
      setState(() => _clientSigningIn = false);
    }
  }

  // Programmer bypass: validate PIN and user id, then create a session as the chosen entity
  Future<void> _handleProgrammerBypass() async {
    final pin = _devPinController.text.trim();
    final id = _bypassIdController.text.trim();
    if (pin.isEmpty || id.isEmpty) {
      _showError('Enter both developer PIN and the target ID.');
      return;
    }

    setState(() => _bypassProcessing = true);
    try {
      // Demo logic: allow bypass if both PIN and ID are '1234'
      if (pin != '1234' || id != '1234') {
        throw 'Invalid developer PIN or Target ID';
      }

      await Future.delayed(const Duration(milliseconds: 700)); // simulate

      if (!mounted) return;
      final destination =
          (_bypassType == 'Customer') ? '/client' : '/admin';
      Navigator.pushNamed(context, destination);
    } catch (e) {
      _showError('Programmer bypass failed: $e');
    } finally {
      setState(() => _bypassProcessing = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isWide = mq.size.width > 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Bridge'),
        actions: [
          IconButton(
            tooltip: 'Toggle programmer bypass',
            onPressed: () => setState(() => _showBypass = !_showBypass),
            icon: const Icon(Icons.developer_mode),
          ),
          IconButton(
            tooltip: 'Switch Role',
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 1000 : 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                _buildIntroCard(),
                const SizedBox(height: 18),
                Flex(
                  direction: isWide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: _buildAdminCard()),
                    const SizedBox(width: 16, height: 16),
                    Expanded(child: _buildClientCard()),
                  ],
                ),
                const SizedBox(height: 18),
                if (_showBypass) _buildBypassCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Welcome to Project Bridge',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text(
              'Sign in as Admin (contractor side) or Client (customer side). '
              'If you are debugging or need to jump in as a specific user, toggle the developer bypass (top-right).',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Form(
          key: _adminFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Admin / Contractor Sign-in',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _adminEmail,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter email';
                  if (!v.contains('@')) return 'Enter valid email';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _adminPassword,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter password';
                  if (v.length < 6) return 'Min 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _adminSigningIn ? null : _handleAdminSignIn,
                child: _adminSigningIn
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sign in as Admin'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  // TODO: wire to admin register / forgot password flow
                  _showError('Admin registration / forgot password not implemented yet.');
                },
                child: const Text('Register / Forgot password'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Form(
          key: _clientFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Client / Customer Sign-in',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _clientEmail,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter email';
                  if (!v.contains('@')) return 'Enter valid email';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _clientPassword,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter password';
                  if (v.length < 6) return 'Min 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _clientSigningIn ? null : _handleClientSignIn,
                child: _clientSigningIn
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sign in as Client'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  // TODO: wire to client register / forgot password flow
                  _showError('Client registration / forgot password not implemented yet.');
                },
                child: const Text('Register / Forgot password'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBypassCard() {
    return Card(
      elevation: 3,
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Programmer Bypass (DEBUG ONLY)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
              'Use this only for development. Enter the developer PIN and the ID of the Customer or Contractor you want to impersonate.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Bypass type:'),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _bypassType,
                  items: const [
                    DropdownMenuItem(value: 'Customer', child: Text('Customer')),
                    DropdownMenuItem(value: 'Contractor', child: Text('Contractor')),
                  ],
                  onChanged: (v) => setState(() {
                    if (v != null) _bypassType = v;
                  }),
                )
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bypassIdController,
              decoration: const InputDecoration(
                labelText: 'Target ID (customerId or contractorId)',
                hintText: 'ex: cust_12345 or cont_67890',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _devPinController,
              decoration: const InputDecoration(
                labelText: 'Developer PIN',
                hintText: 'Enter developer bypass PIN',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _bypassProcessing ? null : _handleProgrammerBypass,
                  icon: _bypassProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: const Text('Bypass & Sign in'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _devPinController.clear();
                      _bypassIdController.clear();
                    });
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Note: This bypass must be implemented server-side for security in production. '
              'Never leave developer PINs in client builds.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple placeholder pages you can navigate to. Replace with your real screens.
class AdminHomePlaceholder extends StatelessWidget {
  const AdminHomePlaceholder({Key? key}) : super(key: key);

  static const routeName = '/admin';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: const Center(child: Text('Admin dashboard placeholder')),
    );
  }
}

class ClientHomePlaceholder extends StatelessWidget {
  const ClientHomePlaceholder({Key? key}) : super(key: key);

  static const routeName = '/client';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Client Dashboard')),
      body: const Center(child: Text('Client dashboard placeholder')),
    );
  }
}
