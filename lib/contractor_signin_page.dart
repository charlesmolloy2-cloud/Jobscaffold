import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:provider/provider.dart';
import 'state/app_state.dart';

class ContractorSignInPage extends StatefulWidget {
  const ContractorSignInPage({Key? key}) : super(key: key);

  @override
  State<ContractorSignInPage> createState() => _ContractorSignInPageState();
}

class _ContractorSignInPageState extends State<ContractorSignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['signedOut'] == true) {
      // Delay to ensure Scaffold is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed out')),
        );
      });
    }
  }

  Future<void> _signInEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/admin',
        (route) => false,
        arguments: const {'signedIn': true},
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? e.code);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        // Placeholder for mobile Google sign-in wiring
        throw UnsupportedError('Google Sign-In is only wired for web in this demo');
      }
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/admin',
        (route) => false,
        arguments: const {'signedIn': true},
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? e.code);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithMicrosoft() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (kIsWeb) {
        // Microsoft OAuth via generic OAuthProvider on web
        final provider = OAuthProvider('microsoft.com');
        provider.addScope('User.Read');
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        throw UnsupportedError('Microsoft Sign-In is only wired for web in this demo');
      }
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/admin',
        (route) => false,
        arguments: const {'signedIn': true},
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? e.code);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contractor Sign In')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  Container(
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                    padding: const EdgeInsets.all(12),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(height: 12),
                ],
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _email,
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
                        controller: _password,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Password'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _busy ? null : _signInEmail,
                        icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.lock_open),
                        label: const Text('Sign In'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 28),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _signInWithGoogle,
                      icon: const Icon(Icons.g_mobiledata),
                      label: const Text('Continue with Google'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _signInWithMicrosoft,
                      icon: const Icon(Icons.account_circle_outlined),
                      label: const Text('Continue with Microsoft'),
                    ),
                  ],
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
                        label: const Text('Enter Contractor Dashboard'),
                        onPressed: () {
                          context.read<AppState>().enableDevBypass('contractor');
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/admin',
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
    );
  }
}
