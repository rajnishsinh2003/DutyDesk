import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/admin/presentation/admin_dashboard.dart';
import '../../features/admin/presentation/add_invigilator_screen.dart';
import '../../features/admin/presentation/manage_invigilators_screen.dart';
import '../../features/admin/presentation/duty_allocation_screen.dart';
import '../../features/admin/presentation/session_assignment_screen.dart';
import '../../features/admin/presentation/manage_centers_screen.dart';
import '../../features/admin/presentation/add_center_screen.dart';
import '../../features/admin/presentation/admin_reports_screen.dart';
import '../../features/invigilator/presentation/invigilator_dashboard.dart';
import '../../features/admin/presentation/invigilator_profile_screen.dart';
import '../../features/admin/presentation/invigilator_availability_calendar_screen.dart';
import '../../features/admin/presentation/maintain_data_screen.dart';
import '../../features/admin/presentation/maintain_home_screen.dart';
import '../../features/admin/presentation/global_search_screen.dart';
import '../../features/admin/presentation/live_control_room_screen.dart';
import '../../features/admin/presentation/admin_payroll_screen.dart';
import '../../features/notifications/presentation/notification_center_screen.dart';
import '../../features/admin/presentation/language_settings_screen.dart';
import '../../features/admin/providers/center_provider.dart';
import '../../features/admin/providers/invigilator_provider.dart';
import '../../features/incidents/presentation/admin_incidents_screen.dart';
import '../../features/centers/presentation/center_hierarchy_screen.dart';
import '../../features/auditor/presentation/auditor_dashboard.dart';
import '../../features/seating/presentation/seating_plan_screen.dart';
import '../../features/dispatch/presentation/question_paper_tracker_screen.dart';
import '../../features/answersheets/presentation/answer_sheet_collection_screen.dart';
import '../../features/admin/presentation/bulk_import_screen.dart';
import '../../features/audit_trail/presentation/audit_trail_screen.dart';
import '../../features/roles/presentation/role_based_dashboard_screen.dart';
import '../../features/cctv/presentation/cctv_monitor_screen.dart';
import '../../features/portal/presentation/student_portal_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationCenterScreen(),
    ),
    GoRoute(
      path: '/settings/language',
      builder: (context, state) => const LanguageSettingsScreen(),
    ),
    GoRoute(
      path: '/admin_dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
      routes: [
        GoRoute(
          path: 'control_room',
          builder: (context, state) => const LiveControlRoomScreen(),
        ),
        GoRoute(
          path: 'payroll',
          builder: (context, state) => const AdminPayrollScreen(),
        ),
        GoRoute(
          path: 'manage_invigilators',
          builder: (context, state) => const ManageInvigilatorsScreen(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => const AddInvigilatorScreen(),
            ),
            GoRoute(
              path: 'edit',
              builder: (context, state) {
                final inv = state.extra as Invigilator;
                return AddInvigilatorScreen(existingInvigilator: inv);
              },
            ),
            GoRoute(
              path: 'profile/:id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return InvigilatorProfileScreen(invigilatorId: id);
              },
            ),
            GoRoute(
              path: 'availability',
              builder: (context, state) => const InvigilatorAvailabilityCalendarScreen(),
            ),
          ]
        ),
        GoRoute(
          path: 'manage_centers',
          builder: (context, state) => const ManageCentersScreen(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => const AddCenterScreen(),
            ),
            GoRoute(
              path: 'edit',
              builder: (context, state) {
                final center = state.extra as ExamCenter;
                return AddCenterScreen(existingCenter: center);
              },
            ),
            GoRoute(
              path: 'details/:centerId',
              builder: (context, state) {
                final centerId = state.pathParameters['centerId']!;
                return CenterHierarchyScreen(centerId: centerId);
              },
            ),
          ]
        ),
        GoRoute(
          path: 'allocate_duty',
          builder: (context, state) => const DutyAllocationScreen(),
          routes: [
            GoRoute(
              path: 'session/:sessionId',
              builder: (context, state) {
                final sessionId = state.pathParameters['sessionId']!;
                return SessionAssignmentScreen(sessionId: sessionId);
              },
            ),
          ],
        ),
        GoRoute(
          path: 'reports',
          builder: (context, state) {
            final filter = state.uri.queryParameters['filter'];
            return AdminReportsScreen(initialStatusFilter: filter);
          },
        ),
        GoRoute(
          path: 'maintain_data',
          builder: (context, state) => const MaintainDataScreen(),
        ),
        GoRoute(
          path: 'maintain_home',
          builder: (context, state) => const MaintainHomeScreen(),
        ),
        GoRoute(
          path: 'global_search',
          builder: (context, state) => const GlobalSearchScreen(),
        ),
        GoRoute(
          path: 'incidents',
          builder: (context, state) => const AdminIncidentsScreen(),
        ),
        GoRoute(
          path: 'seating_plans',
          builder: (context, state) => const SeatingPlanScreen(),
        ),
        GoRoute(
          path: 'paper_dispatch',
          builder: (context, state) => const QuestionPaperTrackerScreen(),
        ),
        GoRoute(
          path: 'answer_sheets',
          builder: (context, state) => const AnswerSheetCollectionScreen(),
        ),
        GoRoute(
          path: 'bulk_import',
          builder: (context, state) => const BulkImportScreen(),
        ),
        GoRoute(
          path: 'audit_trail',
          builder: (context, state) => const AuditTrailScreen(),
        ),
        GoRoute(
          path: 'cctv',
          builder: (context, state) => const CctvMonitorScreen(),
        ),
        GoRoute(
          path: 'role/:role',
          builder: (context, state) {
            final role = state.pathParameters['role'] ?? 'coe';
            return RoleBasedDashboardScreen(role: role);
          },
        ),
        GoRoute(
          path: 'student_portal',
          builder: (context, state) => const StudentPortalScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/invigilator_dashboard',
      builder: (context, state) => const InvigilatorDashboardScreen(),
    ),
    GoRoute(
      path: '/auditor_dashboard',
      builder: (context, state) => const AuditorDashboardScreen(),
    ),
    GoRoute(
      path: '/paper_dispatch',
      builder: (context, state) => const QuestionPaperTrackerScreen(),
    ),
    GoRoute(
      path: '/answer_sheets',
      builder: (context, state) => const AnswerSheetCollectionScreen(),
    ),
    GoRoute(
      path: '/audit_trail',
      builder: (context, state) => const AuditTrailScreen(),
    ),
    GoRoute(
      path: '/cctv',
      builder: (context, state) => const CctvMonitorScreen(),
    ),
    GoRoute(
      path: '/role_dashboard/:role',
      builder: (context, state) {
        final role = state.pathParameters['role'] ?? 'coe';
        return RoleBasedDashboardScreen(role: role);
      },
    ),
    GoRoute(
      path: '/portal',
      builder: (context, state) => const StudentPortalScreen(),
    ),
  ],
);
