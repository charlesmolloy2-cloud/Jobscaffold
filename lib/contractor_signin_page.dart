import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _rememberMe = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load remembered email for contractors
    () async {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('remember_email_contractor');
      if (saved != null && mounted) {
        setState(() {
          _email.text = saved;
          _rememberMe = true;
        });
      }
    }();
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
      // Persist remembered email if opted in
      try {
        final prefs = await SharedPreferences.getInstance();
        if (_rememberMe) {
          await prefs.setString('remember_email_contractor', _email.text.trim());
        } else {
          await prefs.remove('remember_email_contractor');
        }
      } catch (_) {}
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
      // Save email if available and remember is ON
      try {
        final email = FirebaseAuth.instance.currentUser?.email;
        if (email != null && _rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('remember_email_contractor', email);
        }
      } catch (_) {}
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
      // Save email if available and remember is ON
      try {
        final email = FirebaseAuth.instance.currentUser?.email;
        if (email != null && _rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('remember_email_contractor', email);
        }
      } catch (_) {}
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
    // If user is already authenticated, skip this screen entirely.
    final current = FirebaseAuth.instance.currentUser;
    if (current != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/admin',
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
    if (demoBypass == 'contractor') {
      // Navigate to contractor dashboard after the current frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/admin',
          (route) => false,
          arguments: const {'signedIn': true},
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                      CheckboxListTile(
                        value: _rememberMe,
                        onChanged: (v) => setState(() => _rememberMe = v ?? true),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Remember my email on this device'),
                      ),
                      if (_email.text.isNotEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () async {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.remove('remember_email_contractor');
                              setState(() {
                                _email.clear();
                                _rememberMe = false;
                              });
                            },
                            icon: const Icon(Icons.swap_horiz, size: 18),
                            label: const Text('Switch account'),
                          ),
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
