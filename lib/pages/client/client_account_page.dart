import '../../roles/role.dart';
import '../../state/dummy_data.dart';
import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import 'package:provider/provider.dart';

class ClientAccountPage extends StatelessWidget {
	const ClientAccountPage({super.key});

	@override
	Widget build(BuildContext context) {
		final appState = Provider.of<AppState>(context);
		final user = appState.currentUser;
			return Padding(
				padding: const EdgeInsets.all(24),
				child: Column(
					mainAxisAlignment: MainAxisAlignment.center,
					crossAxisAlignment: CrossAxisAlignment.center,
					children: [
						Icon(Icons.person, size: 64, color: Colors.green[700]),
						const SizedBox(height: 16),
						Text(user?.name ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
						Text(user?.role.toString().split('.').last ?? '', style: const TextStyle(fontSize: 16, color: Colors.grey)),
						const SizedBox(height: 32),
						// Switch Role segmented control
						Row(
							mainAxisAlignment: MainAxisAlignment.center,
							children: [
								const Text('Role: '),
												SegmentedButton<UserRole>(
													segments: [
														ButtonSegment(value: UserRole.contractor, label: const Text('Contractor')),
														ButtonSegment(value: UserRole.client, label: const Text('Client')),
													],
													selected: {user?.role ?? UserRole.client},
													onSelectionChanged: (roles) {
														final role = roles.first;
														final appState = Provider.of<AppState>(context, listen: false);
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
						const SizedBox(height: 24),
						ElevatedButton(
							onPressed: () {
								final appState = Provider.of<AppState>(context, listen: false);
								appState.signOut();
								Navigator.pushReplacementNamed(context, '/login');
							},
							child: const Text('Sign Out'),
						),
					],
				),
			);
	}
}
