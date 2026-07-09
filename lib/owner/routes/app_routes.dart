import 'package:flutter/material.dart';

import '../Screen/app_root.dart';
import '../Screen/attendance_archives_screen.dart';
import '../Screen/owerner_dashboard_screen.dart';
import '../Screen/profile_screen.dart';

class AppRoutes {
  static const String root = '/';
  static const String splash = '/splash';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String attendanceArchives = '/attendance-archives';
  static const String leaveRequest = '/leave-request';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case root:
        return _materialRoute(const AppRoot(), settings);

      case dashboard:
        return _materialRoute(const OwernerDashboardScreen(), settings);
      case profile:
        return _materialRoute(const ProfileScreen(), settings);
      case attendanceArchives:
        return _materialRoute(const AttendanceArchivesScreen(), settings);

      default:
        return _materialRoute(
          Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
          settings,
        );
    }
  }

  static MaterialPageRoute<dynamic> _materialRoute(
    Widget page,
    RouteSettings settings,
  ) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }
}
