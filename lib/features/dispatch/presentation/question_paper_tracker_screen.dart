import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/question_paper_packet_model.dart';
import '../providers/question_paper_provider.dart';
import 'packet_unseal_dialog.dart';
import 'packet_handover_dialog.dart';
import 'packet_tamper_dialog.dart';

class QuestionPaperTrackerScreen extends ConsumerStatefulWidget {
  const QuestionPaperTrackerScreen({super.key});

  @override
  ConsumerState<QuestionPaperTrackerScreen> createState() => _QuestionPaperTrackerScreenState();
}

class _QuestionPaperTrackerScreenState extends ConsumerState<QuestionPaperTrackerScreen> {
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
    final packets = ref.watch(questionPaperProvider);

    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    // Filter packets
    final filtered = packets.where((p) {
      if (_selectedFilter != 'all') {
        if (_selectedFilter == 'vault' && p.status != PacketStatus.inStrongroom) return false;
        if (_selectedFilter == 'transit' && p.status != PacketStatus.dispatchedFromStrongroom) return false;
        if (_selectedFilter == 'hall' && (p.status != PacketStatus.receivedByInvigilator && p.status != PacketStatus.sealVerified)) return false;
        if (_selectedFilter == 'opened' && p.status != PacketStatus.opened) return false;
        if (_selectedFilter == 'alert' && p.status != PacketStatus.tampered) return false;
      }

      final query = _searchCtrl.text.trim().toLowerCase();
      if (query.isNotEmpty) {
        final matchCode = p.packetCode.toLowerCase().contains(query);
        final matchSeal = p.securitySealNumber.toLowerCase().contains(query);
        final matchSub = p.subjectName.toLowerCase().contains(query) || p.subjectCode.toLowerCase().contains(query);
        final matchRoom = p.roomName.toLowerCase().contains(query);
        return matchCode || matchSeal || matchSub || matchRoom;
      }
      return true;
    }).toList();

