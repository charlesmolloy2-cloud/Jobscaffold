import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../state/dummy_data.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatelessWidget {
	const LoginPage({super.key});

	@override
	Widget build(BuildContext context) {
		final appState = Provider.of<AppState>(context, listen: false);
		return Scaffold(
			appBar: AppBar(title: const Text('Login')),
			body: Center(
				child: Column(
					mainAxisAlignment: MainAxisAlignment.center,
					children: [
						ElevatedButton(
							onPressed: () {
								appState.signInAs(contractorCasey);
								Navigator.pushReplacementNamed(context, '/');
							},
							child: const Text('Continue as Contractor'),
						),
						const SizedBox(height: 24),
						ElevatedButton(
							onPressed: () {
								appState.signInAs(clientChris);
								Navigator.pushReplacementNamed(context, '/');
							},
							child: const Text('Continue as Client'),
						),
					],
				),
			),
		);
	}
}
