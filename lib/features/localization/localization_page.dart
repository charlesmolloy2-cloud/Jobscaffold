
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class LocalizationPage extends StatefulWidget {
  const LocalizationPage({Key? key}) : super(key: key);

  @override
  State<LocalizationPage> createState() => _LocalizationPageState();
}

class _LocalizationPageState extends State<LocalizationPage> {
  List<_LocaleInfo> _locales = [
    _LocaleInfo(language: 'English', region: 'US'),
    _LocaleInfo(language: 'Spanish', region: 'ES'),
  ];

  void _addLocale() async {
    final result = await showDialog<_LocaleInfo>(
      context: context,
      builder: (context) => _LocaleDialog(),
    );
    if (result != null) {
      setState(() {
        _locales.add(result);
      });
    }
  }

  void _editLocale(int index) async {
    final result = await showDialog<_LocaleInfo>(
      context: context,
      builder: (context) => _LocaleDialog(
        language: _locales[index].language,
        region: _locales[index].region,
      ),
    );
    if (result != null) {
      setState(() {
        _locales[index] = result;
      });
    }
  }

  void _deleteLocale(int index) {
    setState(() {
      _locales.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Language & Localization')),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kGreen, kLightGreenBg],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Supported Languages & Regions',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBlack),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _locales.length,
                  itemBuilder: (context, index) {
                    final locale = _locales[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.language, color: kGreen),
                        title: Text('${locale.language} (${locale.region})'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: kGreenDark),
                              onPressed: () => _editLocale(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteLocale(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Language/Region'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    foregroundColor: kWhite,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _addLocale,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocaleInfo {
  final String language;
  final String region;
  _LocaleInfo({required this.language, required this.region});
}

class _LocaleDialog extends StatefulWidget {
  final String? language;
  final String? region;
  const _LocaleDialog({this.language, this.region});

  @override
  State<_LocaleDialog> createState() => _LocaleDialogState();
}

class _LocaleDialogState extends State<_LocaleDialog> {
  late TextEditingController _languageController;
  late TextEditingController _regionController;

  @override
  void initState() {
    super.initState();
    _languageController = TextEditingController(text: widget.language ?? '');
    _regionController = TextEditingController(text: widget.region ?? '');
  }

  @override
  void dispose() {
    _languageController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Language/Region'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _languageController,
            decoration: const InputDecoration(labelText: 'Language'),
          ),
          TextField(
            controller: _regionController,
            decoration: const InputDecoration(labelText: 'Region'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_languageController.text.trim().isEmpty) return;
            Navigator.pop(context, _LocaleInfo(
              language: _languageController.text.trim(),
              region: _regionController.text.trim(),
            ));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
