import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:koniwalamatrimonial/providers/data_entry_dashboard_provider.dart';
import 'package:koniwalamatrimonial/providers/manager_dashboard_provider.dart';
import 'package:koniwalamatrimonial/providers/navigation_provider.dart';
import 'package:koniwalamatrimonial/providers/notifications_provider.dart';
import 'package:koniwalamatrimonial/owner/providers/dashboard_provider.dart'
    as owner_dashboard;
import 'package:koniwalamatrimonial/owner/providers/app_flow_provider.dart';
import 'package:koniwalamatrimonial/owner/providers/customer_registry_provider.dart';
import 'package:koniwalamatrimonial/owner/providers/follow_up_control_actions_provider.dart';
import 'package:koniwalamatrimonial/owner/providers/hr_employees_provider.dart';
import 'package:koniwalamatrimonial/owner/providers/leave_request_provider.dart';
import 'package:koniwalamatrimonial/owner/providers/lead_follow_ups_provider.dart';
import 'package:koniwalamatrimonial/owner/providers/leads_provider.dart';
import 'package:koniwalamatrimonial/owner/providers/registry_profiles_provider.dart';
import 'package:koniwalamatrimonial/owner/providers/tasks_provider.dart';
import 'package:koniwalamatrimonial/providers/lead_follow_up_provider.dart';
import 'package:koniwalamatrimonial/providers/match_history_provider.dart';
import 'package:koniwalamatrimonial/providers/settings_provider.dart';
import 'package:koniwalamatrimonial/providers/leave_provider.dart';
import 'package:koniwalamatrimonial/services/leave_service.dart';
import 'package:koniwalamatrimonial/providers/holiday_provider.dart';
import 'package:koniwalamatrimonial/providers/hr_attendance_calendar_provider.dart';
import 'package:koniwalamatrimonial/services/holiday_service.dart';
import 'package:koniwalamatrimonial/services/follow_up_control_service.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/routes/app_route_observer.dart';
import 'package:koniwalamatrimonial/routes/app_router.dart';
import 'package:koniwalamatrimonial/routes/app_routes.dart';
import 'package:koniwalamatrimonial/rm/chat_updates/chat_updates_source.dart';
import 'package:koniwalamatrimonial/rm/providers/rm_dashboard_summary_provider.dart';
import 'package:koniwalamatrimonial/rm/providers/rm_leads_provider.dart';
import 'package:koniwalamatrimonial/rm/providers/whatsapp_provider.dart';
import 'package:koniwalamatrimonial/services/whatsapp_service.dart';
import 'package:koniwalamatrimonial/utils/app_responsive.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.trackpad,
  };
}

