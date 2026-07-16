import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:koniwalamatrimonial/attendance_archives_screen.dart';
import 'package:koniwalamatrimonial/dashboard_screen.dart';
import 'package:koniwalamatrimonial/Data Entry operations/data_entry_operations_dashboard_screen.dart';
import 'package:koniwalamatrimonial/rm/relationship_manager_account_screen.dart';
import 'package:koniwalamatrimonial/rm/relationship_manager_dashboard_screen.dart';
import 'package:koniwalamatrimonial/rm/relationship_manager_leads_screen.dart';
import 'package:koniwalamatrimonial/rm/whatsapp_conversation_screen.dart';
import 'package:koniwalamatrimonial/rm/models/rm_lead_item.dart';
import 'package:koniwalamatrimonial/rm/providers/rm_leads_provider.dart';
import 'package:koniwalamatrimonial/owner/Screen/owerner_dashboard_screen.dart';
import 'package:koniwalamatrimonial/login_screen.dart';
import 'package:koniwalamatrimonial/request_new_leave_screen.dart';
import 'package:koniwalamatrimonial/routes/app_routes.dart';
import 'package:koniwalamatrimonial/splash_screen.dart';
import 'package:koniwalamatrimonial/screens/plain_role_screen.dart';
import 'package:koniwalamatrimonial/owner/Screen/registry_screen.dart';
import 'package:koniwalamatrimonial/owner/Screen/leads_registry_screen.dart';
import 'package:koniwalamatrimonial/owner/Screen/client_registry_screen.dart';
import 'package:koniwalamatrimonial/owner/Screen/new_inquiry_screen.dart';
import 'package:koniwalamatrimonial/owner/Screen/create_new_task_screen.dart';
import 'package:koniwalamatrimonial/owner/Screen/lead_follow_ups_screen.dart';
import 'package:koniwalamatrimonial/owner/models/lead_follow_up_item.dart';
import 'package:koniwalamatrimonial/owner/models/customer_registry_item.dart';
import 'package:koniwalamatrimonial/owner/models/match_comparison_args.dart';
import 'package:koniwalamatrimonial/owner/models/registry_profile_item.dart';
import 'package:koniwalamatrimonial/owner/Screen/shortlist_screen.dart';
import 'package:koniwalamatrimonial/owner/Screen/ai_matching_screen.dart';
import 'package:koniwalamatrimonial/owner/Screen/institutional_offer_management_screen.dart';
import 'package:koniwalamatrimonial/owner/Screen/compare_profile_screen.dart';
import 'package:koniwalamatrimonial/screens/edit_profile_screen.dart';
import 'package:koniwalamatrimonial/screens/profile_detail_screen.dart';
import 'package:koniwalamatrimonial/screens/payroll_management_screen.dart';
import 'package:koniwalamatrimonial/screens/notifications_screen.dart';
import 'package:koniwalamatrimonial/owner/Screen/admin_drawer_screen.dart';
import 'package:koniwalamatrimonial/owner/Screen/employee_management_screen.dart';
import 'package:koniwalamatrimonial/owner/Screen/profile_digitizer_screen.dart';
import 'package:koniwalamatrimonial/owner/Screen/new_profile_digitization_screen.dart';
import 'package:koniwalamatrimonial/owner/Screen/leaves_screen.dart';
import 'package:koniwalamatrimonial/owner/Screen/holiday_management_screen.dart';
import 'package:koniwalamatrimonial/owner/Screen/admin_settings_screen.dart';

