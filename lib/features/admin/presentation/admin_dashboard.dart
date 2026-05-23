import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/auth_provider.dart';
import '../providers/invigilator_provider.dart';
import '../providers/center_provider.dart';
import '../../invigilator/providers/duty_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch live states from Riverpod providers
    final invCount = ref.watch(invigilatorProvider).length;
    final centerCount = ref.watch(centerProvider).length;
    final duties = ref.watch(globalDutyProvider);
    
    final activeCount = duties.where((d) => d.status.toLowerCase() == 'accepted').length;
    final pendingCount = duties.where((d) => d.status.toLowerCase() == 'pending').length;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenBgColor = isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: screenBgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER ROW (Greeting + AD Teal Avatar)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Good morning',
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '👋',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Admin Dashboard',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  // AD Teal Avatar
                  GestureDetector(
                    onTap: () => _showLogoutDialog(context, ref),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFF007A87), // Deep Teal color from mockup
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'AD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. SYSTEM OVERVIEW HERO BANNER
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1B2A), // Premium Dark Navy
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // Decorative Overlapping Circle 1 (Deep Blue)
                      Positioned(
                        right: -30,
                        top: -40,
                        child: Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1B4965).withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      // Decorative Overlapping Circle 2 (Teal)
                      Positioned(
                        right: -40,
                        bottom: -50,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF007A87).withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      // Content Inside Banner Card
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SYSTEM OVERVIEW',
                                  style: TextStyle(
                                    color: Color(0xFF8E9AAF),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Exam Invigilation\nControl Center',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                    letterSpacing: -0.2,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        offset: const Offset(0, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Stats Row
                            Row(
                              children: [
                                _buildBannerStat(invCount.toString(), 'Invigilators'),
                                _buildVerticalDivider(),
                                _buildBannerStat(activeCount.toString(), 'Active Duties'),
                                _buildVerticalDivider(),
                                _buildBannerStat(centerCount.toString(), 'Centers'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // 3. STATS AT A GLANCE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Stats at a Glance',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/admin_dashboard/reports'),
                    child: const Text(
                      'See all',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 2x2 Grid of Outline HSL Colored-Shadow Cards
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.15,
                children: [
                  _StatCard(
                    title: 'Total Invigilators',
                    count: invCount.toString(),
                    icon: Icons.people_alt_rounded,
                    bgColor: const Color(0xFFEFF6FF),
                    borderColor: const Color(0xFFBFDBFE),
                    tintColor: const Color(0xFF1D4ED8),
                    onTap: () => context.go('/admin_dashboard/manage_invigilators'),
                  ),
                  _StatCard(
                    title: 'Active Duties',
                    count: activeCount.toString(),
                    icon: Icons.checklist_rtl_rounded,
                    bgColor: const Color(0xFFECFDF5),
                    borderColor: const Color(0xFFA7F3D0),
                    tintColor: const Color(0xFF047857),
                    onTap: () => context.go('/admin_dashboard/reports?filter=accepted'),
                  ),
                  _StatCard(
                    title: 'Pending Duties',
                    count: pendingCount.toString(),
                    icon: Icons.hourglass_empty_rounded,
                    bgColor: const Color(0xFFFFFBEB),
                    borderColor: const Color(0xFFFDE68A),
                    tintColor: const Color(0xFFB45309),
                    onTap: () => context.go('/admin_dashboard/reports?filter=pending'),
                  ),
                  _StatCard(
                    title: 'Total Centers',
                    count: centerCount.toString(),
                    icon: Icons.business_rounded,
                    bgColor: const Color(0xFFF5F3FF),
                    borderColor: const Color(0xFFDDD6FE),
                    tintColor: const Color(0xFF6D28D9),
                    onTap: () => context.go('/admin_dashboard/manage_centers'),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // 4. QUICK ACTIONS
              Text(
                'Quick Actions',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 16),
              // 2x2 Grid of Anthracite Dark Cards
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _ActionCard(
                    title: 'Manage Invigilators',
                    subtitle: 'Add or edit staff',
                    icon: Icons.people_outline_rounded,
                    iconColor: const Color(0xFF1D4ED8),
                    onTap: () => context.go('/admin_dashboard/manage_invigilators'),
                  ),
                  _ActionCard(
                    title: 'Allocate Duty',
                    subtitle: 'Assign sessions',
                    icon: Icons.assignment_rounded,
                    iconColor: const Color(0xFF047857),
                    onTap: () => context.go('/admin_dashboard/allocate_duty'),
                  ),
                  _ActionCard(
                    title: 'Manage Centers',
                    subtitle: 'Venues & halls',
                    icon: Icons.location_city_rounded,
                    iconColor: const Color(0xFFB45309),
                    onTap: () => context.go('/admin_dashboard/manage_centers'),
                  ),
                  _ActionCard(
                    title: 'View Reports',
                    subtitle: 'Analytics & logs',
                    icon: Icons.bar_chart_rounded,
                    iconColor: const Color(0xFF6D28D9),
                    onTap: () => context.go('/admin_dashboard/reports'),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // 5. RECENT ACTIVITY
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Activity',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/admin_dashboard/reports'),
                    child: const Text(
                      'View all',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // List of 3 Anthracite Activity Cards
              _ActivityItem(
                title: 'Duty assigned — Hall A',
                timestamp: 'Today · 09:30 AM',
                icon: Icons.assignment_turned_in_rounded,
                iconColor: const Color(0xFF047857),
                badgeText: 'Live',
                badgeColor: const Color(0xFF047857),
                badgeBgColor: const Color(0xFFECFDF5),
              ),
              const SizedBox(height: 12),
              _ActivityItem(
                title: 'Center 01 registered',
                timestamp: 'Yesterday · 04:12 PM',
                icon: Icons.business_center_rounded,
                iconColor: const Color(0xFF1D4ED8),
                badgeText: 'Done',
                badgeColor: const Color(0xFF1D4ED8),
                badgeBgColor: const Color(0xFFEFF6FF),
              ),
              const SizedBox(height: 12),
              _ActivityItem(
                title: 'New invigilator onboarded',
                timestamp: '20 May · 11:00 AM',
                icon: Icons.person_add_rounded,
                iconColor: const Color(0xFFB45309),
                badgeText: 'Review',
                badgeColor: const Color(0xFFB45309),
                badgeBgColor: const Color(0xFFFFFBEB),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      // 6. PREMIUM CUSTOM BOTTOM NAVIGATION BAR
      bottomNavigationBar: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.grey.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, 'Home', Icons.home_rounded, true, () {}),
            _buildNavItem(context, 'Staff', Icons.people_outline_rounded, false, () {
              context.go('/admin_dashboard/manage_invigilators');
            }),
            _buildNavItem(context, 'Duties', Icons.assignment_outlined, false, () {
              context.go('/admin_dashboard/allocate_duty');
            }),
            _buildNavItem(context, 'Reports', Icons.analytics_outlined, false, () {
              context.go('/admin_dashboard/reports');
            }),
            _buildNavItem(context, 'Settings', Icons.settings_outlined, false, () {
              _showLogoutDialog(context, ref);
            }),
          ],
        ),
      ),
    );
  }

  // Helper to build System Overview banner statistics columns
  Widget _buildBannerStat(String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8E9AAF),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Divider inside the banner card
  Widget _buildVerticalDivider() {
    return Container(
      height: 32,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  // Helper for Bottom Nav Item with blue dot indicator
  Widget _buildNavItem(BuildContext context, String label, IconData icon, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 4),
          // Dynamic Blue selection dot
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  // Show a standard elegant Logout dialog
  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out of DutyDesk?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// CUSTOM SUB-WIDGETS FOR REDESIGNED COMPONENTS
// ----------------------------------------------------

// 1. Colored Tint Statistics Card (2x2 Grid)
class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color bgColor;
  final Color borderColor;
  final Color tintColor;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.bgColor,
    required this.borderColor,
    required this.tintColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: tintColor.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top-left Icon Block (Rounded Square)
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: tintColor,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            // Statistics Label & Value
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: TextStyle(
                    color: tintColor,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: tintColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 2. Anthracite Dark Action Card (2x2 Grid)
class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF22252A), // Anthracite background from mockup
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            child: Row(
              children: [
                // White Rounded Square Icon block
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                // Titles Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 3. Anthracite Dark Recent Activity Row Card
class _ActivityItem extends StatelessWidget {
  final String title;
  final String timestamp;
  final IconData icon;
  final Color iconColor;
  final String badgeText;
  final Color badgeColor;
  final Color badgeBgColor;

  const _ActivityItem({
    required this.title,
    required this.timestamp,
    required this.icon,
    required this.iconColor,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFF22252A), // Anthracite background from mockup
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: White rounded square icon block
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          // Middle: Text & timestamp
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timestamp,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Right: Outlined Colored Pill Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBgColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: badgeColor.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: badgeColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
