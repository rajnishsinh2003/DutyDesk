import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:duty_desk/l10n/app_localizations.dart';
import '../../invigilator/providers/duty_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../providers/center_provider.dart';
import '../providers/invigilator_provider.dart';
import '../providers/duty_settings_provider.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/smtp_email_service.dart';
import '../../../core/services/sms_gateway_service.dart';

class LiveControlRoomScreen extends ConsumerStatefulWidget {
  const LiveControlRoomScreen({super.key});

  @override
  ConsumerState<LiveControlRoomScreen> createState() => _LiveControlRoomScreenState();
}

class _LiveControlRoomScreenState extends ConsumerState<LiveControlRoomScreen> {
  String _selectedStatusFilter = 'all'; // 'all', 'reached', 'pending', 'late', 'absent', 'outside_geofence'
  String? _selectedCenterFilter;
  String? _selectedShiftFilter;
  String _searchQuery = '';
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid phone number available for this staff'), backgroundColor: Colors.orange),
        );
      }
      return;
    }
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open phone dialer: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showReassignModal(ExamDuty duty, List<Invigilator> activeInvs) {
    final s = S.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.emergencyReplacement,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF007A87)),
            ),
            const SizedBox(height: 8),
            Text(
              '${duty.examName} • ${duty.centerName}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: activeInvs.length,
                itemBuilder: (context, index) {
                  final inv = activeInvs[index];
                  if (inv.id == duty.invigilatorId) return const SizedBox.shrink();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(inv.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${s.resourceId}: ${inv.resourceId} • ${inv.mobile}'),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007A87), foregroundColor: Colors.white),
                        onPressed: () async {
                          await ref.read(dutyProvider.notifier).reassignDuty(duty.id, inv.id);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${s.dutySwapped} -> ${inv.name}!'), backgroundColor: Colors.green),
                            );
                          }
                        },
                        child: Text(s.assign),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMarkNoShowDialog(ExamDuty duty, Invigilator staff) {
    final reasonCtrl = TextEditingController(text: 'Absent past reporting window without intimation');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.person_off_rounded, color: Colors.purple),
            SizedBox(width: 8),
            Text('Mark as No-Show', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confirm marking ${staff.name} as NO-SHOW for:'),
            const SizedBox(height: 6),
            Text(
              '${duty.examName} • ${duty.centerName} (Shift ${duty.shift})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'No-Show Reason / Remarks',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              await ref.read(dutyProvider.notifier).markDutyNoShow(
                duty.id,
                reason: reasonCtrl.text.trim(),
              );
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('❌ Marked ${staff.name} as No-Show.'),
                    backgroundColor: Colors.purple.shade700,
                  ),
                );
              }
            },
            child: const Text('Confirm No-Show'),
          ),
        ],
      ),
    );
  }

  void _showDispatchStandbyModal(ExamDuty duty, List<Invigilator> allInvs) {
    final todayStr = DateFormat('yyyy-MM-dd').format(_now);
    final taggedStandbys = allInvs.where((i) => i.isStandby == true && (i.standbyForDate == null || i.standbyForDate == todayStr)).toList();
    final otherStaff = allInvs.where((i) => i.isStandby != true && i.id != duty.invigilatorId && i.isActive).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt, color: Colors.purple, size: 26),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dispatch Standby Replacement',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple),
                      ),
                      Text(
                        'For: ${duty.examName} • ${duty.centerName}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              taggedStandbys.isNotEmpty ? 'TODAY\'S STANDBY POOL (${taggedStandbys.length})' : 'AVAILABLE ACTIVE STAFF (${otherStaff.length})',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  if (taggedStandbys.isNotEmpty) ...[
                    ...taggedStandbys.map((inv) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.purple, width: 1),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.purple,
                              child: Icon(Icons.bolt, color: Colors.white, size: 18),
                            ),
                            title: Text(inv.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              'Resource ID: ${inv.resourceId} • ${inv.mobile}${inv.standbyForCenter != null ? "\nCenter: ${inv.standbyForCenter}" : ""}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple.shade700,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                Navigator.pop(ctx);
                                final messenger = ScaffoldMessenger.of(context);
                                await ref.read(dutyProvider.notifier).dispatchStandbyReplacement(
                                      originalDutyId: duty.id,
                                      standbyInvigilatorId: inv.id,
                                    );
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('⚡ Dispatched ${inv.name} as standby replacement!'),
                                      backgroundColor: Colors.purple.shade700,
                                    ),
                                  );
                                }
                              },
                              child: const Text('Dispatch'),
                            ),
                          ),
                        )),
                    if (otherStaff.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('OTHER ACTIVE STAFF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                      const SizedBox(height: 8),
                    ],
                  ],
                  if (taggedStandbys.isEmpty)
                    ...otherStaff.map((inv) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(inv.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Resource ID: ${inv.resourceId} • ${inv.mobile}', style: const TextStyle(fontSize: 11)),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF007A87),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                Navigator.pop(ctx);
                                final messenger = ScaffoldMessenger.of(context);
                                await ref.read(dutyProvider.notifier).dispatchStandbyReplacement(
                                      originalDutyId: duty.id,
                                      standbyInvigilatorId: inv.id,
                                    );
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('⚡ Dispatched ${inv.name} as standby replacement!'),
                                      backgroundColor: const Color(0xFF007A87),
                                    ),
                                  );
                                }
                              },
                              child: const Text('Dispatch'),
                            ),
                          ),
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStandbyPoolSheet(BuildContext context, List<Invigilator> allInvs, List<ExamCenter> centers) {
    final todayStr = DateFormat('yyyy-MM-dd').format(_now);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final standbys = allInvs.where((i) => i.isStandby == true).toList();
          return Container(
            padding: const EdgeInsets.all(20),
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flash_on, color: Color(0xFF7C3AED), size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Standby Staff Pool (${standbys.length})',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Standby', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _showAddStandbyDialog(context, allInvs, centers, todayStr),
                    ),
                  ],
                ),
                const Divider(height: 20),
                if (standbys.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_outline, size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            'No standby staff tagged yet.',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Tag standby staff in advance to quickly dispatch replacements for no-shows.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: standbys.length,
                      itemBuilder: (context, index) {
                        final inv = standbys[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.purple.shade200, width: 1),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.purple.shade100,
                              child: const Icon(Icons.bolt, color: Colors.purple, size: 20),
                            ),
                            title: Text(inv.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              'Date: ${inv.standbyForDate ?? "Any"} • Center: ${inv.standbyForCenter ?? "All Centers"}\nMobile: ${inv.mobile}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              tooltip: 'Remove Standby Tag',
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                await ref.read(invigilatorProvider.notifier).removeStandbyTag(inv.id);
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('Removed ${inv.name} from Standby Pool.')),
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddStandbyDialog(BuildContext context, List<Invigilator> allInvs, List<ExamCenter> centers, String defaultDate) {
    String? selectedInvId;
    String? selectedCenter;
    String selectedDate = defaultDate;
    final availableInvs = allInvs.where((i) => i.isStandby != true && i.isActive).toList();

    if (availableInvs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active staff available to tag as standby.')),
      );
      return;
    }

    selectedInvId = availableInvs.first.id;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.person_add_alt_1, color: Color(0xFF7C3AED)),
              SizedBox(width: 8),
              Text('Tag Staff as Standby', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Staff Member *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selectedInvId,
                isExpanded: true,
                items: availableInvs.map((i) => DropdownMenuItem(
                  value: i.id,
                  child: Text('${i.name} (${i.resourceId})', overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedInvId = val);
                },
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
              ),
              const SizedBox(height: 12),
              const Text('Standby Date *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.tryParse(selectedDate) ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 7)),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = DateFormat('yyyy-MM-dd').format(picked));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(selectedDate, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Icon(Icons.calendar_today, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Center (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String?>(
                initialValue: selectedCenter,
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Centers / Any')),
                  ...centers.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name, overflow: TextOverflow.ellipsis))),
                ],
                onChanged: (val) => setDialogState(() => selectedCenter = val),
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (selectedInvId == null) return;
                Navigator.pop(ctx);
                final messenger = ScaffoldMessenger.of(context);
                await ref.read(invigilatorProvider.notifier).tagAsStandby(
                  selectedInvId!,
                  selectedDate,
                  centerName: selectedCenter,
                );
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('✅ Staff successfully tagged as Standby!'), backgroundColor: Colors.green),
                  );
                }
              },
              child: const Text('Tag as Standby'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmergencyBroadcastDialog(List<ExamDuty> todayDuties, List<Invigilator> invs) {
    final s = S.of(context)!;
    final titleController = TextEditingController(text: '⚠️ Urgent Exam Day Notice');
    final messageController = TextEditingController();
    bool sendInApp = true;
    bool sendEmail = true;
    bool sendSms = false;
    String priorityLevel = 'high'; // 'normal', 'high', 'critical'
    bool isSending = false;

    // Unique staff IDs for today's duties
    final activeStaffIds = todayDuties.map((d) => d.invigilatorId).toSet();
    final activeStaff = invs.where((i) => activeStaffIds.contains(i.id)).toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.campaign, color: Colors.red.shade700, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Emergency Broadcast', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      'Send to ${activeStaff.length} active staff',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Priority Level
                  const Text('Priority Level', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPriorityChip('Normal', 'normal', Colors.blue, priorityLevel, (v) => setDialogState(() => priorityLevel = v)),
                      const SizedBox(width: 8),
                      _buildPriorityChip('High', 'high', Colors.orange, priorityLevel, (v) => setDialogState(() => priorityLevel = v)),
                      const SizedBox(width: 8),
                      _buildPriorityChip('Critical', 'critical', Colors.red, priorityLevel, (v) => setDialogState(() => priorityLevel = v)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Broadcast Title',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Message
                  TextField(
                    controller: messageController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Message',
                      hintText: 'e.g. All invigilators report to Hall A immediately for re-seating...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Delivery Channels
                  const Text('Delivery Channels', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('In-App Notification', style: TextStyle(fontSize: 13)),
                    subtitle: const Text('Instant push to all active staff', style: TextStyle(fontSize: 11)),
                    value: sendInApp,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (v) => setDialogState(() => sendInApp = v ?? true),
                    secondary: const Icon(Icons.notifications_active, color: Color(0xFF007A87), size: 20),
                  ),
                  CheckboxListTile(
                    title: const Text('Email (SMTP)', style: TextStyle(fontSize: 13)),
                    subtitle: const Text('Send to staff with email addresses', style: TextStyle(fontSize: 11)),
                    value: sendEmail,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (v) => setDialogState(() => sendEmail = v ?? false),
                    secondary: const Icon(Icons.email, color: Colors.blue, size: 20),
                  ),
                  CheckboxListTile(
                    title: const Text('SMS Gateway', style: TextStyle(fontSize: 13)),
                    subtitle: Text(
                      ref.read(dutySettingsProvider).smsGatewayUrl.isNotEmpty
                          ? 'Configured ✓'
                          : 'Not configured (set in Settings)',
                      style: TextStyle(
                        fontSize: 11,
                        color: ref.read(dutySettingsProvider).smsGatewayUrl.isNotEmpty
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    value: sendSms,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: ref.read(dutySettingsProvider).smsGatewayUrl.isNotEmpty
                        ? (v) => setDialogState(() => sendSms = v ?? false)
                        : null,
                    secondary: const Icon(Icons.sms, color: Colors.green, size: 20),
                  ),
                  const SizedBox(height: 12),

                  // Staff count summary
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.people, color: Colors.amber.shade800, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This broadcast will reach ${activeStaff.length} staff members assigned to today\'s exam duties.',
                            style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.cancel),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              icon: isSending
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.campaign, size: 18),
              label: Text(isSending ? 'Sending...' : 'Send Broadcast'),
              onPressed: isSending
                  ? null
                  : () async {
                      if (messageController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a broadcast message'), backgroundColor: Colors.orange),
                        );
                        return;
                      }

                      setDialogState(() => isSending = true);
                      final messenger = ScaffoldMessenger.of(context);
                      int sentCount = 0;

                      final title = titleController.text.trim();
                      final message = messageController.text.trim();

                      // 1. Send in-app notifications
                      if (sendInApp) {
                        for (final staff in activeStaff) {
                          await ref.read(notificationProvider.notifier).sendNotification(
                            userId: staff.id,
                            title: title,
                            message: message,
                            type: 'emergency_broadcast',
                          );
                          sentCount++;
                        }
                      }

                      // 2. Send emails
                      if (sendEmail) {
                        for (final staff in activeStaff) {
                          if (staff.email != null && staff.email!.contains('@')) {
                            try {
                              await SmtpEmailService.sendEmail(
                                toAddress: staff.email!,
                                subject: '[$priorityLevel] $title',
                                bodyText: '$message\n\n---\nThis is an automated emergency broadcast from DutyDesk.',
                              );
                            } catch (_) {}
                          }
                        }
                      }

                      // 3. Send SMS
                      if (sendSms) {
                        final settings = ref.read(dutySettingsProvider);
                        final phones = activeStaff
                            .where((s) => s.mobile.isNotEmpty)
                            .map((s) => s.mobile)
                            .toList();
                        if (phones.isNotEmpty && settings.smsGatewayUrl.isNotEmpty) {
                          await SmsGatewayService.sendBulkSms(
                            gatewayUrl: settings.smsGatewayUrl,
                            apiKey: settings.smsApiKey,
                            recipientPhones: phones,
                            message: '$title: $message',
                          );
                        }
                      }

                      if (ctx.mounted) Navigator.pop(ctx);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('📢 Emergency broadcast sent to $sentCount staff!'),
                          backgroundColor: Colors.red.shade700,
                        ),
                      );
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String label, String value, Color color, String current, ValueChanged<String> onTap) {
    final isSelected = current == value;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: isSelected ? 1.5 : 0.8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : color),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final globalDuties = ref.watch(globalDutyProvider);
    final invs = ref.watch(invigilatorProvider);
    final centers = ref.watch(centerProvider);
    final dutySettings = ref.watch(dutySettingsProvider);
    final todayStr = DateFormat('yyyy-MM-dd').format(_now);

    // Filter duties for TODAY only
    final todayDuties = globalDuties.where((d) => d.date == todayStr).toList();

    // Compute live metrics
    final totalDutiesCount = todayDuties.length;
    final reachedCount = todayDuties.where((d) => d.isReached).length;
    final pendingCount = todayDuties.where((d) => !d.isReached && d.status.toLowerCase() != 'rejected' && d.status.toLowerCase() != 'no_show').length;
    final lateCount = todayDuties.where((d) => d.isReached && (d.reachedPerformance == 'Needs Improvement' || d.reachedPerformance == 'Good')).length;
    final absentCount = todayDuties.where((d) => d.status.toLowerCase() == 'rejected' || (!d.isReached && _isDutyPastReportingTime(d.goodUntil))).length;
    final noShowCount = todayDuties.where((d) => d.status.toLowerCase() == 'no_show').length;
    final clockedOutCount = todayDuties.where((d) => d.isClockedOut).length;
    final standbyCount = invs.where((i) => i.isStandby == true).length;

    // Filter duties based on UI filters
    final filteredDuties = todayDuties.where((d) {
      if (_selectedCenterFilter != null && _selectedCenterFilter!.isNotEmpty && d.centerName != _selectedCenterFilter) {
        return false;
      }
      if (_selectedShiftFilter != null && _selectedShiftFilter!.isNotEmpty && d.shift != _selectedShiftFilter) {
        return false;
      }

      if (_selectedStatusFilter == 'reached' && !d.isReached) return false;
      if (_selectedStatusFilter == 'pending' && (d.isReached || d.status.toLowerCase() == 'rejected' || d.status.toLowerCase() == 'no_show')) return false;
      if (_selectedStatusFilter == 'late' && (!d.isReached || d.reachedPerformance == 'Excellent')) return false;
      if (_selectedStatusFilter == 'absent' && !(d.status.toLowerCase() == 'rejected' || (!d.isReached && _isDutyPastReportingTime(d.goodUntil)))) return false;
      if (_selectedStatusFilter == 'no_show' && d.status.toLowerCase() != 'no_show') return false;
      if (_selectedStatusFilter == 'clocked_out' && !d.isClockedOut) return false;
      if (_selectedStatusFilter == 'outside_geofence' && !(d.isReached && (d.isGeofenceVerified == false || d.geofenceStatus == 'outside' || d.geofenceStatus == 'manual_requested'))) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final staff = invs.firstWhere((i) => i.id == d.invigilatorId, orElse: () => Invigilator(id: '', name: '', resourceId: '', mobile: '', mockDutyCount: 0));
        final match = staff.name.toLowerCase().contains(q) ||
            staff.mobile.toLowerCase().contains(q) ||
            staff.resourceId.toLowerCase().contains(q) ||
            d.centerName.toLowerCase().contains(q) ||
            d.examName.toLowerCase().contains(q);
        if (!match) return false;
      }

      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.liveExamControlRoom, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.campaign, color: Colors.red.shade400),
            tooltip: 'Emergency Broadcast',
            onPressed: () => _showEmergencyBroadcastDialog(todayDuties, invs),
          ),
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.amber),
            tooltip: 'Standby Staff Pool ($standbyCount)',
            onPressed: () => _showStandbyPoolSheet(context, invs, centers),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: s.refresh,
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. LIVE TIME & STATUS HEADER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF007A87), Color(0xFF0F766E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF007A87).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            s.liveMonitoring.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, dd MMM yyyy').format(_now),
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      DateFormat('hh:mm:ss a').format(_now),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. SUMMARY METRICS CARDS
            Row(
              children: [
                Expanded(child: _buildMetricCard(s.todaysDuties, '$totalDutiesCount', const Color(0xFF007A87), Icons.assignment)),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricCard(s.reachedCount, '$reachedCount', Colors.green.shade700, Icons.check_circle_rounded)),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricCard(s.pendingCount, '$pendingCount', Colors.orange.shade700, Icons.pending_actions)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildMetricCard(s.lateCount, '$lateCount', Colors.deepOrange, Icons.alarm_off)),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricCard(s.absentCount, '$absentCount', Colors.red.shade700, Icons.error_outline)),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricCard('No-Show', '$noShowCount', Colors.purple.shade700, Icons.person_off_rounded)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _showStandbyPoolSheet(context, invs, centers),
                    borderRadius: BorderRadius.circular(12),
                    child: _buildMetricCard('Standby Pool', '$standbyCount', const Color(0xFF7C3AED), Icons.flash_on),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricCard('Clocked Out', '$clockedOutCount', Colors.teal.shade700, Icons.logout_rounded)),
              ],
            ),
            const SizedBox(height: 20),

            // 3. CENTER-WISE LIVE STATUS (Health Status Bars)
            Text(
              s.centerHealth.toUpperCase(),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF007A87), letterSpacing: 0.8),
            ),
            const SizedBox(height: 10),
            if (centers.isEmpty)
              Text(s.noCentersFound, style: const TextStyle(color: Colors.grey, fontSize: 12))
            else
              _buildCenterHealthSection(centers, todayDuties, s),
            const SizedBox(height: 20),

            // 4. SEARCH & FILTER CONTROLS
            Text(
              s.quickActions.toUpperCase(),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF007A87), letterSpacing: 0.8),
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                hintText: '${s.search}...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF007A87), size: 20),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
            const SizedBox(height: 10),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('${s.all} (${todayDuties.length})', 'all'),
                  _buildFilterChip('${s.reachedCount} ($reachedCount)', 'reached'),
                  _buildFilterChip('${s.pendingCount} ($pendingCount)', 'pending'),
                  _buildFilterChip('${s.lateCount} ($lateCount)', 'late'),
                  _buildFilterChip('${s.absentCount} ($absentCount)', 'absent'),
                  _buildFilterChip('No-Show ($noShowCount)', 'no_show'),
                  _buildFilterChip('Clocked Out ($clockedOutCount)', 'clocked_out'),
                  _buildFilterChip(s.outsideGeofenceFilter, 'outside_geofence'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 5. LIVE DUTY CARDS LIST
            if (filteredDuties.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(s.noResultsFound, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredDuties.length,
                itemBuilder: (context, i) {
                  final duty = filteredDuties[i];
                  final staff = invs.firstWhere(
                    (item) => item.id == duty.invigilatorId,
                    orElse: () => Invigilator(id: '', name: 'Unknown Staff', resourceId: '-', mobile: '', mockDutyCount: 0),
                  );
                  final activeInvs = invs.where((item) => item.isActive).toList();

                  return _buildLiveDutyCard(duty, staff, activeInvs, s, dutySettings);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Uses goodUntil as the final threshold — if current time is past goodUntil, duty is considered absent.
  bool _isDutyPastReportingTime(String goodUntil) {
    try {
      final now = DateTime.now();
      final format = DateFormat('hh:mm a');
      final goodDateTime = format.parse(goodUntil);
      final currentMinutes = now.hour * 60 + now.minute;
      final goodMinutes = goodDateTime.hour * 60 + goodDateTime.minute;
      return currentMinutes > goodMinutes;
    } catch (_) {
      return false;
    }
  }

  Widget _buildMetricCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterHealthSection(List<ExamCenter> centers, List<ExamDuty> todayDuties, S s) {
    return Column(
      children: centers.map((center) {
        final centerDuties = todayDuties.where((d) => d.centerName.toLowerCase() == center.name.toLowerCase()).toList();
        if (centerDuties.isEmpty) return const SizedBox.shrink();

        final centerTotal = centerDuties.length;
        final centerReached = centerDuties.where((d) => d.isReached).length;
        final percentage = centerTotal > 0 ? (centerReached / centerTotal) : 0.0;

        Color healthColor = Colors.green;
        String statusEmoji = '🟢';
        if (percentage < 0.7) {
          healthColor = Colors.red;
          statusEmoji = '🔴';
        } else if (percentage < 1.0) {
          healthColor = Colors.orange;
          statusEmoji = '🟡';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: healthColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      center.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        s.staffReachedCount(centerReached, centerTotal),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: healthColor),
                      ),
                      const SizedBox(width: 6),
                      Text(statusEmoji, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        selected: isSelected,
        selectedColor: const Color(0xFF007A87),
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
        onSelected: (selected) {
          if (selected) setState(() => _selectedStatusFilter = value);
        },
      ),
    );
  }

  Widget _buildLiveDutyCard(ExamDuty duty, Invigilator staff, List<Invigilator> activeInvs, S s, DutySettings dutySettings) {
    Color cardBorder = Colors.grey.shade300;
    Widget statusBadge;

    if (duty.isReached) {
      cardBorder = Colors.green.shade400;
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.green.shade400, width: 0.8),
        ),
        child: Text(
          '${s.reached.toUpperCase()} • ${duty.reachedTime ?? "-"}',
          style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 10.5),
        ),
      );
    } else if (duty.status.toLowerCase() == 'no_show') {
      cardBorder = Colors.purple.shade400;
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.purple.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.purple.shade400, width: 0.8),
        ),
        child: const Text('NO SHOW', style: TextStyle(color: Color(0xFF6B21A8), fontWeight: FontWeight.bold, fontSize: 10.5)),
      );
    } else if (duty.status.toLowerCase() == 'rejected') {
      cardBorder = Colors.red.shade400;
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.red.shade400, width: 0.8),
        ),
        child: Text('${s.rejected.toUpperCase()} / ${s.replacement.toUpperCase()}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10.5)),
      );
    } else {
      cardBorder = Colors.orange.shade300;
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.orange.shade400, width: 0.8),
        ),
        child: Text(s.pending.toUpperCase(), style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 10.5)),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cardBorder, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Staff Name + Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFF007A87).withValues(alpha: 0.1),
                        child: Text(
                          staff.name.isNotEmpty ? staff.name[0].toUpperCase() : 'S',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF007A87)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(staff.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('${s.resourceId}: ${staff.resourceId} • ${s.shift} ${duty.shift}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (duty.isStandbyReplacement)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('⚡ STANDBY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9.5)),
                      ),
                    if (duty.isFaceVerified)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF6366F1), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_user_rounded, color: Color(0xFF6366F1), size: 10),
                            const SizedBox(width: 3),
                            Text(
                              duty.faceMatchScore != null
                                  ? 'FACE ${duty.faceMatchScore!.toStringAsFixed(0)}%'
                                  : 'FACE OK',
                              style: const TextStyle(
                                color: Color(0xFF6366F1),
                                fontWeight: FontWeight.bold,
                                fontSize: 9.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (duty.isClockedOut)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('CLOCKED OUT', style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold, fontSize: 9.5)),
                      ),
                    statusBadge,
                  ],
                ),
              ],
            ),
            const Divider(height: 18),

            // Exam & Center Info
            Row(
              children: [
                const Icon(Icons.book, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(child: Text('${duty.examName} • ${duty.centerName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${s.reportingTime}: ${duty.reportingTime}  ★${duty.excellentUntil}  👍${duty.goodUntil}', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                if (duty.reachedPerformance != null) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: duty.reachedPerformance == 'Excellent' ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      duty.reachedPerformance!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: duty.reachedPerformance == 'Excellent' ? Colors.green.shade800 : Colors.deepOrange,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            // Geofence & Location Row (if reached)
            if (duty.isReached) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      duty.isGeofenceVerified == true ? Icons.radar : Icons.warning_amber_rounded,
                      size: 16,
                      color: duty.isGeofenceVerified == true ? Colors.teal : Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        duty.distanceFromCenter != null
                            ? (duty.isGeofenceVerified == true
                                ? '${s.geofenceVerified} (${s.distanceMeters(duty.distanceFromCenter! < 1000 ? duty.distanceFromCenter!.toStringAsFixed(0) : (duty.distanceFromCenter! / 1000).toStringAsFixed(1))})'
                                : '${s.outsideGeofence} (${(duty.distanceFromCenter! / 1000).toStringAsFixed(1)}km)')
                            : (duty.reachedLocation ?? s.arrivalRecorded),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: duty.isGeofenceVerified == true ? Colors.teal.shade800 : Colors.deepOrange,
                        ),
                      ),
                    ),
                    if (duty.resolvedMapsUrl != null)
                      InkWell(
                        onTap: () => LocationService.openMapLocation(
                          duty.resolvedMapsUrl!,
                          latitude: duty.reachedLatitude,
                          longitude: duty.reachedLongitude,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(Icons.map, size: 18, color: Color(0xFF007A87)),
                        ),
                      ),
                  ],
                ),
              ),
            ],

            // Clock-out info (if clocked out)
            if (duty.isClockedOut) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.logout_rounded, size: 16, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Clocked out at ${duty.clockOutTime ?? "-"}${duty.clockOutGeofenceVerified == true ? " • Geofence Verified" : duty.clockOutGeofenceStatus != null ? " • ${duty.clockOutGeofenceStatus}" : ""}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // No-show reason box (if marked no-show)
            if (duty.status.toLowerCase() == 'no_show' && duty.noShowReason != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade200, width: 0.8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.purple.shade800),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'No-Show Reason: ${duty.noShowReason!}',
                        style: TextStyle(fontSize: 11, color: Colors.purple.shade900, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Action Buttons (Call Staff, Dispatch Standby, Mark No-Show, Reassign Replacement)
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 6,
              runSpacing: 6,
              children: [
                if (staff.mobile.isNotEmpty)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.phone, size: 14, color: Colors.green),
                    label: Text(s.callStaff, style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      side: const BorderSide(color: Colors.green, width: 0.8),
                    ),
                    onPressed: () => _makePhoneCall(staff.mobile),
                  ),
                if (duty.status.toLowerCase() == 'no_show')
                  ElevatedButton.icon(
                    icon: const Icon(Icons.bolt, size: 14),
                    label: const Text('Dispatch Standby', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _showDispatchStandbyModal(duty, activeInvs),
                  ),
                if (!duty.isReached && duty.status.toLowerCase() != 'no_show' && duty.status.toLowerCase() != 'rejected')
                  OutlinedButton.icon(
                    icon: const Icon(Icons.person_off_outlined, size: 14, color: Colors.purple),
                    label: const Text('Mark No-Show', style: TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      side: const BorderSide(color: Colors.purple, width: 0.8),
                    ),
                    onPressed: () => _showMarkNoShowDialog(duty, staff),
                  ),
                if (dutySettings.allowDutySwap && (!duty.isReached || duty.status.toLowerCase() == 'rejected'))
                  ElevatedButton.icon(
                    icon: const Icon(Icons.swap_horiz, size: 14),
                    label: Text(s.reassign, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade800,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _showReassignModal(duty, activeInvs),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
