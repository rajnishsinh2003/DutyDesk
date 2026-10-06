import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:duty_desk/l10n/app_localizations.dart';
import '../providers/duty_settings_provider.dart';
import '../../../core/services/data_archival_service.dart';

class DutySettingsDialog extends ConsumerStatefulWidget {
  const DutySettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DutySettingsDialog(),
    );
  }

  @override
  ConsumerState<DutySettingsDialog> createState() => _DutySettingsDialogState();
}

class _DutySettingsDialogState extends ConsumerState<DutySettingsDialog> {
  late TextEditingController _shift1Ctrl;
  late TextEditingController _shift2Ctrl;
  late TextEditingController _shift3Ctrl;
  late TextEditingController _taRateCtrl;
  late TextEditingController _smsGatewayCtrl;
  late TextEditingController _smsApiKeyCtrl;
  late TextEditingController _whatsappGatewayCtrl;
  late TextEditingController _whatsappApiKeyCtrl;
  late TextEditingController _retentionDaysCtrl;

  bool _initialized = false;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final settings = ref.read(dutySettingsProvider);
      _shift1Ctrl = TextEditingController(text: settings.shift1Amount.toString());
      _shift2Ctrl = TextEditingController(text: settings.shift2Amount.toString());
      _shift3Ctrl = TextEditingController(text: settings.shift3Amount.toString());
      _taRateCtrl = TextEditingController(text: settings.travelAllowancePerKm.toString());
      _smsGatewayCtrl = TextEditingController(text: settings.smsGatewayUrl);
      _smsApiKeyCtrl = TextEditingController(text: settings.smsApiKey);
      _whatsappGatewayCtrl = TextEditingController(text: settings.whatsappGatewayUrl);
      _whatsappApiKeyCtrl = TextEditingController(text: settings.whatsappApiKey);
      _retentionDaysCtrl = TextEditingController(text: settings.dataRetentionDays.toString());
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _shift1Ctrl.dispose();
    _shift2Ctrl.dispose();
    _shift3Ctrl.dispose();
    _taRateCtrl.dispose();
    _smsGatewayCtrl.dispose();
    _smsApiKeyCtrl.dispose();
    _whatsappGatewayCtrl.dispose();
    _whatsappApiKeyCtrl.dispose();
    _retentionDaysCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final settings = ref.watch(dutySettingsProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDarkMode ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007A87).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune_rounded, color: Color(0xFF007A87), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.dutySettings,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        s.settings,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 1. PERMISSION TOGGLES SECTION
            Text(
              s.settings,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF007A87)),
            ),
            const SizedBox(height: 8),

            // Allow Swap Duty
            Card(
              elevation: 0,
              color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: SwitchListTile(
                title: Text(s.swapDuty, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(
                  settings.allowDutySwap
                      ? 'Staff can request and perform duty swaps.'
                      : 'Duty swap is disabled for all staff.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                value: settings.allowDutySwap,
                activeThumbColor: const Color(0xFF007A87),
                onChanged: (val) {
                  ref.read(dutySettingsProvider.notifier).toggleDutySwap(val);
                },
              ),
            ),
            const SizedBox(height: 8),

            // Allow Lunch
            Card(
              elevation: 0,
              color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: SwitchListTile(
                title: Text(s.lunchProvision, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(
                  settings.allowLunch
                      ? 'Lunch tracking is enabled and accessible.'
                      : 'Lunch feature is disabled for staff.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                value: settings.allowLunch,
                activeThumbColor: const Color(0xFF007A87),
                onChanged: (val) {
                  ref.read(dutySettingsProvider.notifier).toggleLunch(val);
                },
              ),
            ),
            const SizedBox(height: 8),

            // Duty Roles Allocation (Invigilator / Lab Staff / MTOE)
            Card(
              elevation: 0,
              color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: SwitchListTile(
                title: const Text('Duty Roles (Invigilator / Lab Staff / MTOE)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(
                  settings.allowRole
                      ? 'Role selection and display are enabled across the app.'
                      : 'Duty roles are disabled and hidden across the app.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                value: settings.allowRole,
                activeThumbColor: const Color(0xFF007A87),
                onChanged: (val) {
                  ref.read(dutySettingsProvider.notifier).toggleRole(val);
                },
              ),
            ),
            const SizedBox(height: 8),

            // Voice Feedback (TTS)
            Card(
              elevation: 0,
              color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: SwitchListTile(
                title: Text(s.voiceFeedback, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(
                  settings.voiceFeedbackEnabled
                      ? 'Spoken arrival announcement is ON.'
                      : 'Spoken arrival announcement is muted.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                value: settings.voiceFeedbackEnabled,
                activeThumbColor: const Color(0xFF007A87),
                onChanged: (val) {
                  ref.read(dutySettingsProvider.notifier).toggleVoiceFeedback(val);
                },
              ),
            ),
            const SizedBox(height: 20),

            // 2. SHIFT REMUNERATION RATES
            Text(
              s.shiftRemuneration,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF007A87)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _shift1Ctrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: s.shift1,
                      prefixText: '₹',
                      filled: true,
                      fillColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _shift2Ctrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: s.shift2,
                      prefixText: '₹',
                      filled: true,
                      fillColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _shift3Ctrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: s.shift3,
                      prefixText: '₹',
                      filled: true,
                      fillColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. ARRIVAL TIMING — NOW PER-DUTY (Informational Banner)
            Text(
              s.arrivalThreshold,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF007A87)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF007A87).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF007A87).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF007A87), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Per-Duty Timing Enabled',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF007A87)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Arrival timing (Reporting Time, Excellent Until, Good Until) is now configured individually for each duty allocation. Different exams and shifts can have different timings.',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. SMS GATEWAY CONFIGURATION
            const Text(
              '📨 SMS / WhatsApp Gateway',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF007A87)),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _smsGatewayCtrl,
              decoration: InputDecoration(
                labelText: 'SMS Gateway URL',
                hintText: 'e.g. https://www.fast2sms.com/dev/bulkV2',
                prefixIcon: const Icon(Icons.link, size: 18),
                filled: true,
                fillColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _smsApiKeyCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'SMS API Key',
                hintText: 'Your gateway API key / auth token',
                prefixIcon: const Icon(Icons.key, size: 18),
                filled: true,
                fillColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: settings.smsProvider,
              decoration: InputDecoration(
                labelText: 'SMS Provider',
                prefixIcon: const Icon(Icons.business, size: 18),
                filled: true,
                fillColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: const [
                DropdownMenuItem(value: 'generic', child: Text('Generic REST API')),
                DropdownMenuItem(value: 'fast2sms', child: Text('Fast2SMS')),
                DropdownMenuItem(value: 'msg91', child: Text('Msg91')),
                DropdownMenuItem(value: 'textlocal', child: Text('Textlocal')),
                DropdownMenuItem(value: 'twilio', child: Text('Twilio')),
              ],
              onChanged: (val) {
                if (val != null) {
                  ref.read(dutySettingsProvider.notifier).updateSettings(
                    settings.copyWith(smsProvider: val),
                  );
                }
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _whatsappGatewayCtrl,
              decoration: InputDecoration(
                labelText: 'WhatsApp Gateway URL (Optional)',
                hintText: 'e.g. https://graph.facebook.com/v17.0/PHONE_ID/messages',
                prefixIcon: const Icon(Icons.chat, size: 18, color: Colors.green),
                filled: true,
                fillColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _whatsappApiKeyCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'WhatsApp API Key (Optional)',
                hintText: 'Bearer token for WhatsApp Business API',
                prefixIcon: const Icon(Icons.vpn_key, size: 18, color: Colors.green),
                filled: true,
                fillColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),

            // 5. DATA RETENTION & ARCHIVAL
            const Text(
              '🗄️ Data Retention & Archival',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF007A87)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _retentionDaysCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Retention Period (days)',
                      hintText: 'e.g. 90',
                      prefixIcon: const Icon(Icons.schedule, size: 18),
                      filled: true,
                      fillColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.archive, size: 18),
                  label: const Text('Run Archive', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final days = int.tryParse(_retentionDaysCtrl.text.trim()) ?? 90;
                    final messenger = ScaffoldMessenger.of(context);
                    final preview = await DataArchivalService.previewArchival(retentionDays: days);
                    if (!context.mounted) return;

                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('Confirm Archival', style: TextStyle(fontWeight: FontWeight.bold)),
                        content: Text(
                          'This will archive:\n'
                          '• ${preview.eligibleDuties} duties\n'
                          '• ${preview.eligibleNotifications} notifications\n'
                          '• ${preview.eligibleIncidents} incidents\n\n'
                          'older than $days days. Data will be moved to archive collections.',
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Archive Now'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      final report = await DataArchivalService.runFullArchival(retentionDays: days);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('🗄️ Archived ${report.totalArchived} records successfully!'),
                          backgroundColor: Colors.deepPurple,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      setState(() => _isSaving = true);
                      try {
                        final s1 = int.tryParse(_shift1Ctrl.text.trim()) ?? 400;
                        final s2 = int.tryParse(_shift2Ctrl.text.trim()) ?? 600;
                        final s3 = int.tryParse(_shift3Ctrl.text.trim()) ?? 800;

                        final updated = settings.copyWith(
                          shift1Amount: s1,
                          shift2Amount: s2,
                          shift3Amount: s3,
                          smsGatewayUrl: _smsGatewayCtrl.text.trim(),
                          smsApiKey: _smsApiKeyCtrl.text.trim(),
                          whatsappGatewayUrl: _whatsappGatewayCtrl.text.trim(),
                          whatsappApiKey: _whatsappApiKeyCtrl.text.trim(),
                          dataRetentionDays: int.tryParse(_retentionDaysCtrl.text.trim()) ?? 90,
                        );

                        await ref.read(dutySettingsProvider.notifier).updateSettings(updated);

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(s.settingsSaved),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${s.error}: $e'), backgroundColor: Colors.red),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isSaving = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007A87),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(s.saveChanges, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
