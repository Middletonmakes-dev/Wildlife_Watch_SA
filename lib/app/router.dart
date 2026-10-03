import 'package:go_router/go_router.dart';

import '../features/admin/presentation/admin_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/map/presentation/public_map_screen.dart';
import '../features/report/presentation/report_screen.dart';
import '../features/report/presentation/thank_you_screen.dart';
import '../features/support/presentation/support_card.dart';

GoRouter buildRouter() => GoRouter(
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
            path: '/report', builder: (context, state) => const ReportScreen()),
        GoRoute(
            path: '/thanks',
            builder: (context, state) => const ThankYouScreen()),
        GoRoute(
            path: '/map', builder: (context, state) => const PublicMapScreen()),
        GoRoute(
            path: '/admin', builder: (context, state) => const AdminScreen()),
        GoRoute(
            path: '/support',
            builder: (context, state) => const SupportCardPage()),
      ],
    );
