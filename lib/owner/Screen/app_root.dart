import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_flow_provider.dart';

import '../../login_screen.dart';
import '../../splash_screen.dart';
import 'owerner_dashboard_screen.dart';

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppFlowProvider>(
      builder: (context, appFlow, _) {
        if (!appFlow.hasCompletedSplash) {
          return const SplashScreen();
        }

        if (!appFlow.isAuthenticated) {
          return const LoginScreen();
        }

        return const OwernerDashboardScreen();
      },
    );
  }
}
