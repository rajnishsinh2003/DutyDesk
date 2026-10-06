import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/answer_sheet_bundle_model.dart';
import '../providers/answer_sheet_provider.dart';
import '../services/answer_sheet_pdf_service.dart';
import 'bundle_reconciliation_dialog.dart';
import 'bundle_handover_dialog.dart';

class AnswerSheetCollectionScreen extends ConsumerStatefulWidget {
  const AnswerSheetCollectionScreen({super.key});

  @override
  ConsumerState<AnswerSheetCollectionScreen> createState() => _AnswerSheetCollectionScreenState();
}

class _AnswerSheetCollectionScreenState extends ConsumerState<AnswerSheetCollectionScreen> {
  String _selectedFilter = 'all';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bundles = ref.watch(answerSheetProvider);

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    // Filter
    final filtered = bundles.where((b) {
      if (_selectedFilter != 'all') {
        if (_selectedFilter == 'draft' && b.status != BundleStatus.draft) return false;
        if (_selectedFilter == 'sealed' && b.status != BundleStatus.reconciledAndSealed) return false;
        if (_selectedFilter == 'control' && b.status != BundleStatus.handedToSuperintendent) return false;
        if (_selectedFilter == 'dispatched' && b.status != BundleStatus.dispatchedToEvaluation) return false;
        if (_selectedFilter == 'mismatch' && b.status != BundleStatus.countMismatch) return false;
      }

      final q = _searchCtrl.text.trim().toLowerCase();
      if (q.isNotEmpty) {
        final matchCode = b.bundleCode.toLowerCase().contains(q);
        final matchSeal = b.securitySealNumber.toLowerCase().contains(q);
        final matchSub = b.subjectName.toLowerCase().contains(q) || b.subjectCode.toLowerCase().contains(q);
        final matchRoom = b.roomName.toLowerCase().contains(q);
        return matchCode || matchSeal || matchSub || matchRoom;
      }
      return true;
    }).toList();

