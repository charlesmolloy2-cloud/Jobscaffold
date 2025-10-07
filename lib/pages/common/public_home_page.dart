import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/fade_in.dart';
import '../../widgets/slide_fade_in.dart';
import '../../widgets/temp_logo.dart';
import '../../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';

class PublicHomePage extends StatefulWidget {
  const PublicHomePage({super.key});

  @override
  State<PublicHomePage> createState() => _PublicHomePageState();
}

class _PublicHomePageState extends State<PublicHomePage> {
  final _scrollController = ScrollController();
  final _heroKey = GlobalKey();
  final _whatKey = GlobalKey();
  final _featuresKey = GlobalKey();
  final _contractorKey = GlobalKey();
  final _testimonialsKey = GlobalKey();
  final _ctaKey = GlobalKey();

  Future<void> _scrollTo(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 450),
      alignment: 0.1,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const TempLogo(size: 28),
        actions: [
          if (isWide) ...[
            TextButton(onPressed: () => _scrollTo(_whatKey), child: const Text('About')),
            TextButton(onPressed: () => _scrollTo(_featuresKey), child: const Text('Features')),
            TextButton(onPressed: () => _scrollTo(_contractorKey), child: const Text('Contractors')),
            TextButton(onPressed: () => _scrollTo(_testimonialsKey), child: const Text('Testimonials')),
            TextButton(onPressed: () => _scrollTo(_ctaKey), child: const Text('Contact')),
            const VerticalDivider(width: 24),
          ],
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/contractor_signin'),
            child: const Text('Contractor Login'),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/client_signin'),
            child: const Text('Customer Login'),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'reduce_motion') {
                final appState = context.read<AppState>();
                appState.setReduceMotion(!appState.reduceMotion);
              }
            },
            itemBuilder: (context) {
              final reduce = context.select<AppState, bool>((s) => s.reduceMotion);
              return [
                CheckedPopupMenuItem<String>(
                  value: 'reduce_motion',
                  checked: reduce,
                  child: const Text('Reduce motion'),
                ),
              ];
            },
          ),
        ],
      ),
      drawer: isWide
          ? null
          : Drawer(
              child: SafeArea(
                child: ListView(
                  children: [
                    const ListTile(title: Text('Navigate')),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('About'),
                      onTap: () {
                        Navigator.pop(context);
                        _scrollTo(_whatKey);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.widgets_outlined),
                      title: const Text('Features'),
                      onTap: () {
                        Navigator.pop(context);
                        _scrollTo(_featuresKey);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.engineering_outlined),
                      title: const Text('Contractors'),
                      onTap: () {
                        Navigator.pop(context);
                        _scrollTo(_contractorKey);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.reviews_outlined),
                      title: const Text('Testimonials'),
                      onTap: () {
                        Navigator.pop(context);
                        _scrollTo(_testimonialsKey);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.mail_outline),
                      title: const Text('Contact'),
                      onTap: () {
                        Navigator.pop(context);
                        _scrollTo(_ctaKey);
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.login),
                      title: const Text('Contractor Login'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/contractor_signin');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Customer Login'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/client_signin');
                      },
                    ),
                  ],
                ),
              ),
            ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FadeIn(delay: const Duration(milliseconds: 50), child: KeyedSubtree(key: _heroKey, child: _HeroSection(isWide: isWide))),
            const SizedBox(height: 24),
            FadeIn(delay: const Duration(milliseconds: 120), child: KeyedSubtree(key: _whatKey, child: _WhatIsSection(isWide: isWide))),
            const SizedBox(height: 24),
            FadeIn(delay: const Duration(milliseconds: 180), child: KeyedSubtree(key: _featuresKey, child: _FeaturesSection(isWide: isWide))),
            const SizedBox(height: 24),
            FadeIn(delay: const Duration(milliseconds: 240), child: KeyedSubtree(key: _contractorKey, child: _ContractorLoginSection(isWide: isWide))),
            const SizedBox(height: 24),
            FadeIn(delay: const Duration(milliseconds: 300), child: KeyedSubtree(key: _testimonialsKey, child: _TestimonialsSection(isWide: isWide))),
            const SizedBox(height: 36),
            FadeIn(delay: const Duration(milliseconds: 360), child: KeyedSubtree(key: _ctaKey, child: _CallToAction(isWide: isWide))),
            const SizedBox(height: 48),
            const _Footer(),
          ],
        ),
      ),
    );
  }
}

class _ContractorLoginSection extends StatelessWidget {
  final bool isWide;
  const _ContractorLoginSection({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? 1100 : 800),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contractor Logins',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Access your contractor tools and dashboard.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SlideFadeIn(
                    delay: const Duration(milliseconds: 80),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/contractor_signin'),
                      icon: const Icon(Icons.login),
                      label: const Text('Contractor Sign In'),
                    ),
                  ),
                  SlideFadeIn(
                    delay: const Duration(milliseconds: 140),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          Navigator.pushNamed(context, '/contractor_signin');
                        } else {
                          Navigator.pushNamed(context, '/admin');
                        }
                      },
                      icon: const Icon(Icons.dashboard_outlined),
                      label: const Text('Contractor Dashboard'),
                    ),
                  ),
                  SlideFadeIn(
                    delay: const Duration(milliseconds: 200),
                    child: TextButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/role_select'),
                      icon: const Icon(Icons.account_tree_outlined),
                      label: const Text('Choose Role'),
                    ),
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

