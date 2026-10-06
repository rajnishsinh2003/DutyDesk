import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../models/seating_plan_model.dart';
import '../providers/seating_plan_provider.dart';
import '../services/seating_generator_engine.dart';
import 'seating_plan_editor_dialog.dart';

class SeatingPlanScreen extends ConsumerStatefulWidget {
  const SeatingPlanScreen({super.key});

  @override
  ConsumerState<SeatingPlanScreen> createState() => _SeatingPlanScreenState();
}

class _SeatingPlanScreenState extends ConsumerState<SeatingPlanScreen> {
  String? _selectedPlanId;
  StudentSeat? _selectedSeatForSwap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plans = ref.watch(seatingPlanProvider);

    if (plans.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Exam Seating Plans'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.grid_on_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No Seating Plans Created',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Generate an automated seating layout with anti-cheating rules.'),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Generate Seating Plan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => SeatingPlanEditorDialog.show(context),
              ),
            ],
          ),
        ),
      );
    }

    // Default to first plan if not selected or current selection deleted
    final activePlan = plans.firstWhere(
      (p) => p.id == _selectedPlanId,
      orElse: () => plans.first,
    );

    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Exam Seating Plans', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Print PDF Door Notice',
            onPressed: () => SeatingGeneratorEngine.printOrSharePdf(activePlan),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export CSV Roster',
            onPressed: () {
              final csvData = SeatingGeneratorEngine.exportToCsv(activePlan);
              SharePlus.instance.share(
                ShareParams(
                  text: csvData,
                  subject: 'Seating_Plan_${activePlan.roomName}.csv',
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'New Seating Plan',
            onPressed: () => SeatingPlanEditorDialog.show(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'edit') {
                SeatingPlanEditorDialog.show(context, existingPlan: activePlan);
              } else if (val == 'delete') {
                ref.read(seatingPlanProvider.notifier).deletePlan(activePlan.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Seating plan removed')),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit / Re-generate')),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete Plan', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Plan Selector Chips Bar
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: plans.length,
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final p = plans[idx];
                final isSelected = p.id == activePlan.id;
                return ChoiceChip(
                  label: Text('${p.roomName} (${p.allocatedCount}/${p.totalCapacity})'),
                  selected: isSelected,
                  selectedColor: const Color(0xFF2563EB),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (sel) {
                    if (sel) setState(() => _selectedPlanId = p.id);
                  },
                );
              },
            ),
          ),

          // Plan Details & Metrics Card
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activePlan.examName,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${activePlan.roomName} • ${activePlan.centerName}',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Date: ${activePlan.date} • ${activePlan.sessionOrShift}',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black45,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Strategy Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF10B981)),
                          const SizedBox(width: 4),
                          Text(
                            switch (activePlan.strategy) {
                              AntiCheatingStrategy.alternatingBranches => 'ALT BRANCHES',
                              AntiCheatingStrategy.checkerboard => 'CHECKERBOARD',
                              AntiCheatingStrategy.consecutiveRolls => 'SEQUENTIAL',
                            },
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Metrics Row
                Row(
                  children: [
                    _StatPill(
                      label: 'Capacity',
                      count: '${activePlan.totalCapacity}',
                      color: const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 8),
                    _StatPill(
                      label: 'Allocated',
                      count: '${activePlan.allocatedCount}',
                      color: const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 8),
                    _StatPill(
                      label: 'Vacant',
                      count: '${activePlan.vacantCount}',
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    _StatPill(
                      label: 'Buffer',
                      count: '${activePlan.bufferCount}',
                      color: const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 8),
                    _StatPill(
                      label: 'Blocked',
                      count: '${activePlan.blockedCount}',
                      color: const Color(0xFFEF4444),
                    ),
                  ],
                ),

                if (_selectedSeatForSwap != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.swap_horiz_rounded, color: Color(0xFFF59E0B), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Select second seat to SWAP with ${_selectedSeatForSwap!.deskLabel} (${_selectedSeatForSwap!.studentName ?? "Vacant"})',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _selectedSeatForSwap = null),
                          child: const Text('Cancel', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Hall Front / Blackboard indicator
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tv_rounded, size: 14, color: Colors.grey),
                  SizedBox(width: 6),
                  Text(
                    'INSPECTOR / BLACKBOARD FRONT',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),

          // 2D Scrollable Desk Grid
          Expanded(
            child: InteractiveViewer(
              constrained: false,
              boundaryMargin: const EdgeInsets.all(32),
              minScale: 0.6,
              maxScale: 2.0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    for (int r = 0; r < activePlan.rows; r++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (int c = 0; c < activePlan.columns; c++)
                              _buildDeskWidget(
                                seat: activePlan.seats.firstWhere(
                                  (s) => s.row == r && s.col == c,
                                  orElse: () => StudentSeat(row: r, col: c, deskLabel: 'R${r+1}-C${c+1}'),
                                ),
                                plan: activePlan,
                                isDark: isDark,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeskWidget({
    required StudentSeat seat,
    required SeatingPlan plan,
    required bool isDark,
  }) {
    final isSelectedForSwap = _selectedSeatForSwap?.row == seat.row && _selectedSeatForSwap?.col == seat.col;

    Color deskBorderColor = isDark ? Colors.white10 : Colors.black12;
    Color deskBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    Color accentColor = const Color(0xFF2563EB);

    if (seat.status == SeatStatus.buffer) {
      deskBorderColor = const Color(0xFFF59E0B);
      deskBgColor = const Color(0xFFF59E0B).withValues(alpha: 0.08);
      accentColor = const Color(0xFFF59E0B);
    } else if (seat.status == SeatStatus.vacant) {
      deskBorderColor = isDark ? Colors.white12 : Colors.grey.shade300;
      deskBgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
      accentColor = Colors.grey;
    } else if (seat.status == SeatStatus.blocked) {
      deskBorderColor = const Color(0xFFEF4444);
      deskBgColor = const Color(0xFFEF4444).withValues(alpha: 0.08);
      accentColor = const Color(0xFFEF4444);
    }

    if (isSelectedForSwap) {
      deskBorderColor = const Color(0xFFF59E0B);
      deskBgColor = const Color(0xFFF59E0B).withValues(alpha: 0.2);
    }

    // Branch Color Pill
    Color branchColor = const Color(0xFF2563EB);
    if (seat.branchOrSubject == 'ECE') branchColor = const Color(0xFF8B5CF6);
    if (seat.branchOrSubject == 'ME') branchColor = const Color(0xFFF97316);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        if (_selectedSeatForSwap != null) {
          // Perform Swap!
          ref.read(seatingPlanProvider.notifier).swapSeats(
            planId: plan.id,
            r1: _selectedSeatForSwap!.row,
            c1: _selectedSeatForSwap!.col,
            r2: seat.row,
            c2: seat.col,
          );
          setState(() => _selectedSeatForSwap = null);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Swapped ${seat.deskLabel} with ${_selectedSeatForSwap!.deskLabel}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        } else {
          _showSeatInspectorModal(seat, plan);
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 110,
        height: 80,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: deskBgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: deskBorderColor,
            width: isSelectedForSwap ? 2.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Desk Label + Status Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  seat.deskLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                if (seat.status == SeatStatus.allocated && seat.branchOrSubject != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: branchColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      seat.branchOrSubject!,
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        color: branchColor,
                      ),
                    ),
                  )
                else
                  Text(
                    seat.status.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
              ],
            ),

            // Middle: Roll Number & Name
            if (seat.status == SeatStatus.allocated && seat.studentRoll != null) ...[
              Text(
                seat.studentRoll!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                seat.studentName ?? '',
                style: TextStyle(
                  fontSize: 9.5,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ] else ...[
              Center(
                child: Icon(
                  seat.status == SeatStatus.buffer
                      ? Icons.bookmark_added_outlined
                      : (seat.status == SeatStatus.blocked ? Icons.block : Icons.event_seat_outlined),
                  size: 20,
                  color: accentColor.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 2),
            ],
          ],
        ),
      ),
    );
  }

  void _showSeatInspectorModal(StudentSeat seat, SeatingPlan plan) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.chair_rounded, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Desk ${seat.deskLabel}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Row ${seat.row + 1}, Column ${seat.col + 1} • Status: ${seat.status.name.toUpperCase()}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              if (seat.status == SeatStatus.allocated) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    child: Icon(Icons.person, size: 20),
                  ),
                  title: Text(seat.studentName ?? 'Student Candidate', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Roll: ${seat.studentRoll} • Branch: ${seat.branchOrSubject}'),
                ),
                const Divider(),
              ],

              // Seat actions
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.swap_horiz, size: 16),
                    label: const Text('Swap with Seat'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() => _selectedSeatForSwap = seat);
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.bookmark_border, size: 16),
                    label: Text(seat.status == SeatStatus.buffer ? 'Remove Buffer' : 'Tag as Buffer'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      final updated = seat.copyWith(
                        status: seat.status == SeatStatus.buffer ? SeatStatus.vacant : SeatStatus.buffer,
                        studentRoll: null,
                        studentName: null,
                      );
                      ref.read(seatingPlanProvider.notifier).updateSeat(plan.id, updated);
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.block, size: 16),
                    label: Text(seat.status == SeatStatus.blocked ? 'Unblock Desk' : 'Block Desk'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      final updated = seat.copyWith(
                        status: seat.status == SeatStatus.blocked ? SeatStatus.vacant : SeatStatus.blocked,
                        studentRoll: null,
                        studentName: null,
                      );
                      ref.read(seatingPlanProvider.notifier).updateSeat(plan.id, updated);
                    },
                  ),
                  if (seat.status != SeatStatus.vacant)
                    ActionChip(
                      avatar: const Icon(Icons.person_remove_outlined, size: 16),
                      label: const Text('Mark Vacant'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        final updated = seat.copyWith(
                          status: SeatStatus.vacant,
                          studentRoll: null,
                          studentName: null,
                          branchOrSubject: null,
                        );
                        ref.read(seatingPlanProvider.notifier).updateSeat(plan.id, updated);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String count;
  final Color color;

  const _StatPill({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
