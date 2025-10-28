// JobScaffold: A platform for project clarity between contractor and client
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'utils/title_helper_stub.dart' if (dart.library.html) 'utils/title_helper_web.dart' as title_helper;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'generated_routes.dart';
import 'state/app_state.dart';
import 'state/dummy_data.dart';
import 'theme/app_theme.dart';
import 'services/firestore_repository.dart';
import 'features/projects/app_project_detail_page.dart';
import 'pages/common/how_to_create_job.dart';
import 'pages/common/how_to_use_jobs.dart';
import 'pages/common/how_to_use_messaging.dart';
import 'pages/common/how_to_use_calendar.dart';
import 'pages/common/how_to_use_payments.dart';
import 'pages/common/how_to_use_tasks.dart';
import 'pages/common/how_to_use_notifications.dart';
import 'pages/common/how_to_use_files.dart';
import 'pages/common/how_to_use_feedback.dart';
import 'pages/common/how_to_use_profile.dart';
import 'pages/common/admin_panel_page.dart';

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
final _AppRouteObserver _routeObserver = _AppRouteObserver();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Clean path URLs (no #) for web
  setPathUrlStrategy();
  // Avoid double-initialization during hot restart/web.
  if (Firebase.apps.isEmpty) {
    if (kIsWeb) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // On iOS, prefer using GoogleService-Info.plist bundled with the app
      // so teams don't need to regenerate firebase_options.dart immediately.
      await Firebase.initializeApp();
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }
  // Initialize Firebase Analytics
  FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  
  // Initialize Firebase Crashlytics (not available on web)
  if (!kIsWeb) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    // Pass all uncaught asynchronous errors to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // Initialize Push Notifications
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
  } catch (e) {
    // Ignore failures to avoid blocking app startup
    print('Failed to initialize notifications: $e');
  }
  
  // If running locally (e.g., on localhost), connect to Firebase Emulators
  try {
    final host = Uri.base.host; // works on web and mobile
    if (host == 'localhost' || host == '127.0.0.1') {
      // Auth emulator
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      // Firestore emulator
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      // Functions emulator (default region us-central1)
      FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
    }
  } catch (_) {
    // No-op: emulator setup is best-effort and only for local development
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final appState = AppState();
          seedAppState(appState);
          appState.loadPreferences();
          return appState;
        }),
        Provider<FirestoreRepository>(create: (_) => FirestoreRepository()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
  // Decide initial route:
  // - On web, go to '/' which we map to the Contractors page (no landing page).
  // - Otherwise, honor the platform's defaultRouteName or fallback to '/'.
  final platformDefaultRoute = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
  final String initialRoute = kIsWeb
    ? (platformDefaultRoute.isNotEmpty ? platformDefaultRoute : '/')
    : (platformDefaultRoute.isNotEmpty ? platformDefaultRoute : '/');

    return MaterialApp(
      debugShowCheckedModeBanner: false,
  title: 'JobScaffold',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      navigatorKey: _navigatorKey,
  navigatorObservers: <NavigatorObserver>[_routeObserver, _TitleObserver()],
    // Honor flutter --route; on web, default to '/landing' at root
    initialRoute: initialRoute,
      routes: {
        // Ensure generated routes can't override our index route ('/').
        ...generatedRoutes,
        // Developer route index moved under /routes to avoid hijacking '/'
        '/routes': (_) => const RouteIndex(),
        '/payments/success': (_) => const _PaymentResultScreen(success: true),
        '/payments/cancel': (_) => const _PaymentResultScreen(success: false),
  '/how_to_create_job': (_) => const HowToCreateJobPage(),
  '/how_to_use_jobs': (_) => const HowToUseJobsPage(),
  '/how_to_use_messaging': (_) => const HowToUseMessagingPage(),
  '/how_to_use_calendar': (_) => const HowToUseCalendarPage(),
  '/how_to_use_payments': (_) => const HowToUsePaymentsPage(),
  '/how_to_use_tasks': (_) => const HowToUseTasksPage(),
  '/how_to_use_notifications': (_) => const HowToUseNotificationsPage(),
  '/how_to_use_files': (_) => const HowToUseFilesPage(),
  '/how_to_use_feedback': (_) => const HowToUseFeedbackPage(),
  '/how_to_use_profile': (_) => const HowToUseProfilePage(),
  '/admin': (_) => const AdminPanelPage(),
      },
      onGenerateRoute: (settings) {
        final name = settings.name ?? '';
        // Stripe Checkout returns with query params, e.g. /payments/success?session_id=...
        if (name.startsWith('/payments/')) {
          final uri = Uri.tryParse(name);
          final isSuccess = uri?.pathSegments.contains('success') ?? name.contains('/payments/success');
          return MaterialPageRoute(
            settings: RouteSettings(name: name),
            builder: (_) => _PaymentResultScreen(success: isSuccess),
            maintainState: true,
          );
        }
        if (name.startsWith('/project/')) {
          final id = name.substring('/project/'.length);
          return MaterialPageRoute(
            settings: RouteSettings(name: settings.name, arguments: {'projectId': id}),
            builder: (_) => const AppProjectDetailPage(),
            maintainState: true,
          );
        }
        // Tab-level deep links for client and contractor dashboards
        if (name == '/client' || name.startsWith('/client/')) {
          return MaterialPageRoute(
            settings: RouteSettings(name: name),
            builder: (context) => generatedRoutes['/client']!(context),
            maintainState: true,
          );
        }
        if (name == '/admin' || name.startsWith('/admin/')) {
          return MaterialPageRoute(
            settings: RouteSettings(name: name),
            builder: (context) => generatedRoutes['/admin']!(context),
            maintainState: true,
          );
        }
        return null;
      },
      onUnknownRoute: (s) => MaterialPageRoute(
        settings: s, // preserve the original RouteSettings (including name)
        builder: (_) => NotFoundScreen(routeName: s.name ?? ''),
      ),
      builder: (context, child) => _AuthRouteSync(child: child),
    );
  }
}

