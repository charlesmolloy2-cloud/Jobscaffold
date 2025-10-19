import 'package:flutter/material.dart';

// Core navigation destinations with zero-arg constructors
import 'home_page.dart';
import 'role_select_page.dart';
import 'client_signin_page.dart';
import 'contractor_signin_page.dart';

// Tabbed home containers
import 'pages/client/client_home_page.dart';
import 'pages/contractor/contractor_home_page.dart';

// Common
import 'pages/common/login_page.dart';
import 'pages/common/public_home_page.dart';
import 'pages/common/landing_page.dart';

// Optional feature demo routes (standalone screens)
import 'features/calendar/calendar_page.dart';
import 'features/messaging/messaging_page.dart';
import 'features/notifications/notifications_page.dart';
import 'features/tasks/tasks_page.dart';
import 'features/analytics/analytics_page.dart';
import 'features/payments/payments_page.dart';
import 'features/feedback/feedback_page.dart';
import 'features/esignature/esignature_page.dart';
import 'features/projects/projects.dart';
import 'features/projects/app_project_detail_page.dart';
import 'pages/common/privacy_page.dart';
import 'pages/common/terms_page.dart';

// Export a single map of route name to builder. Keep '/' reserved for the index in main.dart
final Map<String, WidgetBuilder> generatedRoutes = <String, WidgetBuilder>{
  // Landing and auth
  '/role_select': (_) => const RoleSelectPage(),
  '/home': (_) => const HomePage(),
  '/': (_) => const PublicHomePage(),
  '/landing': (_) => const LandingPage(),
  '/login': (_) => const LoginPage(),
  '/client_signin': (_) => const ClientSignInPage(),
  '/contractor_signin': (_) => const ContractorSignInPage(),

  // Primary apps (client/contractor containers)
  '/client': (_) => const ClientHomePage(),
  '/admin': (_) => const ContractorHomePage(),

  // Demos
  // Firebase demo intentionally omitted from web build to avoid web plugin constraints

  // Feature sample screens
  '/calendar': (_) => const CalendarPage(),
  '/messaging': (_) => const MessagingPage(),
  '/notifications': (_) => const NotificationsPage(),
  '/tasks': (_) => const TasksPage(),
  '/analytics': (_) => const AnalyticsPage(),
  '/payments': (_) => const PaymentsPage(),
  '/feedback': (_) => const FeedbackPage(),
  '/esignature': (_) => const ESignaturePage(),
  '/projects': (_) => const ProjectsScreen(),
  '/project': (_) => const AppProjectDetailPage(),
  '/privacy': (_) => const PrivacyPage(),
  '/terms': (_) => const TermsPage(),
};