ThemeData _buildAppTheme(Brightness brightness) {
  final baseTheme = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      surface: brightness == Brightness.dark
          ? const Color(0xFF141213)
          : const Color(0xFFFFFFFF),
    ),
  );
  final interTextTheme = AppResponsive.scaleTextTheme(
    GoogleFonts.interTextTheme(baseTheme.textTheme).apply(
      bodyColor: brightness == Brightness.dark
          ? Colors.white
          : AppColors.titleColor,
      displayColor: brightness == Brightness.dark
          ? Colors.white
          : AppColors.titleColor,
    ),
  );
  final interPrimaryTextTheme = AppResponsive.scaleTextTheme(
    GoogleFonts.interTextTheme(baseTheme.primaryTextTheme).apply(
      bodyColor: brightness == Brightness.dark
          ? Colors.white
          : AppColors.titleColor,
      displayColor: brightness == Brightness.dark
          ? Colors.white
          : AppColors.titleColor,
    ),
  );

  return baseTheme.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary,
      surfaceTintColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white, size: 24.sp),
      actionsIconTheme: IconThemeData(color: Colors.white, size: 24.sp),
    ),
    iconTheme: IconThemeData(
      size: 24.sp,
      color: brightness == Brightness.dark
          ? Colors.white
          : AppColors.titleColor,
    ),
    primaryIconTheme: IconThemeData(
      size: 24.sp,
      color: brightness == Brightness.dark
          ? Colors.white
          : AppColors.titleColor,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(iconSize: 24.sp),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: AppColors.primary,
      selectedIconTheme: IconThemeData(size: 24.sp),
      unselectedIconTheme: IconThemeData(size: 24.sp),
      selectedLabelStyle: TextStyle(fontSize: 12.sp),
      unselectedLabelStyle: TextStyle(fontSize: 11.sp),
    ),
    scaffoldBackgroundColor: brightness == Brightness.dark
        ? const Color(0xFF141213)
        : AppColors.rmSoftPink,
    textTheme: interTextTheme,
    primaryTextTheme: interPrimaryTextTheme,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DataEntryDashboardProvider()),
        ChangeNotifierProvider(create: (_) => ManagerDashboardProvider()),
        ChangeNotifierProvider(create: (_) => RmDashboardSummaryProvider()),
        ChangeNotifierProvider(create: (_) => RmLeadsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => LeadFollowUpProvider()),
        ChangeNotifierProvider(
          create: (_) => owner_dashboard.DashboardProvider(),
        ),
        ChangeNotifierProvider(create: (_) => AppFlowProvider()),
        ChangeNotifierProvider(create: (_) => LeadsProvider()),
        ChangeNotifierProvider(create: (_) => LeadFollowUpsProvider()),
        ChangeNotifierProvider(create: (_) => CustomerRegistryProvider()),
        ChangeNotifierProvider(create: (_) => RegistryProfilesProvider()),
        ChangeNotifierProvider(create: (_) => HrEmployeesProvider()),
        ChangeNotifierProvider(create: (_) => HrAttendanceCalendarProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => MatchHistoryProvider()),
        ChangeNotifierProvider(create: (_) => TasksProvider()),
        Provider(create: (_) => FollowUpControlService()),
        Provider(create: (_) => const WhatsappService()),
        Provider<ChatUpdatesSourceFactory>(
          create: (context) =>
              () => PollingChatUpdatesSource(context.read<WhatsappService>()),
        ),
        ChangeNotifierProxyProvider<WhatsappService, WhatsappProvider>(
          create: (context) =>
              WhatsappProvider(context.read<WhatsappService>()),
          update: (_, service, previous) =>
              previous ?? WhatsappProvider(service),
        ),
        ChangeNotifierProxyProvider<
          FollowUpControlService,
          FollowUpControlActionsProvider
        >(
          create: (context) => FollowUpControlActionsProvider(
            context.read<FollowUpControlService>(),
          ),
          update: (_, service, previous) =>
              previous ?? FollowUpControlActionsProvider(service),
        ),
        Provider(create: (_) => HolidayService()),
        ChangeNotifierProxyProvider<HolidayService, HolidayProvider>(
          create: (context) => HolidayProvider(context.read<HolidayService>()),
          update: (_, service, previous) =>
              previous ?? HolidayProvider(service),
        ),
        Provider(create: (_) => LeaveService()),
        ChangeNotifierProxyProvider<LeaveService, LeaveRequestProvider>(
          create: (context) =>
              LeaveRequestProvider(context.read<LeaveService>()),
          update: (_, service, previous) =>
              previous ?? LeaveRequestProvider(service),
        ),
        ChangeNotifierProxyProvider<LeaveService, LeaveProvider>(
          create: (context) => LeaveProvider(context.read<LeaveService>()),
          update: (_, service, previous) => previous ?? LeaveProvider(service),
        ),
      ],

      child: ScreenUtilInit(
        designSize: AppResponsive.designSize,
        minTextAdapt: true,
        splitScreenMode: true,
        fontSizeResolver: AppResponsive.clampedFontSize,
        builder: (context, child) {
          return MaterialApp(
            title: 'Koniwala Matrimonial',
            scrollBehavior: const _AppScrollBehavior(),
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.noScaling),
                child: child!,
              );
            },
            theme: _buildAppTheme(Brightness.light),
            darkTheme: _buildAppTheme(Brightness.dark),
            initialRoute: AppRoutes.splash,
            navigatorObservers: [appRouteObserver],
            onGenerateRoute: AppRouter.onGenerateRoute,
          );
        },
      ),
    );
  }
}