class RouteIndex extends StatelessWidget {
  const RouteIndex({super.key});
  @override
  Widget build(BuildContext context) {
    final routes = generatedRoutes.keys.toList()..sort();
    return Scaffold(
  appBar: AppBar(title: const Text('JobScaffold')),
      body: routes.isEmpty
          ? const Center(child: Text('No screens with zero-arg constructors found.'))
          : ListView(
              children: [
                const _FirebaseStatusCard(),
                const Divider(height: 0),
                ...routes.map((name) => ListTile(
                      title: Text(name),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(context, name),
                    )),
              ],
            ),
    );
  }
}

class _AppRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  String? currentRouteName;

  void _update(Route<dynamic> route) {
    if (route is PageRoute<dynamic>) {
      currentRouteName = route.settings.name;
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _update(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _update(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) _update(previousRoute);
  }
}

class _TitleObserver extends RouteObserver<PageRoute<dynamic>> {
  void _set(PageRoute<dynamic> route) {
    final name = route.settings.name ?? '';
  String title = 'JobScaffold';
  if (name == '/admin') title = 'Contractor · JobScaffold';
  if (name == '/client') title = 'Client · JobScaffold';
    if (name.startsWith('/admin/')) {
      final seg = name.substring('/admin/'.length);
      final tab = seg.isEmpty ? 'Home' : seg[0].toUpperCase() + seg.substring(1);
  title = 'Contractor · $tab · JobScaffold';
    }
    if (name.startsWith('/client/')) {
      final seg = name.substring('/client/'.length);
      final tab = seg.isEmpty ? 'Home' : seg[0].toUpperCase() + seg.substring(1);
  title = 'Client · $tab · JobScaffold';
    }
  if (name == '/projects') title = 'Projects · JobScaffold';
  if (name == '/project' || name.startsWith('/project/')) title = 'Project Details · JobScaffold';
    // Best-effort: set document title for web only.
    title_helper.setDocumentTitle(title);
  }
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) _set(route);
  }
  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute is PageRoute) _set(newRoute);
  }
  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute is PageRoute) _set(previousRoute);
  }
}

class _AuthRouteSync extends StatefulWidget {
  final Widget? child;
  const _AuthRouteSync({required this.child});

  @override
  State<_AuthRouteSync> createState() => _AuthRouteSyncState();
}

class _AuthRouteSyncState extends State<_AuthRouteSync> {
  late final Stream<User?> _authStream;
  User? _lastUser;

  @override
  void initState() {
    super.initState();
    _authStream = FirebaseAuth.instance.authStateChanges();
    _authStream.listen((user) {
      final appState = mounted ? context.read<AppState>() : null;
      final bypass = appState?.devBypassRole;
      final hasLocalUser = (appState?.currentUser != null);
      final wasSignedIn = _lastUser != null;
      final isSignedIn = user != null;
      _lastUser = user;

      // Minimal, safe route synchronization:
      // - If signed out while on protected dashboards, send to home.
      // - If signed in while on sign-in screens, send to the corresponding dashboard.
      final routeName = _routeObserver.currentRouteName;
      if (!isSignedIn && bypass == null && !hasLocalUser) {
        if (routeName == '/admin' || routeName == '/client') {
          _navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);
        }
      } else if (isSignedIn && !wasSignedIn) {
        if (routeName == '/contractor_signin') {
          _navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/admin',
            (r) => false,
            arguments: const {'signedIn': true},
          );
        } else if (routeName == '/client_signin') {
          _navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/client',
            (r) => false,
            arguments: const {'signedIn': true},
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child ?? const SizedBox.shrink();
}

class NotFoundScreen extends StatelessWidget {
  final String routeName;
  const NotFoundScreen({super.key, required this.routeName});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not Found')),
      body: Center(child: Text('Route "$routeName" is not registered.')),
    );
  }
}

class _PaymentResultScreen extends StatelessWidget {
  final bool success;
  const _PaymentResultScreen({required this.success});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(success ? 'Payment Success' : 'Payment Canceled')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(success ? Icons.check_circle : Icons.cancel, size: 64, color: success ? Colors.green : Colors.red),
            const SizedBox(height: 16),
            Text(success ? 'Thank you! Your payment was successful.' : 'Payment was canceled.'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.popUntil(context, (r) => r.settings.name == '/admin' || r.settings.name == '/client' || r.isFirst),
              child: const Text('Back to app'),
            )
          ],
        ),
      ),
    );
  }
}

class _FirebaseStatusCard extends StatelessWidget {
  const _FirebaseStatusCard();
  @override
  Widget build(BuildContext context) {
    String status;
    String? projectId;
    String? appId;
    try {
      final apps = Firebase.apps;
      if (apps.isEmpty) {
        status = 'Firebase NOT initialized';
      } else {
        final app = Firebase.app();
        final opts = app.options;
        status = 'Firebase initialized (${apps.length} app${apps.length == 1 ? '' : 's'})';
        projectId = opts.projectId;
        appId = opts.appId;
      }
    } catch (e) {
      status = 'Firebase status error: $e';
    }

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Firebase', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(status),
            if (projectId != null) Text('projectId: $projectId'),
            if (appId != null) Text('appId: $appId'),
          ],
        ),
      ),
    );
  }
}