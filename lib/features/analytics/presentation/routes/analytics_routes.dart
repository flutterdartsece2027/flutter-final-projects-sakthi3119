import 'package:flutter/material.dart';
import 'package:expense_tracker/features/analytics/presentation/screens/analytics_screen.dart';

class AnalyticsRoutes {
  static const String analytics = '/analytics';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case analytics:
        return MaterialPageRoute(
          builder: (_) => const AnalyticsScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
