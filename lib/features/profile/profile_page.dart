
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _name = '';
  String _email = '';
  String _phone = '';

  void _editProfile() async {
    final result = await showDialog<_ProfileInfo>(
      context: context,
      builder: (context) => _ProfileDialog(
        name: _name,
        email: _email,
        phone: _phone,
      ),
    );
    if (result != null) {
      setState(() {
        _name = result.name;
        _email = result.email;
        _phone = result.phone;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Icon(Icons.person, size: 64, color: kGreenDark),
            const SizedBox(height: 16),
            const Text(
              'Profile & Settings',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kBlack),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manage your profile, contact info, and notification preferences.',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text('Name: ${_name.isEmpty ? 'Not set' : _name}'),
                    Text('Email: ${_email.isEmpty ? 'Not set' : _email}'),
                    Text('Phone: ${_phone.isEmpty ? 'Not set' : _phone}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen,
                foregroundColor: kWhite,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _editProfile,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfo {
  final String name;
  final String email;
  final String phone;
  _ProfileInfo({required this.name, required this.email, required this.phone});
}

class _ProfileDialog extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  const _ProfileDialog({required this.name, required this.email, required this.phone});

  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profile'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone'),
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
            if (_nameController.text.trim().isEmpty) return;
            Navigator.pop(context, _ProfileInfo(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              phone: _phoneController.text.trim(),
            ));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
