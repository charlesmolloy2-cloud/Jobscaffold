import 'package:flutter/material.dart';
import 'package:url_strategy/url_strategy.dart';
import 'utils/title_helper_stub.dart' if (dart.library.html) 'utils/title_helper_web.dart' as title_helper;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'generated_routes.dart';
import 'state/app_state.dart';
import 'state/dummy_data.dart';
import 'theme/app_theme.dart';
import 'services/firestore_repository.dart';
import 'features/projects/app_project_detail_page.dart';

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
final _AppRouteObserver _routeObserver = _AppRouteObserver();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Clean path URLs (no #) for web
  setPathUrlStrategy();
  // Avoid double-initialization during hot restart/web.
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Project Bridge',
      theme: AppTheme.light,
      navigatorKey: _navigatorKey,
  navigatorObservers: <NavigatorObserver>[_routeObserver, _TitleObserver()],
      // Public marketing page is the default route for all platforms.
      initialRoute: '/',
      routes: {
        // Ensure generated routes can't override our index route ('/').
        ...generatedRoutes,
        // Developer route index moved under /routes to avoid hijacking '/'
        '/routes': (_) => const RouteIndex(),
      },
      onGenerateRoute: (settings) {
        final name = settings.name ?? '';
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
      appBar: AppBar(title: const Text('Project Bridge')),
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
    String title = 'Project Bridge';
    if (name == '/admin') title = 'Contractor · Project Bridge';
    if (name == '/client') title = 'Client · Project Bridge';
    if (name.startsWith('/admin/')) {
      final seg = name.substring('/admin/'.length);
      final tab = seg.isEmpty ? 'Home' : seg[0].toUpperCase() + seg.substring(1);
      title = 'Contractor · $tab · Project Bridge';
    }
    if (name.startsWith('/client/')) {
      final seg = name.substring('/client/'.length);
      final tab = seg.isEmpty ? 'Home' : seg[0].toUpperCase() + seg.substring(1);
      title = 'Client · $tab · Project Bridge';
    }
    if (name == '/projects') title = 'Projects · Project Bridge';
    if (name == '/project' || name.startsWith('/project/')) title = 'Project Details · Project Bridge';
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
      final wasSignedIn = _lastUser != null;
      final isSignedIn = user != null;
      _lastUser = user;

      // Minimal, safe route synchronization:
      // - If signed out while on protected dashboards, send to home.
      // - If signed in while on sign-in screens, send to the corresponding dashboard.
      final routeName = _routeObserver.currentRouteName;
      if (!isSignedIn && bypass == null) {
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