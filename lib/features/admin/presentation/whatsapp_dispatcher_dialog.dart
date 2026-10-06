import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../invigilator/providers/duty_provider.dart';
import '../providers/invigilator_provider.dart';
import '../../../core/services/sms_gateway_service.dart';

/// Interactive WhatsApp broadcast console with simulated 2-way incoming webhook responses.
class WhatsAppDispatcherDialog extends ConsumerStatefulWidget {
  const WhatsAppDispatcherDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => const WhatsAppDispatcherDialog(),
    );
  }

  @override
  ConsumerState<WhatsAppDispatcherDialog> createState() => _WhatsAppDispatcherDialogState();
}

class _WhatsAppDispatcherDialogState extends ConsumerState<WhatsAppDispatcherDialog> {
  String _selectedTemplate = 'allocation';
  String _selectedTarget = 'all_pending';
  bool _isDispatching = false;
  final List<Map<String, dynamic>> _webhookLogs = [];

  void _dispatchBroadcast() async {
    setState(() => _isDispatching = true);
    HapticFeedback.mediumImpact();

    await Future.delayed(const Duration(milliseconds: 600));

    final duties = ref.read(globalDutyProvider);
    final invs = ref.read(invigilatorProvider);

    int count = 0;
    for (final duty in duties) {
      if (_selectedTarget == 'all_pending' && duty.status.toLowerCase() != 'pending') continue;

      final inv = invs.firstWhere(
        (i) => i.id == duty.invigilatorId,
        orElse: () => Invigilator(id: '', name: 'Staff', resourceId: '-', mobile: '', mockDutyCount: 0),
      );

      count++;
      final msg = _selectedTemplate == 'emergency'
          ? '🚨 URGENT DutyDesk Alert: Emergency exam duty required for ${duty.examName} at ${duty.centerName}. Reply CONFIRM to accept.'
          : '📋 DutyDesk Exam Notice: You have been assigned invigilation duty for ${duty.examName} on ${duty.date} (Shift ${duty.shift}). Reply CONFIRM or SWAP.';

      // Dispatch via SmsGatewayService
      SmsGatewayService.sendSms(
        gatewayUrl: 'https://api.dutydesk.local/sms',
        apiKey: 'DUTYDESK_DEMO_KEY',
        recipientPhone: inv.mobile.isNotEmpty ? inv.mobile : '9876543210',
        message: msg,
        senderId: 'DUTYDK',
      );

      if (mounted) {
        _webhookLogs.insert(0, {
          'timestamp': TimeOfDay.now().format(context),
        'direction': 'OUTGOING',
        'recipient': '${inv.name} (${inv.mobile})',
        'text': msg,
          'dutyId': duty.id,
          'invigilatorId': inv.id,
        });
      }
    }

    if (mounted) {
      setState(() => _isDispatching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📱 WhatsApp Interactive Broadcast sent to $count faculty members!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _simulateIncomingWebhookReply(Map<String, dynamic> log, String replyAction) async {
    HapticFeedback.heavyImpact();
    final recipient = log['recipient'] as String?;

    final dutyId = log['dutyId'] as String?;

    if (dutyId != null) {
      final notifier = ref.read(dutyProvider.notifier);

      if (replyAction == 'CONFIRM') {
        await notifier.updateDutyStatus(dutyId, 'accepted');
      } else if (replyAction == 'SWAP') {
        await notifier.updateDutyStatus(dutyId, 'pending');
      }

      setState(() {
        _webhookLogs.insert(0, {
          'timestamp': TimeOfDay.now().format(context),
          'direction': 'INCOMING_WEBHOOK',
          'recipient': recipient ?? 'Faculty',
          'text': 'Action: [$replyAction] processed via WhatsApp Cloud Webhook',
          'action': replyAction,
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚡ Webhook Received: $recipient replied "$replyAction" — Duty roster updated!'),
            backgroundColor: const Color(0xFF007A87),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF007A87);
    const whatsappGreen = Color(0xFF25D366);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: whatsappGreen.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(color: whatsappGreen.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: 2),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFF075E54),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WhatsApp Interactive Hub',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            'Automated Duty Notices & 2-Way Webhook Console',
                            style: TextStyle(color: Colors.white70, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Template Selector
                    const Text('Broadcast Template', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTemplate,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'allocation',
                          child: Text('Official Allocation Notice (with Confirm/Swap)'),
                        ),
                        DropdownMenuItem(
                          value: 'emergency',
                          child: Text('Emergency Urgent Callout (Reserve Swapping)'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _selectedTemplate = v ?? 'allocation'),
                    ),
                    const SizedBox(height: 12),

                    // Target Filter
                    const Text('Target Audience', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTarget,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all_pending', child: Text('All Pending/Unconfirmed Duties')),
                        DropdownMenuItem(value: 'all', child: Text('All Allocated Staff Roster')),
                      ],
                      onChanged: (v) => setState(() => _selectedTarget = v ?? 'all_pending'),
                    ),
                    const SizedBox(height: 16),

                    // Dispatch Button
                    ElevatedButton.icon(
                      icon: _isDispatching
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(_isDispatching ? 'Dispatching Payloads...' : 'Send WhatsApp Broadcast',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: whatsappGreen,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isDispatching ? null : _dispatchBroadcast,
                    ),
                    const Divider(color: Colors.white12, height: 26),

                    // Interactive Webhook Activity Feed
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Live Webhook Event Feed',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        if (_webhookLogs.isNotEmpty)
                          TextButton(
                            onPressed: () => setState(() => _webhookLogs.clear()),
                            child: const Text('Clear Logs', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Container(
                      height: 180,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF050B14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: _webhookLogs.isEmpty
                          ? const Center(
                              child: Text(
                                'No webhook dispatches yet.\nClick "Send WhatsApp Broadcast" to start.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white38, fontSize: 11),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _webhookLogs.length,
                              itemBuilder: (context, idx) {
                                final item = _webhookLogs[idx];
                                final isOut = item['direction'] == 'OUTGOING';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isOut ? const Color(0xFF1E293B) : const Color(0xFF064E3B),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isOut ? Colors.white12 : whatsappGreen.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                isOut ? Icons.arrow_upward : Icons.arrow_downward,
                                                size: 12,
                                                color: isOut ? const Color(0xFF22D3EE) : whatsappGreen,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                item['direction'] as String,
                                                style: TextStyle(
                                                  color: isOut ? const Color(0xFF22D3EE) : whatsappGreen,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 9.5,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(item['recipient'] as String, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                                            ],
                                          ),
                                          Text(item['timestamp'] as String, style: const TextStyle(color: Colors.white38, fontSize: 9.5)),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(item['text'] as String, style: const TextStyle(color: Colors.white, fontSize: 11)),
                                      if (isOut) ...[
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Text('Simulate User Reply: ', style: TextStyle(color: Colors.white54, fontSize: 9.5)),
                                            InkWell(
                                              onTap: () => _simulateIncomingWebhookReply(item, 'CONFIRM'),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(color: brandColor, borderRadius: BorderRadius.circular(4)),
                                                child: const Text('CONFIRM', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            InkWell(
                                              onTap: () => _simulateIncomingWebhookReply(item, 'SWAP'),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(4)),
                                                child: const Text('SWAP', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
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
}
