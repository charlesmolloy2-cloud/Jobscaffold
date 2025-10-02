import 'client_signin_page.dart';
import 'contractor_signin_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'state/app_state.dart';
import 'state/dummy_data.dart';
import 'home_page.dart';
import 'role_select_page.dart';
import 'pages/contractor/contractor_home_page.dart';
import 'pages/client/client_home_page.dart';
import 'features/files/files_page.dart';
import 'features/localization/localization_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_demo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (_) {
        final appState = AppState();
        seedAppState(appState);
        appState.signInAs(contractorCasey); // Sign in as default user
        return appState;
      },
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Project Bridge',
      theme: AppTheme.light,
      initialRoute: '/', // Role select page
      routes: {
        '/': (_) => const RoleSelectPage(),
        '/client_signin': (_) => const ClientSignInPage(),
        '/contractor_signin': (_) => const ContractorSignInPage(),
        '/home': (_) => const HomePage(),
        '/admin': (_) => const ContractorHomePage(),
        '/client': (_) => const ClientHomePage(),
        '/files': (_) => const FilesPage(),
        '/localization': (context) => const LocalizationPage(),
        '/firebase_demo': (_) => const FirebaseDemoPage(),
      },
    );
  }
}