import '../hr/hr_dashboard_screen.dart';
import '../screens/color_page.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case AppRoutes.registry:
        return MaterialPageRoute(
          builder: (_) => RegistryScreen(onMenuPressed: () {}),
        );
      case AppRoutes.leadsRegistry:
        final initialStage = settings.arguments is String
            ? settings.arguments as String
            : null;
        return MaterialPageRoute(
          builder: (_) => LeadsRegistryScreen(
            showScaffold: true,
            initialStage: initialStage,
          ),
        );
      case AppRoutes.clientRegistry:
        final initialFilter = settings.arguments is ClientRegistryInitialFilter
            ? settings.arguments as ClientRegistryInitialFilter
            : ClientRegistryInitialFilter.all;
        return MaterialPageRoute(
          builder: (_) => ClientRegistryScreen(initialFilter: initialFilter),
        );
      case AppRoutes.newInquiry:
        return MaterialPageRoute(builder: (_) => const NewInquiryScreen());
      case AppRoutes.leadFollowUps:
        return MaterialPageRoute(builder: (_) => const LeadFollowUpsScreen());
      case AppRoutes.createNewTask:
        {
          final lead = settings.arguments is LeadFollowUpItem
              ? settings.arguments as LeadFollowUpItem
              : null;
          return MaterialPageRoute(
            builder: (_) => CreateNewTaskScreen(lead: lead),
          );
        }
      case AppRoutes.shortlist:
        {
          final profile = settings.arguments is RegistryProfileItem
              ? settings.arguments as RegistryProfileItem
              : null;
          return MaterialPageRoute(
            builder: (_) => ShortlistScreen(profile: profile),
          );
        }
      case AppRoutes.aiMatching:
        return MaterialPageRoute(builder: (_) => const AiMatchingScreen());
      case AppRoutes.institutionalOfferManagement:
        return MaterialPageRoute(
          builder: (_) => const InstitutionalOfferManagementScreen(),
        );
      case AppRoutes.compareProfile:
        {
          final args = settings.arguments is MatchComparisonArgs
              ? settings.arguments as MatchComparisonArgs
              : null;
          return MaterialPageRoute(
            builder: (_) => CompareProfileScreen(args: args),
          );
        }
      case AppRoutes.profileDetail:
        {
          final profile = settings.arguments is RegistryProfileItem
              ? settings.arguments as RegistryProfileItem
              : null;
          return MaterialPageRoute(
            builder: (_) => ProfileDetailScreen(profile: profile),
          );
        }
      case AppRoutes.editProfile:
        {
          final profile = settings.arguments is RegistryProfileItem
              ? settings.arguments as RegistryProfileItem
              : null;
          return MaterialPageRoute(
            builder: (_) => EditProfileScreen(profile: profile),
          );
        }
      case AppRoutes.ownerDashboard:
        return MaterialPageRoute(
          builder: (_) => const OwernerDashboardScreen(),
        );
      case AppRoutes.plainRole:
        final roleName = settings.arguments as String? ?? 'Unknown Role';
        return MaterialPageRoute(
          builder: (_) => PlainRoleScreen(roleName: roleName),
        );
      case AppRoutes.attendanceArchives:
        return MaterialPageRoute(
          builder: (_) => const AttendanceArchivesScreen(),
        );
      case AppRoutes.requestNewLeave:
        return MaterialPageRoute(builder: (_) => const RequestNewLeaveScreen());
      case AppRoutes.colorPage: // New case for the color page
        return MaterialPageRoute(builder: (_) => const ColorPage());
      case AppRoutes.dataEntryDashboard:
        return MaterialPageRoute(
          builder: (_) => const DataEntryOperationsDashboardScreen(),
        );
      case AppRoutes.relationshipManagerDashboard:
        return MaterialPageRoute(
          builder: (_) => const RelationshipManagerDashboardScreen(),
        );
      case AppRoutes.relationshipManagerAccount:
        return MaterialPageRoute(
          builder: (_) => const RelationshipManagerAccountScreen(),
        );
      case AppRoutes.relationshipManagerLeads:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => RmLeadsProvider(),
            child: const RelationshipManagerLeadsScreen(),
          ),
        );
      // LeadsRegistryScreen(
      // onMenuPressed: () =>
      // Navigator.of(context).pushNamed(AppRoutes.adminDrawer),
      // ),
      case AppRoutes.whatsappConversation:
        final lead = settings.arguments is RmLeadItem
            ? settings.arguments as RmLeadItem
            : null;
        return MaterialPageRoute(
          builder: (_) => WhatsappConversationScreen(lead: lead),
        );
      case AppRoutes.hrDashboard:
        return MaterialPageRoute(
          builder: (_) => HrDashboardScreen(),
          // const OwernerDashboardScreen(),
        );
      case AppRoutes.payrollManagement:
        return MaterialPageRoute(
          builder: (_) => const PayrollManagementScreen(),
        );
      case AppRoutes.adminDrawer:
        return PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.transparent,
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AdminDrawerScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      case AppRoutes.profileDigitizer:
        return MaterialPageRoute(
          builder: (_) => const ProfileDigitizerScreen(),
        );
      case AppRoutes.newProfileDigitization:
        final customer = settings.arguments is CustomerRegistryItem
            ? settings.arguments as CustomerRegistryItem
            : null;
        return MaterialPageRoute(
          builder: (_) => NewProfileDigitizationScreen(customer: customer),
        );
      case AppRoutes.employeeManagement:
        return MaterialPageRoute(
          builder: (_) => const EmployeeManagementScreen(),
        );
      case AppRoutes.leaves:
        return MaterialPageRoute(builder: (_) => const LeavesScreen());
      case AppRoutes.holidayManagement:
        return MaterialPageRoute(
          builder: (_) => const HolidayManagementScreen(),
        );
      case AppRoutes.notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      case AppRoutes.adminSettings:
        return MaterialPageRoute(builder: (_) => const AdminSettingsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const _UnknownRouteScreen(),
          settings: settings,
        );
    }
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Unknown route')));
  }
}