    // Metrics
    final total = packets.length;
    final inVault = packets.where((p) => p.status == PacketStatus.inStrongroom).length;
    final inTransit = packets.where((p) => p.status == PacketStatus.dispatchedFromStrongroom).length;
    final inHall = packets.where((p) => p.status == PacketStatus.receivedByInvigilator || p.status == PacketStatus.sealVerified).length;
    final opened = packets.where((p) => p.status == PacketStatus.opened).length;
    final alerts = packets.where((p) => p.status == PacketStatus.tampered).length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Question Paper Dispatch Tracker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                _KpiPill(label: 'Total', count: '$total', color: const Color(0xFF2563EB)),
                const SizedBox(width: 8),
                _KpiPill(label: 'In Vault', count: '$inVault', color: const Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                _KpiPill(label: 'In Transit', count: '$inTransit', color: const Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                _KpiPill(label: 'In Hall', count: '$inHall', color: const Color(0xFF8B5CF6)),
                const SizedBox(width: 8),
                _KpiPill(label: 'Unsealed', count: '$opened', color: const Color(0xFF10B981)),
                const SizedBox(width: 8),
                _KpiPill(label: 'Alerts', count: '$alerts', color: const Color(0xFFEF4444)),
              ],
            ),
          ),

          // Search & Filter Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search by packet, seal barcode, room...',
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
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _filterChip('all', 'All Packets ($total)'),
                _filterChip('vault', 'In Vault ($inVault)'),
                _filterChip('transit', 'In Transit ($inTransit)'),
                _filterChip('hall', 'In Exam Hall ($inHall)'),
                _filterChip('opened', 'Unsealed ($opened)'),
                _filterChip('alert', 'Breach / Tamper ($alerts)'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Packet Cards List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 56, color: isDark ? Colors.white24 : Colors.black26),
                        const SizedBox(height: 12),
                        const Text('No question paper packets found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text('Try resetting the search query or status filter.', style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 14),
                    itemBuilder: (context, idx) {
                      final packet = filtered[idx];
                      return _buildPacketCard(packet, isDark, cardBg, textColor);
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

  Widget _buildPacketCard(QuestionPaperPacket p, bool isDark, Color cardBg, Color textColor) {
    final timeFormat = DateFormat('hh:mm a');
    final now = DateTime.now();

    final statusColor = switch (p.status) {
      PacketStatus.inStrongroom => const Color(0xFF3B82F6),
      PacketStatus.dispatchedFromStrongroom => const Color(0xFFF59E0B),
      PacketStatus.receivedByInvigilator => const Color(0xFF8B5CF6),
      PacketStatus.sealVerified => const Color(0xFF0891B2),
      PacketStatus.opened => const Color(0xFF10B981),
      PacketStatus.tampered => const Color(0xFFEF4444),
    };

    final statusText = switch (p.status) {
      PacketStatus.inStrongroom => 'VAULT LOCKED',
      PacketStatus.dispatchedFromStrongroom => 'IN TRANSIT',
      PacketStatus.receivedByInvigilator => 'WITH INVIGILATOR',
      PacketStatus.sealVerified => 'SEAL VERIFIED',
      PacketStatus.opened => 'UNSEALED & ACTIVE',
      PacketStatus.tampered => '🚨 BREACH / TAMPERED',
    };

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: p.status == PacketStatus.tampered
              ? const Color(0xFFEF4444)
              : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
          width: p.status == PacketStatus.tampered ? 2 : 1,
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
          // Top Bar
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
                            p.packetCode,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${p.bookletCount} Papers',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${p.subjectCode} — ${p.subjectName}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
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

          // Security Bar (Seal barcode & Hall Destination)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            child: Row(
              children: [
                const Icon(Icons.qr_code_2_rounded, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  p.securitySealNumber,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                const Spacer(),
                const Icon(Icons.meeting_room_outlined, size: 15, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${p.roomName} • ${p.shift}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Time-Lock Window Info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Row(
              children: [
                Icon(
                  p.isWithinUnsealWindow ? Icons.lock_clock : Icons.timer_outlined,
                  size: 16,
                  color: p.isWithinUnsealWindow ? const Color(0xFF10B981) : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  'Unseal Window: ${timeFormat.format(p.unlockWindowStart)} - ${timeFormat.format(p.unlockWindowEnd)}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: p.isWithinUnsealWindow ? const Color(0xFF10B981) : (isDark ? Colors.white60 : Colors.black54),
                    fontWeight: p.isWithinUnsealWindow ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (p.isTimeLocked) ...[
                  const Spacer(),
                  Text(
                    '🔒 Locked (${p.unlockWindowStart.difference(now).inMinutes}m left)',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                  ),
                ],
              ],
            ),
          ),

          // Witnesses (if opened)
          if (p.witnesses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 16, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Student Witnesses: ${p.witnesses.map((w) => "${w.name} (${w.rollNumber})").join(", ")}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Tamper remarks (if breached)
          if (p.status == PacketStatus.tampered && p.tamperRemarks != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.report_problem, size: 16, color: Color(0xFFEF4444)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'BREACH NOTES: ${p.tamperRemarks}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                      ),
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
                'Chain of Custody (${p.custodyLog.length} events logged)',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    children: p.custodyLog.map((event) {
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
                                color: Color(0xFF2563EB),
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

          // Action Buttons Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
              ),
            ),
            child: Row(
              children: [
                if (p.status != PacketStatus.tampered && p.status != PacketStatus.opened)
                  IconButton(
                    icon: const Icon(Icons.report_gmailerrorred_rounded, color: Color(0xFFEF4444), size: 20),
                    tooltip: 'Report Seal Breach / Tamper',
                    onPressed: () => PacketTamperDialog.show(context, p),
                  ),
                const Spacer(),
                // Stage Action Button
                if (p.status == PacketStatus.inStrongroom)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.outbox_rounded, size: 16),
                    label: const Text('Dispatch from Vault'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => PacketHandoverDialog.show(
                      context,
                      packet: p,
                      handoverType: HandoverType.strongroomCheckout,
                    ),
                  )
                else if (p.status == PacketStatus.dispatchedFromStrongroom)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.move_to_inbox_rounded, size: 16),
                    label: const Text('Receive in Exam Hall'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => PacketHandoverDialog.show(
                      context,
                      packet: p,
                      handoverType: HandoverType.invigilatorReceive,
                    ),
                  )
                else if (p.status == PacketStatus.receivedByInvigilator)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.verified_rounded, size: 16),
                    label: const Text('Verify Seal Integrity'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0891B2),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      await ref.read(questionPaperProvider.notifier).verifySeal(
                        packetId: p.id,
                        verifierName: p.assignedInvigilatorName ?? 'Room Invigilator',
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🛡️ Seal verified for ${p.packetCode}! Ready for unsealing.'),
                            backgroundColor: const Color(0xFF0891B2),
                          ),
                        );
                      }
                    },
                  )
                else if (p.status == PacketStatus.sealVerified)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.lock_open_rounded, size: 16),
                    label: const Text('Unseal Packet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => PacketUnsealDialog.show(context, p),
                  )
                else if (p.status == PacketStatus.opened)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
                    label: const Text('Unsealed & Verified', style: TextStyle(color: Color(0xFF10B981))),
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
