import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../widgets/temp_logo.dart';
import '../../widgets/slide_fade_in.dart';
import '../../widgets/blueprint_background.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';

class ContractorsPageV2 extends StatefulWidget {
  const ContractorsPageV2({super.key});

  @override
  State<ContractorsPageV2> createState() => _ContractorsPageV2State();
}

class _ContractorsPageV2State extends State<ContractorsPageV2> {
  final _scrollController = ScrollController();
  final _benefitsKey = GlobalKey();
  final _featuresKey = GlobalKey();
  final _analyticsKey = GlobalKey();
  final _pricingKey = GlobalKey();
  final _faqKey = GlobalKey();

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
        title: const TempLogo(size: 28, text: 'JobScaffold'),
        actions: [
          if (isWide) ...[
            TextButton(onPressed: () => _scrollTo(_benefitsKey), child: const Text('Benefits')),
            TextButton(onPressed: () => _scrollTo(_featuresKey), child: const Text('Features')),
            TextButton(onPressed: () => _scrollTo(_analyticsKey), child: const Text('Analytics')),
            TextButton(onPressed: () => _scrollTo(_pricingKey), child: const Text('Pricing')),
            TextButton(onPressed: () => _scrollTo(_faqKey), child: const Text('FAQ')),
            TextButton(onPressed: () => Navigator.pushNamed(context, '/demo_login'), child: const Text('Demo')),
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
                    const ListTile(title: Text('For Contractors')),
                    ListTile(
                      leading: const Icon(Icons.star_outline),
                      title: const Text('Benefits'),
                      onTap: () { Navigator.pop(context); _scrollTo(_benefitsKey); },
                    ),
                    ListTile(
                      leading: const Icon(Icons.widgets_outlined),
                      title: const Text('Features'),
                      onTap: () { Navigator.pop(context); _scrollTo(_featuresKey); },
                    ),
                    ListTile(
                      leading: const Icon(Icons.analytics_outlined),
                      title: const Text('Analytics & Reporting'),
                      onTap: () { Navigator.pop(context); _scrollTo(_analyticsKey); },
                    ),
                    ListTile(
                      leading: const Icon(Icons.attach_money_outlined),
                      title: const Text('Pricing'),
                      onTap: () { Navigator.pop(context); _scrollTo(_pricingKey); },
                    ),
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text('FAQ'),
                      onTap: () { Navigator.pop(context); _scrollTo(_faqKey); },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.engineering_outlined),
                      title: const Text('Join as a Contractor'),
                      onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/contractor_signin'); },
                    ),
                  ],
                ),
              ),
            ),
      body: BlueprintBackground(
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _HeroSection(),
              const SizedBox(height: 24),
              KeyedSubtree(key: _benefitsKey, child: const _BenefitsSection()),
              const SizedBox(height: 24),
              KeyedSubtree(key: _featuresKey, child: const _FeaturesDeepDive()),
              const SizedBox(height: 24),
              KeyedSubtree(key: _analyticsKey, child: const _AnalyticsSection()),
              const SizedBox(height: 24),
              const _RoiSection(),
              const SizedBox(height: 24),
              KeyedSubtree(key: _pricingKey, child: const _PricingSection()),
              const SizedBox(height: 24),
              KeyedSubtree(key: _faqKey, child: const _FaqSection()),
              const SizedBox(height: 48),
              const _Footer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 72),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kSteelBlue, kDarkGray],
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
                'Win more jobs. Deliver on time. Get paid faster.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 34, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                'Estimates, approvals, scheduling, updates, and payments — organized in one place.',
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
                      onPressed: () => Navigator.pushNamed(context, '/contractor_signin'),
                      icon: const Icon(Icons.engineering_outlined),
                      label: const Text('Join as a Contractor'),
                    ),
                  ),
                  SlideFadeIn(
                    delay: const Duration(milliseconds: 150),
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/demo_login'),
                      icon: const Icon(Icons.login),
                      label: const Text('Open Demo'),
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

class _BenefitsSection extends StatelessWidget {
  const _BenefitsSection();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final items = const [
      _Benefit(icon: Icons.description_outlined, title: 'Professional estimates in minutes', desc: 'Templates, line items, and markups with client-ready PDFs.'),
      _Benefit(icon: Icons.rule_folder_outlined, title: 'Client approvals you can trust', desc: 'E‑sign change orders and approvals with a clear audit trail.'),
      _Benefit(icon: Icons.access_time, title: 'Clear timelines, fewer surprises', desc: 'Milestones, dependencies, and reminders that keep projects on track.'),
      _Benefit(icon: Icons.payments_outlined, title: 'Faster payments, less chasing', desc: 'Invoice by milestone with card/ACH and automatic reminders.'),
      _Benefit(icon: Icons.groups_2_outlined, title: 'Keep your crew aligned', desc: 'Assign tasks, share files, and track progress in one place.'),
      _Benefit(icon: Icons.photo_library_outlined, title: 'Photos clients love', desc: 'Before/after albums and galleries share progress professionally.'),
    ];
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? 1100 : 800),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Why contractors choose JobScaffold', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 3 : 1,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: isWide ? 3.2 : 3.6,
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

class _Benefit extends StatelessWidget {
  final IconData icon; final String title; final String desc;
  const _Benefit({required this.icon, required this.title, required this.desc});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: kSteelBlue, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(desc),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturesDeepDive extends StatelessWidget {
  const _FeaturesDeepDive();
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    Widget tile(String title, String desc, IconData icon) => Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: kSteelBlue),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(desc),
          ],
        ),
      ),
    );

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? 1100 : 800),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Everything you need to run the job', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isWide ? 3 : 1,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: isWide ? 1.8 : 1.6,
                children: [
                  tile('Lead pipeline', 'Capture, qualify, and convert leads with a simple CRM.', Icons.move_to_inbox_outlined),
                  tile('Estimates & change orders', 'Templates, e‑sign approval, and version history.', Icons.receipt_long_outlined),
                  tile('Scheduling & calendar sync', 'Crew assignments and Google/Outlook sync.', Icons.calendar_today_outlined),
                  tile('Tasking & workflows', 'Templates per job type, checklists, and dependencies.', Icons.checklist_rtl),
                  tile('Photos & files', 'Before/after albums and client-ready galleries.', Icons.photo_library_outlined),
                  tile('Payments & invoicing', 'Milestones, card/ACH, and auto reminders.', Icons.payments_outlined),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyticsSection extends StatelessWidget {
  const _AnalyticsSection();
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    Widget kpi(String label, String value, IconData icon, {Color? color}) => Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: color ?? kSteelBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    Widget miniBarChart() => LayoutBuilder(
          builder: (context, c) {
            final bars = [24.0, 56.0, 40.0, 72.0, 68.0, 90.0, 62.0, 96.0, 84.0, 110.0, 120.0, 140.0];
            final maxH = bars.reduce((a, b) => a > b ? a : b);
            return Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Revenue by Month', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 140,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final h in bars) ...[
                            Expanded(
                              child: Container(
                                height: (h / maxH) * 120 + 10,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: kSteelBlue.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? 1100 : 800),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Analytics & Reporting', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Track job pipeline, revenue, approvals, and payments – all in one dashboard designed for contractors.'),
              const SizedBox(height: 14),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isWide ? 3 : 1,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: isWide ? 3.2 : 3.6,
                children: const [
                  // Example KPIs (placeholder values)
                  // ignore: unnecessary_const
                  
                ],
              ),
              // Build KPIs programmatically to avoid const restriction with dynamic icons/colors
              LayoutBuilder(
                builder: (context, _) {
                  return GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 3 : 1,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: isWide ? 3.2 : 3.6,
                    ),
                    children: [
                      kpi('Open Jobs', '12', Icons.work_outline, color: Colors.teal),
                      kpi('30‑day Revenue', '\$124,800', Icons.payments_outlined, color: Colors.indigo),
                      kpi('Overdue Invoices', '3', Icons.report_problem_outlined, color: Colors.orange),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              // Simple chart placeholder
              miniBarChart(),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/analytics'),
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('View full analytics'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoiSection extends StatelessWidget {
  const _RoiSection();
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? 900 : 800),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('ROI calculator', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  SizedBox(height: 8),
                  Text('Estimate savings from time saved and faster payments.'),
                  SizedBox(height: 12),
                  _RoiCalculator(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoiCalculator extends StatefulWidget {
  const _RoiCalculator();
  @override
  State<_RoiCalculator> createState() => _RoiCalculatorState();
}

class _RoiCalculatorState extends State<_RoiCalculator> {
  final jobsPerMonth = TextEditingController(text: '8');
  final hoursSavedPerJob = TextEditingController(text: '2');
  final hourlyRate = TextEditingController(text: '75');

  double get _monthlySavings {
    final j = double.tryParse(jobsPerMonth.text) ?? 0;
    final h = double.tryParse(hoursSavedPerJob.text) ?? 0;
    final r = double.tryParse(hourlyRate.text) ?? 0;
    return j * h * r;
  }

  @override
  void dispose() {
    jobsPerMonth.dispose();
    hoursSavedPerJob.dispose();
    hourlyRate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _numField('Jobs per month', jobsPerMonth),
            _numField('Hours saved per job', hoursSavedPerJob),
            _numField('Hourly rate (\$)', hourlyRate),
          ],
        ),
        const SizedBox(height: 12),
        Text('Estimated monthly savings: \$${_monthlySavings.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _numField(String label, TextEditingController c) {
    return SizedBox(
      width: 220,
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}

class _PricingSection extends StatelessWidget {
  const _PricingSection();
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    Widget plan(String name, String price, List<String> items, {bool highlighted = false}) {
      return Card(
        color: highlighted ? Colors.blueGrey.shade50 : null,
        elevation: highlighted ? 4 : 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(price, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ...items.map((e) => Row(children: [const Icon(Icons.check, size: 16, color: Colors.green), const SizedBox(width: 6), Expanded(child: Text(e))])),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/contractor_signin'),
                child: const Text('Start free'),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? 1100 : 800),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Simple, transparent pricing', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  plan('Starter', '\$29 / user / mo', [
                    'Estimates & invoices',
                    'Client approvals',
                    'Basic scheduling',
                  ]),
                  plan('Team', '\$49 / user / mo', [
                    'Everything in Starter',
                    'Advanced scheduling',
                    'File galleries & approvals',
                  ], highlighted: true),
                  plan('Business', 'Talk to us', [
                    'Custom workflows',
                    'Priority support',
                    'QB Online integration',
                  ]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqSection extends StatelessWidget {
  const _FaqSection();
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final faqs = const [
      ('Do my clients need an app?', 'No. Clients can approve, message, and pay from any browser.'),
      ('Can I export my data?', 'Yes. You can export project data, contacts, and invoices.'),
      ('Do you support ACH payments?', 'Yes. ACH and cards are supported with standard processing fees.'),
      ('Can I import from spreadsheets?', 'Yes. We provide simple CSV import tools for contacts and tasks.'),
    ];
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? 1100 : 800),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Contractor FAQs', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              ...faqs.map((q) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(q.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(q.$2),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatefulWidget {
  const _Footer();
  @override
  State<_Footer> createState() => _FooterState();
}

class _FooterState extends State<_Footer> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _message = null;
    });
    try {
      final email = _emailController.text.trim().toLowerCase();
      
      // Capture UTM params and landing path (portable)
      final Map<String, dynamic> meta = {};
      final qp = Uri.base.queryParameters;
      meta.addAll({
        'utm_source': qp['utm_source'],
        'utm_medium': qp['utm_medium'],
        'utm_campaign': qp['utm_campaign'],
        'utm_term': qp['utm_term'],
        'utm_content': qp['utm_content'],
        'landing_path': Uri.base.path,
      });
      meta.removeWhere((key, value) => value == null || (value is String && value.isEmpty));
      
      // Check if email already exists (rate limiting)
      final existing = await FirebaseFirestore.instance
          .collection('leads')
          .doc(email)
          .get();
      
      if (existing.exists) {
        if (!mounted) return;
        setState(() {
          _message = 'You\'re already on the list! We\'ll be in touch soon.';
        });
        return;
      }
      
      // Create lead with email as document ID for deduplication
      await FirebaseFirestore.instance.collection('leads').doc(email).set({
        'email': email,
        'source': 'contractors_page_footer',
        'timestamp': FieldValue.serverTimestamp(),
        ...meta,
      });
      
      // Track analytics event
      try {
        await FirebaseAnalytics.instance.logEvent(
          name: 'lead_submitted',
          parameters: {
            'source': 'contractors_page_footer',
            'email_domain': email.split('@').last,
            if (meta['utm_source'] != null) 'utm_source': meta['utm_source'],
            if (meta['utm_medium'] != null) 'utm_medium': meta['utm_medium'],
            if (meta['utm_campaign'] != null) 'utm_campaign': meta['utm_campaign'],
          },
        );
      } catch (_) {}
      
      if (!mounted) return;
      setState(() {
        _message = 'Thanks! We\'ll be in touch soon.';
        _emailController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = 'Oops, something went wrong. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.black,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const TempLogo(size: 22, text: 'JobScaffold'),
              const SizedBox(height: 16),
              const Text(
                'Get early access and updates',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Form(
                key: _formKey,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Enter your email',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) {
                          final val = v?.trim() ?? '';
                          if (val.isEmpty) return 'Enter your email';
                          if (!val.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _submitting ? null : _submitEmail,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      ),
                      child: _submitting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Notify me'),
                    ),
                  ],
                ),
              ),
              if (_message != null) ...[
                const SizedBox(height: 8),
                Text(
                  _message!,
                  style: TextStyle(
                    color: _message!.startsWith('Thanks') ? Colors.greenAccent : Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text('© ${DateTime.now().year} JobScaffold', style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}