class _HeroSection extends StatelessWidget {
  final bool isWide;
  const _HeroSection({required this.isWide});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 72),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kGreen, kLightGreenBg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 1100 : 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const TempLogo(size: 64),
              const SizedBox(height: 16),
              Text(
                'Plan. Build. Deliver — Together.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 34, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                'A modern platform that connects homeowners and contractors with clear communication, scheduling, and payments.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: kDarkGray),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  SlideFadeIn(
                    delay: const Duration(milliseconds: 80),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/client_signin'),
                      icon: const Icon(Icons.person_outline),
                      label: const Text('I am a Customer'),
                    ),
                  ),
                  SlideFadeIn(
                    delay: const Duration(milliseconds: 150),
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/contractor_signin'),
                      icon: const Icon(Icons.engineering_outlined),
                      label: const Text('I am a Contractor'),
                    ),
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

class _WhatIsSection extends StatelessWidget {
  final bool isWide;
  const _WhatIsSection({required this.isWide});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? 1100 : 800),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('What is Project Bridge?', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
              SizedBox(height: 12),
              Text(
                'Project Bridge is a simple way to plan, track, and complete home projects together. '
                'Customers get transparency and peace of mind. Contractors get tools to communicate, organize, '
                'and deliver great results — on time.',
                style: TextStyle(fontSize: 17, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  final bool isWide;
  const _FeaturesSection({required this.isWide});
  @override
  Widget build(BuildContext context) {
    final items = const [
      _Feature(icon: Icons.timeline, title: 'Live Updates', desc: 'Track progress and photos as they happen.'),
      _Feature(icon: Icons.chat_bubble_outline, title: 'Clear Messaging', desc: 'Stay aligned with built-in chat.'),
      _Feature(icon: Icons.receipt_long, title: 'Simple Payments', desc: 'Invoice and pay securely in one place.'),
      _Feature(icon: Icons.calendar_today, title: 'Smart Scheduling', desc: 'See milestones and deadlines on a shared calendar.'),
    ];
    final crossAxisCount = isWide ? 4 : 2;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? 1100 : 800),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Why people choose us', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: isWide ? 1.6 : 1.2,
                ),
                itemBuilder: (_, i) => SlideFadeIn(
                  delay: Duration(milliseconds: 80 + (i * 80)),
                  child: items[i],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _Feature({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: kGreenDark, size: 28),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(desc),
          ],
        ),
      ),
    );
  }
}

class _TestimonialsSection extends StatelessWidget {
  final bool isWide;
  const _TestimonialsSection({required this.isWide});
  @override
  Widget build(BuildContext context) {
    final testimonials = const [
      _Testimonial(name: 'Alex R.', role: 'Homeowner', quote: 'Project Bridge made my remodel stress-free. I always knew what was happening.'),
      _Testimonial(name: 'Casey M.', role: 'Contractor', quote: 'Scheduling, updates, and invoicing in one place — my crew loves it.'),
      _Testimonial(name: 'Jordan S.', role: 'Homeowner', quote: 'Transparent progress and easy payments. Highly recommend.'),
    ];
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? 1100 : 800),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('What people are saying', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: testimonials
                    .asMap()
                    .entries
                    .map((entry) {
                      final i = entry.key;
                      final t = entry.value;
                      return SizedBox(
                        width: isWide ? 350 : 320,
                        child: SlideFadeIn(delay: Duration(milliseconds: 80 + (i * 120)), child: t),
                      );
                    })
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Testimonial extends StatelessWidget {
  final String name;
  final String role;
  final String quote;
  const _Testimonial({required this.name, required this.role, required this.quote});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(role, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('“$quote”'),
          ],
        ),
      ),
    );
  }
}

class _CallToAction extends StatelessWidget {
  final bool isWide;
  const _CallToAction({required this.isWide});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? 1100 : 800),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Ready to get started?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  const Text('Join thousands of customers and contractors working better together.'),
                  const SizedBox(height: 16),
                  // Simple email capture (non-persistent placeholder)
                  _EmailCapture(),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      SlideFadeIn(
                        delay: const Duration(milliseconds: 80),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, '/client_signin'),
                          child: const Text('Customer Login'),
                        ),
                      ),
                      SlideFadeIn(
                        delay: const Duration(milliseconds: 140),
                        child: OutlinedButton(
                          onPressed: () => Navigator.pushNamed(context, '/contractor_signin'),
                          child: const Text('Contractor Login'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmailCapture extends StatefulWidget {
  @override
  State<_EmailCapture> createState() => _EmailCaptureState();
}

class _EmailCaptureState extends State<_EmailCapture> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final email = _email.text.trim();
      await FirebaseFirestore.instance.collection('leads').add({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'public_home',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks! We\'ll be in touch.')),
      );
      _email.clear();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 280,
            child: TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'you@example.com',
                labelText: 'Email',
              ),
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Enter your email';
                if (!value.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Notify Me'),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const TempLogo(size: 22, text: 'Project Bridge'),
          const SizedBox(height: 8),
          Text('© ${DateTime.now().year} Project Bridge', style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
