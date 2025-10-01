import 'package:flutter/material.dart';
import 'pages/common/splash_gate.dart';
import 'pages/common/not_found_page.dart';
import 'pages/contractor/contractor_home_page.dart';
import 'pages/client/client_home_page.dart';
import 'state/app_state.dart';

class AppRouterDelegate extends RouterDelegate<RouteSettings>
		with ChangeNotifier, PopNavigatorRouterDelegateMixin<RouteSettings> {
	final GlobalKey<NavigatorState> navigatorKey;
	final AppState appState;

	AppRouterDelegate(this.appState)
			: navigatorKey = GlobalKey<NavigatorState>() {
		appState.addListener(notifyListeners);
	}

	@override
	RouteSettings? get currentConfiguration => null;

	@override
	Widget build(BuildContext context) {
		return Navigator(
			key: navigatorKey,
			pages: [
				if (appState.currentUser == null)
					const MaterialPage(child: SplashGate())
				else if (appState.currentUser!.role.toString().contains('contractor'))
					const MaterialPage(child: ContractorHomePage())
				else if (appState.currentUser!.role.toString().contains('client'))
					const MaterialPage(child: ClientHomePage())
				else
					const MaterialPage(child: NotFoundPage()),
			],
			onPopPage: (route, result) => route.didPop(result),
		);
	}

	@override
	Future<void> setNewRoutePath(RouteSettings configuration) async {}
}

class AppRouteInformationParser extends RouteInformationParser<RouteSettings> {
		@override
		Future<RouteSettings> parseRouteInformation(
				RouteInformation routeInformation) async {
			final uri = Uri.parse(routeInformation.location);
			return RouteSettings(name: uri.path);
		}

	@override
	RouteInformation? restoreRouteInformation(RouteSettings configuration) {
		return RouteInformation(location: configuration.name);
	}
}
