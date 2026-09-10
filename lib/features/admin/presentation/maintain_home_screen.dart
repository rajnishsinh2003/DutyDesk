import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:duty_desk/l10n/app_localizations.dart';
import '../providers/master_data_provider.dart';
import 'maintain_module_list_screen.dart';

class MaintainHomeScreen extends ConsumerStatefulWidget {
  const MaintainHomeScreen({super.key});

  @override
  ConsumerState<MaintainHomeScreen> createState() => _MaintainHomeScreenState();
}

class _MaintainHomeScreenState extends ConsumerState<MaintainHomeScreen> {
  String _searchQuery = '';

  List<Map<String, dynamic>> _getModules(S s) {
    return [
      {'type': 'centers', 'title': s.centers, 'icon': Icons.business_rounded, 'color': const Color(0xFF3B82F6)},
      {'type': 'es_names', 'title': s.esNames, 'icon': Icons.badge_rounded, 'color': const Color(0xFF10B981)},
      {'type': 'exam_names', 'title': s.examNames, 'icon': Icons.assignment_rounded, 'color': const Color(0xFF8B5CF6)},
      {'type': 'security_guards', 'title': s.securityGuardNames, 'icon': Icons.security_rounded, 'color': const Color(0xFFF59E0B)},
      {'type': 'jammers', 'title': s.jammerNames, 'icon': Icons.router_rounded, 'color': const Color(0xFFEF4444)},
      {'type': 'users', 'title': s.users, 'icon': Icons.people_alt_rounded, 'color': const Color(0xFF06B6D4)},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final masterDataState = ref.watch(masterDataProvider);
    final modules = _getModules(s);

    final filteredModules = modules.where((m) {
      return m['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark Theme
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.go('/admin_dashboard'),
        ),
        title: Text(s.masterDataManagement, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background subtle gradients for glassmorphism effect
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.selectModuleDescription,
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                        // Separate Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: TextField(
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: s.searchModules,
                              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                              prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.6)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            onChanged: (val) => setState(() => _searchQuery = val),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  sliver: masterDataState.when(
                    loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                    error: (e, _) => SliverToBoxAdapter(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
                    data: (data) {
                      return SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.9,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final module = filteredModules[index];
                            final type = module['type'] as String;
                            final recordCount = data[type]?.length ?? 0;

                            return _GlassModuleCard(
                              title: module['title'] as String,
                              icon: module['icon'] as IconData,
                              color: module['color'] as Color,
                              count: recordCount,
                              countLabel: s.records(recordCount),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MaintainModuleListScreen(
                                      type: type,
                                      title: module['title'] as String,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          childCount: filteredModules.length,
                        ),
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassModuleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int count;
  final String countLabel;
  final VoidCallback onTap;

  const _GlassModuleCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.count,
    required this.countLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        countLabel,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
