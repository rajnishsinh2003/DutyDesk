import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:duty_desk/l10n/app_localizations.dart';
import '../providers/daily_record_provider.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  int _extractPayment(String paymentStr) {
    try {
      final cleanStr = paymentStr.replaceAll(RegExp(r'[^0-9]'), '');
      return int.parse(cleanStr);
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final dailyState = ref.watch(dailyRecordProvider);
    final guards = dailyState.guardRecords;
    final staffs = dailyState.examStaffRecords;
    final jammers = dailyState.jammerRecords;

    // Aggregate records matching the query
    final lowerQuery = _query.toLowerCase();

    List<dynamic> allMatchingRecords = [];
    int totalPayment = 0;
    int esCount = 0;
    int securityCount = 0;
    int jammerCount = 0;
    final Set<String> centersWorked = {};
    final Set<String> personNamesFound = {};

    if (lowerQuery.isNotEmpty) {
      for (var guard in guards) {
        if (guard.name.toLowerCase().contains(lowerQuery) || 
            guard.center.toLowerCase().contains(lowerQuery) || 
            guard.duty.toLowerCase().contains(lowerQuery)) {
          allMatchingRecords.add(guard);
          totalPayment += _extractPayment(guard.payment);
          securityCount++;
          centersWorked.add(guard.center);
          personNamesFound.add(guard.name);
        }
      }
      for (var staff in staffs) {
        if (staff.esName.toLowerCase().contains(lowerQuery) || 
            staff.centerName.toLowerCase().contains(lowerQuery) || 
            staff.examName.toLowerCase().contains(lowerQuery) || 
            staff.duty.toLowerCase().contains(lowerQuery)) {
          allMatchingRecords.add(staff);
          totalPayment += _extractPayment(staff.payment);
          esCount++;
          centersWorked.add(staff.centerName);
          personNamesFound.add(staff.esName);
        }
      }
      for (var jammer in jammers) {
        if (jammer.name.toLowerCase().contains(lowerQuery) || 
            jammer.center.toLowerCase().contains(lowerQuery) || 
            jammer.examName.toLowerCase().contains(lowerQuery) || 
            jammer.duty.toLowerCase().contains(lowerQuery)) {
          allMatchingRecords.add(jammer);
          totalPayment += _extractPayment(jammer.payment);
          jammerCount++;
          centersWorked.add(jammer.center);
          personNamesFound.add(jammer.name);
        }
      }

      allMatchingRecords = allMatchingRecords.reversed.toList();
    }

    final totalDuties = esCount + securityCount + jammerCount;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.go('/admin_dashboard'),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '${s.search}...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            border: InputBorder.none,
          ),
          onChanged: (val) => setState(() => _query = val.trim()),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Gradient
          Positioned(
            top: 0,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
              ),
            ),
          ),
          SafeArea(
            child: _query.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_rounded, size: 64, color: Colors.white.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        Text(s.typeToSearch, style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                      ],
                    ),
                  )
                : allMatchingRecords.isEmpty
                    ? Center(child: Text(s.noResultsFound, style: const TextStyle(color: Colors.white)))
                    : CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          personNamesFound.length == 1 ? personNamesFound.first : '${s.search}: "$_query"',
                                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            _buildStat(s.totalDuties, totalDuties.toString(), Colors.blue),
                                            _buildStat(s.totalRemuneration, '₹$totalPayment', Colors.green),
                                            _buildStat(s.centers, centersWorked.length.toString(), Colors.purple),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        const Divider(color: Colors.white24),
                                        const SizedBox(height: 8),
                                        Text('${s.esNames}: $esCount   •   ${s.securityGuardNames}: $securityCount   •   ${s.jammerNames}: $jammerCount', 
                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600)
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              child: Text(s.searchResults, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final record = allMatchingRecords[index];
                                  String typeLabel = '';
                                  String name = '';
                                  String center = '';
                                  String exam = '';
                                  String shift = '';
                                  String payment = '';
                                  String date = '';

                                  if (record is ExamStaffRecord) {
                                    typeLabel = s.esNames;
                                    name = record.esName;
                                    center = record.centerName;
                                    exam = record.examName;
                                    shift = record.totalShifts;
                                    payment = record.payment;
                                    date = record.date;
                                  } else if (record is SecurityGuardRecord) {
                                    typeLabel = s.securityGuardNames;
                                    name = record.name;
                                    center = record.center;
                                    exam = record.duty;
                                    shift = record.totalShifts;
                                    payment = record.payment;
                                    date = record.date;
                                  } else if (record is JammerRecord) {
                                    typeLabel = s.jammerNames;
                                    name = record.name;
                                    center = record.center;
                                    exam = record.examName;
                                    shift = record.totalShifts;
                                    payment = record.payment;
                                    date = record.date;
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.03),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(typeLabel, style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text('${s.date}: $date   |   ${s.shift}: $shift', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                                        const SizedBox(height: 4),
                                        Text('${s.center}: $center', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                                        const SizedBox(height: 4),
                                        Text('${s.exams}: $exam', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                                        const SizedBox(height: 8),
                                        Text('${s.remuneration}: $payment', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                                      ],
                                    ),
                                  );
                                },
                                childCount: allMatchingRecords.length,
                              ),
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

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
      ],
    );
  }
}
