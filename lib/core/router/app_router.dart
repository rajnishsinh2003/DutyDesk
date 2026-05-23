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
import '../../features/admin/providers/center_provider.dart';
import '../../features/admin/providers/invigilator_provider.dart';

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
      path: '/admin_dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
      routes: [
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
      ],
    ),
    GoRoute(
      path: '/invigilator_dashboard',
      builder: (context, state) => const InvigilatorDashboardScreen(),
    ),
  ],
);
