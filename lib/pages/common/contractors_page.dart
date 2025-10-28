import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/temp_logo.dart';
import '../../widgets/fade_in.dart';
import '../../widgets/slide_fade_in.dart';
import '../../widgets/blueprint_background.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
              Wrap(
class ContractorsPage extends StatefulWidget {
  const ContractorsPage({super.key});

                  plan('Starter', '\$29 / user / mo', [
  State<ContractorsPage> createState() => _ContractorsPageState();
}

class _ContractorsPageState extends State<ContractorsPage> {
                  plan('Team', '\$49 / user / mo', [
  final _benefitsKey = GlobalKey();
  final _featuresKey = GlobalKey();
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
            TextButton(onPressed: () => _scrollTo(_pricingKey), child: const Text('Pricing')),
            TextButton(onPressed: () => _scrollTo(_faqKey), child: const Text('FAQ')),
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
          }
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
      return Expanded(
        child: Card(
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
          const TempLogo(size: 22, text: 'JobScaffold'),
          const SizedBox(height: 8),
          Text('© ${DateTime.now().year} JobScaffold', style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/temp_logo.dart';
import '../../widgets/fade_in.dart';
import '../../widgets/slide_fade_in.dart';
import '../../widgets/blueprint_background.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';

class ContractorsPage extends StatefulWidget {
  const ContractorsPage({super.key});

  @override
  State<ContractorsPage> createState() => _ContractorsPageState();
}

class _ContractorsPageState extends State<ContractorsPage> {
  final _scrollController = ScrollController();
  final _benefitsKey = GlobalKey();
  final _featuresKey = GlobalKey();
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
            TextButton(onPressed: () => _scrollTo(_pricingKey), child: const Text('Pricing')),
            TextButton(onPressed: () => _scrollTo(_faqKey), child: const Text('FAQ')),
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

class _PricingSection extends StatelessWidget {
  const _PricingSection();
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    Widget plan(String name, String price, List<String> items, {bool highlighted = false}) {
      return Expanded(
        child: Card(
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
                  plan('Starter', ' 2429 / user / mo', [
                    'Estimates & invoices',
                    'Client approvals',
                    'Basic scheduling',
                  ]),
                  plan('Team', ' 2449 / user / mo', [
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
      return Expanded(
        child: Card(
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
                  plan('Starter', ' 029 / user / mo', [
                    'Estimates & invoices',
                    'Client approvals',
                    'Basic scheduling',
                  ]),
                  plan('Team', ' 049 / user / mo', [
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
          const TempLogo(size: 22, text: 'JobScaffold'),
          const SizedBox(height: 8),
          Text('© ${DateTime.now().year} JobScaffold', style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
