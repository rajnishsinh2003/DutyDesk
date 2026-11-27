import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/auth_provider.dart';
import '../../chatbot/presentation/widget/chatbot_launcher.dart';

/// DutyDesk Official Web Landing & Overview Index Screen.
/// Provides a comprehensive, enterprise-grade presentation of all DutyDesk modules,
/// live operational metrics, security chain-of-custody protocols, stakeholder portals,
/// and direct single-click redirection into the Login portal.
class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _securityKey = GlobalKey();
  final GlobalKey _rolesKey = GlobalKey();
  final GlobalKey _workflowKey = GlobalKey();
  final GlobalKey _faqKey = GlobalKey();

  int _selectedRoleTab = 0;
  final Set<int> _expandedFaqIndices = {0};

  void _scrollToKey(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Palette Tokens
    final bg = isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF131B2E) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const brandColor = Color(0xFF007A87);
    const brandCyan = Color(0xFF06B6D4);

    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Background ambient gradient glow
          Positioned(
            top: -120,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    brandColor.withValues(alpha: isDark ? 0.18 : 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 400,
            right: -150,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    brandCyan.withValues(alpha: isDark ? 0.12 : 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Scrollable Page
          SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 80), // Navbar spacing

                // 1. HERO SECTION
                _buildHeroSection(
                  context,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  brandColor: brandColor,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  isLoggedIn: authState.userId != null,
                ),

                // 2. LIVE METRICS & IMPACT BAR
                _buildImpactMetricsBar(isDark: isDark, cardBg: cardBg, cardBorder: cardBorder),

                const SizedBox(height: 60),

                // 3. CORE PLATFORM PILLARS (WHAT WE PROVIDE)
                Container(
                  key: _featuresKey,
                  child: _buildCoreFeaturesGrid(
                    context,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    brandColor: brandColor,
                  ),
                ),

                const SizedBox(height: 70),

                // 4. SECURITY & CHAIN OF CUSTODY DEEP DIVE
                Container(
                  key: _securityKey,
                  child: _buildSecurityProtocolSection(
                    context,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    brandColor: brandColor,
                  ),
                ),

                const SizedBox(height: 70),

                // 5. STAKEHOLDER PORTALS (ROLE-BASED VALUE)
                Container(
                  key: _rolesKey,
                  child: _buildStakeholdersSection(
                    context,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    brandColor: brandColor,
                  ),
                ),

                const SizedBox(height: 70),

                // 6. EXAMINATION OPERATIONS WORKFLOW (TIMELINE)
                Container(
                  key: _workflowKey,
                  child: _buildWorkflowSection(
                    context,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    brandColor: brandColor,
                  ),
                ),

                const SizedBox(height: 70),

                // 7. FREQUENTLY ASKED QUESTIONS (FAQ)
                Container(
                  key: _faqKey,
                  child: _buildFaqSection(
                    context,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    brandColor: brandColor,
                  ),
                ),

                const SizedBox(height: 80),

                // 8. FINAL CALL TO ACTION (CTA)
                _buildFinalCtaSection(
                  context,
                  isDark: isDark,
                  brandColor: brandColor,
                ),

                const SizedBox(height: 60),

                // 9. FOOTER
                _buildFooter(
                  context,
                  isDark: isDark,
                  textSecondary: textSecondary,
                  cardBorder: cardBorder,
                ),
              ],
            ),
          ),

          // STICKY TOP NAVIGATION BAR
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildStickyNavbar(
              context,
              isDark: isDark,
              cardBg: cardBg,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              brandColor: brandColor,
              isLoggedIn: authState.userId != null,
            ),
          ),

          // AI CHATBOT FLOATING LAUNCHER
          const Positioned(
            bottom: 20,
            right: 20,
            child: ChatbotLauncher(surface: 'landing'),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 1. STICKY TOP NAVBAR
  // =========================================================================
  Widget _buildStickyNavbar(
    BuildContext context, {
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color brandColor,
    required bool isLoggedIn,
  }) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF090D16) : Colors.white).withValues(alpha: 0.92),
        border: Border(bottom: BorderSide(color: cardBorder, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // BRAND LOGO & TITLE
              InkWell(
                onTap: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF007A87), Color(0xFF06B6D4)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF007A87).withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.shield_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'DutyDesk',
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: brandColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: brandColor.withValues(alpha: 0.3), width: 0.8),
                                ),
                                child: Text(
                                  'GOV / NTA READY',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    color: brandColor,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Smart Examination Administration System',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // DESKTOP NAVIGATION LINKS (Hidden on small mobile screens)
              if (MediaQuery.of(context).size.width > 860)
                Row(
                  children: [
                    _navTextButton('Features', () => _scrollToKey(_featuresKey), isDark),
                    _navTextButton('Security', () => _scrollToKey(_securityKey), isDark),
                    _navTextButton('Stakeholders', () => _scrollToKey(_rolesKey), isDark),
                    _navTextButton('Workflow', () => _scrollToKey(_workflowKey), isDark),
                    _navTextButton('FAQ', () => _scrollToKey(_faqKey), isDark),
                    _navTextButton('Student Portal', () => context.push('/portal'), isDark, isAccent: true),
                  ],
                ),

              // CTA BUTTONS
              Row(
                children: [
                  // Student Portal on smaller screens
                  if (MediaQuery.of(context).size.width <= 860)
                    IconButton(
                      icon: const Icon(Icons.school_outlined),
                      tooltip: 'Public Student Portal',
                      onPressed: () => context.push('/portal'),
                    ),

                  const SizedBox(width: 8),

                  // PRIMARY LOGIN / SIGN IN BUTTON
                  ElevatedButton.icon(
                    icon: Icon(
                      isLoggedIn ? Icons.dashboard_rounded : Icons.login_rounded,
                      size: 18,
                    ),
                    label: Text(
                      isLoggedIn ? 'Go to Dashboard' : 'Sign In / Login',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandColor,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shadowColor: brandColor.withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      context.go('/login');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navTextButton(String title, VoidCallback onTap, bool isDark, {bool isAccent = false}) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: isAccent
            ? const Color(0xFF007A87)
            : (isDark ? Colors.grey.shade300 : const Color(0xFF334155)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: isAccent ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );
  }

  // =========================================================================
  // 2. HERO SECTION
  // =========================================================================
  Widget _buildHeroSection(
    BuildContext context, {
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color brandColor,
    required Color cardBg,
    required Color cardBorder,
    required bool isLoggedIn,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 980;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
          child: Column(
            children: [
              // ANNOUNCEMENT BADGE PILL
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: brandColor.withValues(alpha: isDark ? 0.16 : 0.08),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: brandColor.withValues(alpha: 0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Color(0xFF007A87), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Next-Gen Examination Administration & Zero-Trust Invigilation Protocol',
                      style: TextStyle(
                        color: brandColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // MAIN HERO HEADLINE
              Text(
                'Complete Security, Automated Rostering &\nZero-Leak Examination Governance',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: isDesktop ? 46 : (screenWidth > 600 ? 36 : 28),
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                  height: 1.15,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 20),

              // SUBTITLE DESCRIPTION
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Text(
                  'DutyDesk is the unified operating platform for universities, state examination commissions, and higher-education institutions. Automate clash-free invigilator duty allocation, enforce biometric and GPS-geofenced attendance, secure question paper vaults, and mathematically reconcile answer script dockets in real-time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isDesktop ? 16.5 : 14.5,
                    color: textSecondary,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ACTION BUTTON ROW
              Wrap(
                spacing: 16,
                runSpacing: 14,
                alignment: WrapAlignment.center,
                children: [
                  // PRIMARY LOGIN BUTTON
                  ElevatedButton.icon(
                    icon: Icon(
                      isLoggedIn ? Icons.dashboard_rounded : Icons.login_rounded,
                      size: 20,
                    ),
                    label: Text(
                      isLoggedIn ? 'Launch Dashboard' : 'Sign In to Portal',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                      elevation: 4,
                      shadowColor: brandColor.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      context.go('/login');
                    },
                  ),

                  // EXPLORE CAPABILITIES BUTTON
                  OutlinedButton.icon(
                    icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                    label: const Text(
                      'Explore Capabilities',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      side: BorderSide(color: cardBorder, width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _scrollToKey(_featuresKey),
                  ),

                  // PUBLIC STUDENT PORTAL
                  TextButton.icon(
                    icon: const Icon(Icons.school_outlined, size: 18, color: Color(0xFF007A87)),
                    label: const Text(
                      'Public Student & Parent Portal →',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF007A87)),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    ),
                    onPressed: () => context.push('/portal'),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // HERO SIMULATION DASHBOARD PREVIEW CARD
              _buildHeroPreviewCard(
                isDark: isDark,
                cardBg: cardBg,
                cardBorder: cardBorder,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                brandColor: brandColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroPreviewCard({
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
    required Color brandColor,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1040),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Preview Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              color: isDark ? const Color(0xFF0A101D) : const Color(0xFFF1F5F9),
              child: Row(
                children: [
                  Row(
                    children: [
                      Container(width: 11, height: 11, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Container(width: 11, height: 11, decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Container(width: 11, height: 11, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'https://dutydesk.nta.gov.in/live_control_room • Live Operations Session',
                        style: TextStyle(fontSize: 11.5, color: textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fiber_manual_record, color: Color(0xFF10B981), size: 10),
                        SizedBox(width: 4),
                        Text('LIVE TELEMETRY', style: TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Preview Interactive Content
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Central Examination Monitoring Console',
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                          ),
                          Text(
                            'Real-time status across n testing centers & n examination rooms',
                            style: TextStyle(fontSize: 12, color: textSecondary),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => context.go('/login'),
                        child: const Text('Access Console →'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Mini Metric Pills
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      _previewStatCard('Total Duties Allocated', '0', Icons.assignment_turned_in, const Color(0xFF2563EB), isDark),
                      _previewStatCard('On-Time Arrival Rate', '0%', Icons.gps_fixed, const Color(0xFF10B981), isDark),
                      _previewStatCard('Paper Custody Breaches', '0', Icons.verified_user, const Color(0xFF007A87), isDark),
                      _previewStatCard('Form B Script Balance', '0% Balanced', Icons.inventory_2, const Color(0xFF6366F1), isDark),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.grey), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 3. IMPACT METRICS BAR
  // =========================================================================
  Widget _buildImpactMetricsBar({
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cardBorder, width: 1),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 700;
                if (isNarrow) {
                  return Column(
                    children: [
                      _metricStat('0+', 'Examination Duties Managed'),
                      const Divider(height: 24),
                      _metricStat('0%', 'Zero-Leak Paper Custody'),
                      const Divider(height: 24),
                      _metricStat('0%', 'Geofence Attendance Accuracy'),
                      const Divider(height: 24),
                      _metricStat('0 / 0', 'Enterprise Modules Operational'),
                    ],
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _metricStat('0+', 'Examination Duties Managed'),
                    _verticalDivider(cardBorder),
                    _metricStat('0%', 'Zero-Leak Paper Custody'),
                    _verticalDivider(cardBorder),
                    _metricStat('0%', 'Geofence Attendance Accuracy'),
                    _verticalDivider(cardBorder),
                    _metricStat('0 / 0', 'Enterprise Modules Operational'),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _metricStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF007A87),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _verticalDivider(Color color) {
    return Container(width: 1, height: 42, color: color);
  }

  // =========================================================================
  // 4. CORE PLATFORM PILLARS (WHAT WE PROVIDE)
  // =========================================================================
  Widget _buildCoreFeaturesGrid(
    BuildContext context, {
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardBg,
    required Color cardBorder,
    required Color brandColor,
  }) {
    final features = [
      _FeatureItem(
        icon: Icons.auto_awesome_rounded,
        title: 'Automated Duty Allocation & Fairness Engine',
        tag: 'CORE ALGORITHM',
        color: const Color(0xFF2563EB),
        bullets: [
          'Clash-free scheduling preventing double booking across shifts',
          'Faculty fairness algorithm balancing cumulative invigilation workload',
          'Automated standby pool with emergency replacement dispatch',
          'Peer-to-peer duty swap workflow with admin sign-off approval',
        ],
      ),
      _FeatureItem(
        icon: Icons.gps_fixed_rounded,
        title: 'Zero-Trust Geofenced Attendance & Anti-Proxy',
        tag: 'HIGH SECURITY',
        color: const Color(0xFF10B981),
        bullets: [
          'Mandatory GPS geodesic verification with strict center radius check',
          'Device camera biometric face verification with liveness alignment frame',
          'BLE beacon proximity detection ensuring continuous in-room presence',
          'Dynamic cryptographic QR gate passes with security guard scanner',
        ],
      ),
      _FeatureItem(
        icon: Icons.lock_clock_rounded,
        title: 'Question Paper Custody & Time-Locked Unsealing',
        tag: 'CHAIN OF CUSTODY',
        color: const Color(0xFFD97706),
        bullets: [
          'Strongroom vault checkout barcode scanning with escort timestamps',
          'Strict time-locked unsealing preventing premature packet opening',
          'Digital authentication of 2 candidate student witnesses before unseal',
          'Instant tamper incident escalation directly to COE and Control Room',
        ],
      ),
      _FeatureItem(
        icon: Icons.fact_check_rounded,
        title: 'Answer Script Reconciliation & Form B Docket',
        tag: 'STATUTORY AUDIT',
        color: const Color(0xFF8B5CF6),
        bullets: [
          'Mathematical validation: Registered = Present + Absent = Collected + Blank',
          'Granular absentee roll-number verification and tracking',
          'Tamper-evident wax seal barcode serialization and custody log',
          'One-click statutory Form B Docket PDF generation for evaluation centers',
        ],
      ),
      _FeatureItem(
        icon: Icons.monitor_heart_rounded,
        title: 'Live Control Room & Real-Time CCTV Console',
        tag: 'COMMAND CENTER',
        color: const Color(0xFF06B6D4),
        bullets: [
          'Live arrival telemetry with punctuality performance rankings',
          'Multi-feed IP/RTSP CCTV camera surveillance grid (2x2 / 3x3 layout)',
          'Instant direct dialer to center superintendents and invigilators',
          'Incident ticketing with severity tags (Malpractice, Technical, Medical)',
        ],
      ),
      _FeatureItem(
        icon: Icons.account_balance_wallet_rounded,
        title: 'Automated Payroll & Salary Remuneration',
        tag: 'FINANCE & BILLING',
        color: const Color(0xFF059669),
        bullets: [
          'Automatic session honorarium calculation based on shift configurations',
          'Travel Allowance (TA/DA) per km computation for external center travel',
          'Bank account & IFSC directory validation for faculty disbursements',
          'One-click Excel (.xlsx) batch export and printable PDF remuneration slips',
        ],
      ),
      _FeatureItem(
        icon: Icons.grid_view_rounded,
        title: 'Anti-Cheating Seating Plan Engine',
        tag: 'EXAMINATION HALL',
        color: const Color(0xFFEC4899),
        bullets: [
          'Interactive 2D room grid generator with custom rows, cols & buffer seats',
          'Anti-cheating alternate-branch student placement algorithm',
          'Candidate seat manifests and hall door notice printables',
          'Instant candidate schedule lookup via the public student portal',
        ],
      ),
      _FeatureItem(
        icon: Icons.cloud_sync_rounded,
        title: 'Bulk Data Migration & Immutable Audit Log',
        tag: 'ENTERPRISE SCALE',
        color: const Color(0xFF3B82F6),
        bullets: [
          'Drag-and-drop Excel (.xlsx) / CSV batch importer for centers and faculty',
          'Conflict resolution policy (skip, overwrite, duplicate)',
          'Immutable chronological administrative activity trail',
          'Semester-end archival and secure data purge lifecycle',
        ],
      ),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // Section Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: brandColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'COMPREHENSIVE CAPABILITIES',
                  style: TextStyle(color: brandColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Everything Needed for Leak-Proof Exam Operations',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Text(
                  'From pre-examination roster planning to post-exam remuneration settlement, DutyDesk replaces fragmented paper files with zero-trust automation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.5, color: textSecondary, height: 1.5),
                ),
              ),
              const SizedBox(height: 36),

              // Feature Cards Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 980 ? 2 : 1;
                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: features.map((f) {
                      final cardWidth = crossAxisCount == 2
                          ? (constraints.maxWidth - 20) / 2
                          : constraints.maxWidth;

                      return SizedBox(
                        width: cardWidth,
                        child: _buildFeatureCard(
                          f,
                          isDark: isDark,
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    _FeatureItem item, {
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: item.color.withValues(alpha: 0.3), width: 0.8),
                ),
                child: Text(
                  item.tag,
                  style: TextStyle(
                    color: item.color,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            item.title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...item.bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4, right: 8),
                    child: Icon(Icons.check_circle_rounded, size: 14, color: item.color),
                  ),
                  Expanded(
                    child: Text(
                      b,
                      style: TextStyle(fontSize: 12.5, color: textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 5. SECURITY & CHAIN OF CUSTODY SECTION
  // =========================================================================
  Widget _buildSecurityProtocolSection(
    BuildContext context, {
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardBg,
    required Color cardBorder,
    required Color brandColor,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF0F1E2E), const Color(0xFF0C1624)]
                    : [const Color(0xFFF0FDF4), const Color(0xFFF8FAFC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? const Color(0xFF1E3A52) : const Color(0xFFBBF7D0),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.security_rounded, color: Color(0xFF10B981), size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Zero-Leak Custody & Cryptographic Verification',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            'State-level examination integrity protocols enforced via digital tamper-locks',
                            style: TextStyle(fontSize: 12.5, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 3 Security Columns
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth > 760;
                    return Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: [
                        _securityProtocolCard(
                          title: 'Time-Locked Question Paper Vault',
                          desc: 'Packets remain cryptographically locked until scheduled release windows. Early opening triggers alarms across Control Room consoles.',
                          icon: Icons.timer_outlined,
                          isDark: isDark,
                          width: isDesktop ? (constraints.maxWidth - 40) / 3 : constraints.maxWidth,
                        ),
                        _securityProtocolCard(
                          title: '2-Student Witness Verification',
                          desc: 'Digital witness protocols capture candidate roll numbers and timestamps before envelope seals can be legally unsealed in the exam hall.',
                          icon: Icons.people_outline,
                          isDark: isDark,
                          width: isDesktop ? (constraints.maxWidth - 40) / 3 : constraints.maxWidth,
                        ),
                        _securityProtocolCard(
                          title: 'Form B Mathematical Reconciliation',
                          desc: 'Guarantees zero script displacement: Every single printed paper, used script, and blank returned is mathematically balanced.',
                          icon: Icons.calculate_outlined,
                          isDark: isDark,
                          width: isDesktop ? (constraints.maxWidth - 40) / 3 : constraints.maxWidth,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _securityProtocolCard({
    required String title,
    required String desc,
    required IconData icon,
    required bool isDark,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF132337) : Colors.white).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isDark ? Colors.white12 : Colors.black12),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF10B981), size: 24),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 6),
          Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.45)),
        ],
      ),
    );
  }

  // =========================================================================
  // 6. STAKEHOLDER PORTALS SECTION
  // =========================================================================
  Widget _buildStakeholdersSection(
    BuildContext context, {
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardBg,
    required Color cardBorder,
    required Color brandColor,
  }) {
    final roles = [
      _RoleInfo(
        title: 'Super Admin & COE',
        subtitle: 'Controller of Examinations & University Admins',
        icon: Icons.admin_panel_settings_rounded,
        accentColor: const Color(0xFF007A87),
        desc: 'Complete high-level governance of sessions, center readiness audits, automated fairness allocations, incident resolutions, and multi-channel broadcast notices via WhatsApp & SMS.',
        route: '/login',
      ),
      _RoleInfo(
        title: 'Invigilators & Faculty',
        subtitle: 'Examination Room Staff & Supervisors',
        icon: Icons.badge_rounded,
        accentColor: const Color(0xFF2563EB),
        desc: 'Mobile-first console featuring duty acceptance/rejection, peer duty swapping, GPS geodesic clock-in, AI face verification, digital gate pass badge, and 1-tap incident alerts.',
        route: '/login',
      ),
      _RoleInfo(
        title: 'Statutory Observers',
        subtitle: 'Independent NTA & University Compliance Auditors',
        icon: Icons.visibility_rounded,
        accentColor: const Color(0xFFEAB308),
        desc: 'Read-only compliance console with full access to center readiness inspection checklists, CCTV streams, unseal witness logs, and Form B script reconciliation verification.',
        route: '/login',
      ),
      _RoleInfo(
        title: 'Finance & Accounts',
        subtitle: 'Bursar & Payroll Disbursement Officers',
        icon: Icons.payments_rounded,
        accentColor: const Color(0xFF10B981),
        desc: 'Automated remuneration engine calculating shift allowances, travel allowance (TA/DA) per km, bank IFSC validation, and batch Excel (.xlsx) / PDF pay statement exports.',
        route: '/login',
      ),
      _RoleInfo(
        title: 'Students & Parents',
        subtitle: 'Public Examination Information Portal',
        icon: Icons.school_rounded,
        accentColor: const Color(0xFF6366F1),
        desc: 'Publicly accessible candidate portal allowing students and parents to look up exam timetables, room assignments, seat numbers, and examination hall code of conduct.',
        route: '/portal',
      ),
    ];

    final currentRole = roles[_selectedRoleTab];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: brandColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'TAILORED FOR EVERY STAKEHOLDER',
                  style: TextStyle(color: brandColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Dedicated Portals for Every Examination Role',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // Role Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: List.generate(roles.length, (idx) {
                    final r = roles[idx];
                    final isSelected = _selectedRoleTab == idx;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        selected: isSelected,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(r.icon, size: 16, color: isSelected ? Colors.white : r.accentColor),
                            const SizedBox(width: 8),
                            Text(r.title),
                          ],
                        ),
                        selectedColor: r.accentColor,
                        backgroundColor: cardBg,
                        side: BorderSide(
                          color: isSelected ? r.accentColor : cardBorder,
                          width: 1,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedRoleTab = idx);
                        },
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),

              // Selected Role Showcase Box
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: currentRole.accentColor.withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: currentRole.accentColor.withValues(alpha: 0.1),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: currentRole.accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(currentRole.icon, color: currentRole.accentColor, size: 32),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                currentRole.title,
                                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '•  ${currentRole.subtitle}',
                                style: TextStyle(fontSize: 12, color: textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentRole.desc,
                            style: TextStyle(fontSize: 13.5, color: textSecondary, height: 1.5),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                            label: Text(
                              currentRole.route == '/portal' ? 'Open Student Portal' : 'Access ${currentRole.title} Console',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: currentRole.accentColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              if (currentRole.route == '/portal') {
                                context.push('/portal');
                              } else {
                                context.go('/login');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 7. OPERATIONS WORKFLOW (TIMELINE)
  // =========================================================================
  Widget _buildWorkflowSection(
    BuildContext context, {
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardBg,
    required Color cardBorder,
    required Color brandColor,
  }) {
    final steps = [
      _StepInfo('1', 'Automated Roster & Schedule', 'Fair algorithm matches invigilators based on department, shift preferences, and historical allocations without clashes.'),
      _StepInfo('2', 'SMS & WhatsApp Broadcasts', 'Instant automated duty notices with 2-way interactive acceptance, decline, or peer swap requests.'),
      _StepInfo('3', 'GPS & Biometric Gate Clock-In', 'Staff arrives within 200m geofence, verifies camera liveness mesh, and presents dynamic QR pass to guard.'),
      _StepInfo('4', 'Time-Locked Paper Unsealing', 'Vault release barcode scan, transit tracking, and unsealing locked until exact window with 2 student witnesses.'),
      _StepInfo('5', 'CCTV & BLE Room Monitoring', 'Central Control Room monitors in-hall presence, IP camera streams, and responds to real-time incident tickets.'),
      _StepInfo('6', 'Form B Reconciliation & Payroll', 'Mathematical script audit, absentee verification, wax sealing, and automated TA/DA salary settlement.'),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: brandColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'EXAMINATION OPERATIONS LIFECYCLE',
                  style: TextStyle(color: brandColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Six Standardized Phases of Examination Security',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              const SizedBox(height: 36),

              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 900;
                  final stepWidth = isDesktop ? (constraints.maxWidth - 40) / 3 : constraints.maxWidth;

                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: steps.map((s) {
                      return Container(
                        width: stepWidth,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorder, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: brandColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  s.number,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(s.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 6),
                            Text(s.desc, style: TextStyle(fontSize: 12, color: textSecondary, height: 1.45)),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 8. FAQ SECTION
  // =========================================================================
  Widget _buildFaqSection(
    BuildContext context, {
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardBg,
    required Color cardBorder,
    required Color brandColor,
  }) {
    final faqs = [
      _FaqItem(
        'How does DutyDesk prevent proxy attendance during exam duty?',
        'DutyDesk enforces a three-tier biometric and hardware-bound verification: 1) High-precision GPS geodesic geofencing checks that the device is physically within the authorized examination center boundary; 2) Front-facing camera biometric face verification with anti-spoofing and liveness check ensures the registered faculty member is present; 3) Optional Bluetooth Low Energy (BLE) room beacons authenticate uninterrupted hall presence.',
      ),
      _FaqItem(
        'What happens if an invigilator does not report for duty?',
        'The automated Standby Promotion Engine actively monitors reporting deadlines. If an assigned faculty member has not clocked in within the configured grace period (e.g., 20 minutes before start), the system flags the vacancy, dispatches an emergency standby replacement from the verified pool, and alerts the Center Superintendent and Control Room.',
      ),
      _FaqItem(
        'How does Time-Locked question paper unsealing work?',
        'Question paper packets are registered with encrypted barcodes in the central vault. Custodians log transit checkout. When packets reach the hall, the unsealing console remains locked until the predetermined schedule (e.g., 30 minutes before exam). Unsealing requires digital identity capture of 2 random student witnesses, preventing early leaks.',
      ),
      _FaqItem(
        'Can DutyDesk operate offline in low-connectivity examination centers?',
        'Yes. DutyDesk includes an Offline Sync Engine with a local SQLite queue. Invigilators can clock in, register student attendance, and record gate passes offline. Once campus Wi-Fi or cellular connectivity is restored, all timestamped cryptographic tokens synchronize seamlessly with Google Cloud Firestore.',
      ),
      _FaqItem(
        'How are faculty remuneration and Travel Allowances (TA/DA) processed?',
        'DutyDesk automatically logs completed shifts and multiplies them by the institutional rate rules (e.g., Morning Shift, Evening Shift, Center Superintendent surcharge). For external centers, it calculates distance-based travel allowances. Finance officers can review, approve, and export one-click Excel (.xlsx) bank batch payroll statements.',
      ),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: brandColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'QUESTIONS & ANSWERS',
                  style: TextStyle(color: brandColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Frequently Asked Questions',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              const SizedBox(height: 32),

              Column(
                children: List.generate(faqs.length, (idx) {
                  final faq = faqs[idx];
                  final isExpanded = _expandedFaqIndices.contains(idx);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isExpanded ? brandColor.withValues(alpha: 0.5) : cardBorder,
                        width: 1.2,
                      ),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: isExpanded,
                        onExpansionChanged: (expanded) {
                          setState(() {
                            if (expanded) {
                              _expandedFaqIndices.add(idx);
                            } else {
                              _expandedFaqIndices.remove(idx);
                            }
                          });
                        },
                        title: Text(
                          faq.question,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Text(
                              faq.answer,
                              style: TextStyle(
                                fontSize: 13,
                                color: textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 9. FINAL CALL TO ACTION (CTA)
  // =========================================================================
  Widget _buildFinalCtaSection(
    BuildContext context, {
    required bool isDark,
    required Color brandColor,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF007A87), Color(0xFF004D56)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF007A87).withValues(alpha: 0.35),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.verified_outlined, color: Colors.white, size: 44),
                const SizedBox(height: 16),
                Text(
                  'Modernize & Secure Your Examination Operations',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: const Text(
                    'Join state testing agencies, universities, and colleges standardizing their invigilation integrity on DutyDesk.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.white70, height: 1.5),
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  icon: const Icon(Icons.login_rounded, size: 20),
                  label: const Text('Access Central Login Portal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF007A87),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                  ),
                  onPressed: () {
                    context.go('/login');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 10. FOOTER
  // =========================================================================
  Widget _buildFooter(
    BuildContext context, {
    required bool isDark,
    required Color textSecondary,
    required Color cardBorder,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF060910) : const Color(0xFFF1F5F9),
        border: Border(top: BorderSide(color: cardBorder, width: 1)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007A87),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.shield_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'DutyDesk Examination Commission',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.circle, color: Color(0xFF10B981), size: 10),
                      const SizedBox(width: 6),
                      Text(
                        'All Systems Operational By EnviroWatch.Services (2026 )',
                        style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '© 2026 DutyDesk Technologies. All rights reserved. Strict Examination Governance Standard.',
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Portal Sign In →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DATA MODELS
// ---------------------------------------------------------------------------
class _FeatureItem {
  final IconData icon;
  final String title;
  final String tag;
  final Color color;
  final List<String> bullets;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.tag,
    required this.color,
    required this.bullets,
  });
}

class _RoleInfo {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String desc;
  final String route;

  const _RoleInfo({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.desc,
    required this.route,
  });
}

class _StepInfo {
  final String number;
  final String title;
  final String desc;

  const _StepInfo(this.number, this.title, this.desc);
}

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem(this.question, this.answer);
}
