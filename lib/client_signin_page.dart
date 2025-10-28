import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClientSignInPage extends StatefulWidget {
  const ClientSignInPage({Key? key}) : super(key: key);

  @override
  State<ClientSignInPage> createState() => _ClientSignInPageState();
}

class _ClientSignInPageState extends State<ClientSignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _signingIn = false;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load remembered email for clients
    () async {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('remember_email_client');
      if (saved != null && mounted) {
        setState(() {
          _emailController.text = saved;
          _rememberMe = true;
        });
      }
    }();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['signedOut'] == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed out')),
        );
      });
    }
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _signingIn = true);
    try {
      // Real Firebase Auth sign-in
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // Persist remembered email if opted in
      try {
        final prefs = await SharedPreferences.getInstance();
        if (_rememberMe) {
          await prefs.setString('remember_email_client', _emailController.text.trim());
        } else {
          await prefs.remove('remember_email_client');
        }
      } catch (_) {}
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/client',
        (route) => false,
        arguments: const {'signedIn': true},
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? e.code)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Customer sign-in failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If user is already authenticated, skip this screen entirely.
    final current = FirebaseAuth.instance.currentUser;
    if (current != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/client',
          (route) => false,
          arguments: const {'signedIn': true},
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If demo bypass is active, skip this screen entirely.
    final demoBypass = context.watch<AppState>().devBypassRole;
    if (demoBypass == 'client') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/client',
          (route) => false,
          arguments: const {'signedIn': true},
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Customer Sign In')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Welcome back to JobScaffold',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return 'Enter your email';
                      if (!value.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                  ),
                  CheckboxListTile(
                    value: _rememberMe,
                    onChanged: (v) => setState(() => _rememberMe = v ?? true),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Remember my email on this device'),
                  ),
                  if (_emailController.text.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove('remember_email_client');
                          setState(() {
                            _emailController.clear();
                            _rememberMe = false;
                          });
                        },
                        icon: const Icon(Icons.swap_horiz, size: 18),
                        label: const Text('Switch account'),
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _signingIn ? null : _signIn,
                    icon: _signingIn
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.login),
                    label: const Text('Enter JobScaffold'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _signingIn ? null : () => Navigator.pushReplacementNamed(context, '/'),
                    child: const Text('Back'),
                  ),
                  if (!kReleaseMode) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 28),
                    Text('Developer bypass', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.bolt_outlined),
                          label: const Text('Enter Client Dashboard'),
                          onPressed: () {
                            context.read<AppState>().enableDevBypass('client');
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/client',
                              (route) => false,
                              arguments: const {'signedIn': true},
                            );
                          },
                        ),
                        TextButton(
                          onPressed: () => context.read<AppState>().disableDevBypass(),
                          child: const Text('Disable bypass'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