    // Aggregates
    final totalBundles = bundles.length;
    final totalRegistered = bundles.fold<int>(0, (sum, b) => sum + b.registeredCandidates);
    final totalCollected = bundles.fold<int>(0, (sum, b) => sum + b.collectedScriptCount);
    final totalAbsent = bundles.fold<int>(0, (sum, b) => sum + b.absentCount);
    final totalMismatches = bundles.where((b) => b.status == BundleStatus.countMismatch).length;
    final totalDispatched = bundles.where((b) => b.status == BundleStatus.dispatchedToEvaluation).length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Answer Sheet Collection Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // KPI Metric Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _KpiPill(label: 'Allotted', count: '$totalRegistered', color: const Color(0xFF2563EB)),
                const SizedBox(width: 8),
                _KpiPill(label: 'Collected', count: '$totalCollected', color: const Color(0xFF10B981)),
                const SizedBox(width: 8),
                _KpiPill(label: 'Absentees', count: '$totalAbsent', color: const Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                _KpiPill(label: 'Bundles', count: '$totalBundles', color: const Color(0xFF8B5CF6)),
                const SizedBox(width: 8),
                _KpiPill(label: 'Dispatched', count: '$totalDispatched', color: const Color(0xFF0D9488)),
                const SizedBox(width: 8),
                _KpiPill(label: 'Gaps', count: '$totalMismatches', color: const Color(0xFFEF4444)),
              ],
            ),
          ),

          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by bundle code, seal #, subject, room...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: cardBg,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 8),

          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _filterChip('all', 'All Bundles ($totalBundles)'),
                _filterChip('draft', 'In Exam Hall'),
                _filterChip('sealed', 'Sealed'),
                _filterChip('control', 'In Control Room'),
                _filterChip('dispatched', 'Dispatched ($totalDispatched)'),
                _filterChip('mismatch', 'Count Mismatches ($totalMismatches)'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Bundles List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 56, color: isDark ? Colors.white24 : Colors.black26),
                        const SizedBox(height: 12),
                        const Text('No answer sheet bundles found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text('Try adjusting the search query or status filter.', style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 14),
                    itemBuilder: (context, idx) {
                      final bundle = filtered[idx];
                      return _buildBundleCard(bundle, isDark, cardBg);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String filterId, String label) {
    final isSelected = _selectedFilter == filterId;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: const Color(0xFF2563EB),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey,
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (sel) {
          if (sel) setState(() => _selectedFilter = filterId);
        },
      ),
    );
  }

  Widget _buildBundleCard(AnswerSheetBundle b, bool isDark, Color cardBg) {
    final timeFormat = DateFormat('hh:mm a');

    final statusColor = switch (b.status) {
      BundleStatus.draft => const Color(0xFF3B82F6),
      BundleStatus.reconciledAndSealed => const Color(0xFF10B981),
      BundleStatus.handedToSuperintendent => const Color(0xFF8B5CF6),
      BundleStatus.dispatchedToEvaluation => const Color(0xFF0D9488),
      BundleStatus.countMismatch => const Color(0xFFEF4444),
    };

    final statusText = switch (b.status) {
      BundleStatus.draft => 'COLLECTION IN PROGRESS',
      BundleStatus.reconciledAndSealed => 'SEALED & BALANCED',
      BundleStatus.handedToSuperintendent => 'IN CONTROL ROOM',
      BundleStatus.dispatchedToEvaluation => 'DISPATCHED TO EVALUATION',
      BundleStatus.countMismatch => '🚨 COUNT MISMATCH',
    };

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: b.status == BundleStatus.countMismatch
              ? const Color(0xFFEF4444)
              : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
          width: b.status == BundleStatus.countMismatch ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            b.bundleCode,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${b.collectedScriptCount} Scripts',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${b.subjectCode} — ${b.subjectName}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Room & Seal Info Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            child: Row(
              children: [
                const Icon(Icons.qr_code_2_rounded, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  b.securitySealNumber,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                const Spacer(),
                const Icon(Icons.meeting_room_outlined, size: 15, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${b.roomName} • ${b.shift}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Reconciliation Numbers Breakdown
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NumberItem(label: 'Allotted', value: '${b.registeredCandidates}', color: Colors.blueGrey),
                  _NumberItem(label: 'Present', value: '${b.presentCount}', color: const Color(0xFF2563EB)),
                  _NumberItem(label: 'Absent', value: '${b.absentCount}', color: const Color(0xFFF59E0B)),
                  _NumberItem(label: 'Collected', value: '${b.collectedScriptCount}', color: const Color(0xFF10B981)),
                  _NumberItem(label: 'Returned Blank', value: '${b.unusedBlankSheetsReturned}', color: Colors.grey),
                ],
              ),
            ),
          ),

          // Absentee Roll Numbers
          if (b.absentRollNumbers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Text('Absentees: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                  Expanded(
                    child: Text(
                      b.absentRollNumbers.join(', '),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

          // Courier consignment tracking
          if (b.courierConsignmentNumber != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_shipping_outlined, size: 16, color: Color(0xFF0D9488)),
                    const SizedBox(width: 8),
                    Text(
                      'Dispatch Tracking: ${b.courierConsignmentNumber}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                    ),
                  ],
                ),
              ),
            ),

          // Custody Log Expander
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              dense: true,
              title: Text(
                'Chain of Custody (${b.custodyLog.length} events logged)',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    children: b.custodyLog.map((event) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 4, right: 10),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        event.stage,
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        timeFormat.format(event.timestamp),
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${event.actorName} (${event.actorRole})',
                                    style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white60 : Colors.black54),
                                  ),
                                  if (event.notes != null)
                                    Text(
                                      'Note: ${event.notes}',
                                      style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: isDark ? Colors.white38 : Colors.black45),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Actions Row
          Container(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
              ),
            ),
            child: Row(
              children: [
                // Print Form B Docket Slip
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF2563EB), size: 20),
                  tooltip: 'Print Form B Docket Slip',
                  onPressed: () => AnswerSheetPdfService.printBundleDocket(b),
                ),
                const Spacer(),

                if (b.status == BundleStatus.draft || b.status == BundleStatus.countMismatch)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.lock_rounded, size: 16),
                    label: const Text('Reconcile & Seal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => BundleReconciliationDialog.show(context, b),
                  )
                else if (b.status == BundleStatus.reconciledAndSealed)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.assignment_turned_in_rounded, size: 16),
                    label: const Text('Control Room Handover'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => BundleHandoverDialog.show(
                      context,
                      bundle: b,
                      handoverType: BundleHandoverType.superintendentReceive,
                    ),
                  )
                else if (b.status == BundleStatus.handedToSuperintendent)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.local_shipping_rounded, size: 16),
                    label: const Text('Dispatch to Evaluation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => BundleHandoverDialog.show(
                      context,
                      bundle: b,
                      handoverType: BundleHandoverType.evaluationDispatch,
                    ),
                  )
                else if (b.status == BundleStatus.dispatchedToEvaluation)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF0D9488)),
                    label: const Text('Dispatched', style: TextStyle(color: Color(0xFF0D9488))),
                    onPressed: null,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _NumberItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _KpiPill extends StatelessWidget {
  final String label;
  final String count;
  final Color color;

  const _KpiPill({
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
          color: color.withValues(alpha: 0.1),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
