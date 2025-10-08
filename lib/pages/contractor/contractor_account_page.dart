import '../../roles/role.dart';
import '../../state/dummy_data.dart';
import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user.dart';

class ContractorAccountPage extends StatefulWidget {
	const ContractorAccountPage({super.key});

	@override
	State<ContractorAccountPage> createState() => _ContractorAccountPageState();
}

class _ContractorAccountPageState extends State<ContractorAccountPage> {
	final _formKey = GlobalKey<FormState>();
	late final TextEditingController _nameCtrl;
	late final TextEditingController _companyCtrl;
	late final TextEditingController _phoneCtrl;
	late final TextEditingController _emailCtrl;
	late final TextEditingController _addressCtrl;
	bool _loadedFromFirestore = false;
	bool _saving = false;

	@override
	void initState() {
		super.initState();
		final appState = context.read<AppState>();
		final auth = FirebaseAuth.instance.currentUser;
		_nameCtrl = TextEditingController(text: appState.currentUser?.name ?? auth?.displayName ?? '');
		_companyCtrl = TextEditingController();
		_phoneCtrl = TextEditingController();
		_emailCtrl = TextEditingController(text: auth?.email ?? '');
		_addressCtrl = TextEditingController();
	}

	@override
	void dispose() {
		_nameCtrl.dispose();
		_companyCtrl.dispose();
		_phoneCtrl.dispose();
		_emailCtrl.dispose();
		_addressCtrl.dispose();
		super.dispose();
	}

	Future<void> _saveProfile() async {
		if (!(_formKey.currentState?.validate() ?? false)) return;
		setState(() => _saving = true);
		final authUser = FirebaseAuth.instance.currentUser;
		final appState = context.read<AppState>();
		try {
			// Update FirebaseAuth display name when available
			if (authUser != null && _nameCtrl.text.trim().isNotEmpty) {
				await authUser.updateDisplayName(_nameCtrl.text.trim());
			}
			// Update Firestore profile document if signed in
			if (authUser != null) {
				final uid = authUser.uid;
				final data = <String, dynamic>{
					'name': _nameCtrl.text.trim(),
					'company': _companyCtrl.text.trim(),
					'phone': _phoneCtrl.text.trim(),
					'email': _emailCtrl.text.trim(),
					'address': _addressCtrl.text.trim(),
					'updatedAt': FieldValue.serverTimestamp(),
				};
				await FirebaseFirestore.instance.collection('users').doc(uid).set(data, SetOptions(merge: true));
			}
			// Keep local state in sync with edited name (role unchanged)
			final local = appState.currentUser;
			if (local != null) {
				appState.signInAs(
					AppUser(id: local.id, name: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : local.name, role: local.role),
				);
			}
			if (mounted) {
				ScaffoldMessenger.of(context).showSnackBar(
					const SnackBar(content: Text('Profile saved')),
				);
			}
		} catch (e) {
			if (mounted) {
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(content: Text('Failed to save profile: $e')),
				);
			}
		} finally {
			if (mounted) setState(() => _saving = false);
		}
	}

	@override
	Widget build(BuildContext context) {
		final appState = context.watch<AppState>();
		final localUser = appState.currentUser;
		final authUser = FirebaseAuth.instance.currentUser;
		final uid = authUser?.uid;

		return Padding(
			padding: const EdgeInsets.all(16),
			child: Center(
				child: ConstrainedBox(
					constraints: const BoxConstraints(maxWidth: 700),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.stretch,
						children: [
							// Profile card with form
							Card(
								elevation: 0,
								color: Colors.white,
								child: Padding(
									padding: const EdgeInsets.all(16),
									child: Form(
										key: _formKey,
										child: Column(
											crossAxisAlignment: CrossAxisAlignment.stretch,
											children: [
												Row(
													children: [
														CircleAvatar(
															radius: 28,
															backgroundColor: Colors.green[100],
															child: const Icon(Icons.person, size: 32, color: Colors.green),
														),
														const SizedBox(width: 16),
														Expanded(
															child: Text(
																'Your Profile',
																style: Theme.of(context).textTheme.titleMedium,
															),
														),
														FilledButton.icon(
															onPressed: _saving ? null : _saveProfile,
															icon: _saving
																	? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
																	: const Icon(Icons.save),
															label: const Text('Save'),
														),
													],
												),
												const SizedBox(height: 16),
												if (uid != null)
													StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
														stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
														builder: (context, snap) {
															if (snap.hasData && !_loadedFromFirestore) {
																final d = snap.data!.data() ?? {};
																_companyCtrl.text = d['company']?.toString() ?? _companyCtrl.text;
																_phoneCtrl.text = d['phone']?.toString() ?? _phoneCtrl.text;
																_addressCtrl.text = d['address']?.toString() ?? _addressCtrl.text;
																final n = d['name']?.toString();
																if ((n != null && n.isNotEmpty) && _nameCtrl.text.trim().isEmpty) {
																	_nameCtrl.text = n;
																}
																_loadedFromFirestore = true;
															}
															return const SizedBox.shrink();
														},
													),
												TextFormField(
													controller: _nameCtrl,
													decoration: const InputDecoration(labelText: 'Full Name'),
													validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
												),
												Row(
													children: [
														Expanded(
															child: TextFormField(
																controller: _companyCtrl,
																decoration: const InputDecoration(labelText: 'Company'),
															),
														),
														const SizedBox(width: 12),
														Expanded(
															child: TextFormField(
																controller: _phoneCtrl,
																decoration: const InputDecoration(labelText: 'Phone'),
																keyboardType: TextInputType.phone,
															),
														),
													],
												),
												TextFormField(
													controller: _emailCtrl,
													readOnly: true,
													decoration: const InputDecoration(labelText: 'Email (from sign-in)'),
												),
												TextFormField(
													controller: _addressCtrl,
													decoration: const InputDecoration(labelText: 'Business Address'),
													maxLines: 2,
												),
											],
										),
									),
								),
							),
							const SizedBox(height: 16),
							// Role switch and sign-out
							Card(
								elevation: 0,
								color: Colors.white,
								child: Padding(
									padding: const EdgeInsets.all(16),
									child: Column(
										children: [
											Row(
												mainAxisAlignment: MainAxisAlignment.center,
												children: [
													const Text('Role: '),
													SegmentedButton<UserRole>(
														segments: const [
															ButtonSegment(value: UserRole.contractor, label: Text('Contractor')),
															ButtonSegment(value: UserRole.client, label: Text('Client')),
														],
														selected: {localUser?.role ?? UserRole.contractor},
														onSelectionChanged: (roles) {
															final role = roles.first;
															final appState = context.read<AppState>();
															if (role == UserRole.contractor) {
																appState.signInAs(contractorCasey);
															} else {
																appState.signInAs(clientChris);
															}
															Navigator.pushReplacementNamed(context, '/');
														},
													),
												],
											),
											const SizedBox(height: 16),
											ElevatedButton(
												onPressed: () async {
													final appState = context.read<AppState>();
													appState.signOut();
													try {
														await FirebaseAuth.instance.signOut();
													} catch (_) {}
													if (mounted) {
														Navigator.pushNamedAndRemoveUntil(
															context,
															'/contractor_signin',
															(route) => false,
															arguments: const {'signedOut': true},
														);
													}
												},
												child: const Text('Sign Out'),
											),
										],
									),
								),
							),
						],
					),
				),
			),
		);
	}
}
