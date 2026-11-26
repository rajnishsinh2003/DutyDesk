import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/chatbot_settings.dart';
import '../../../providers/chatbot_admin_provider.dart';
import '../../../providers/chatbot_widget_provider.dart';

class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({super.key});

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab> {
  late ChatbotSettings _draft;
  bool _saving = false;

  late final TextEditingController _botNameCtrl;
  late final TextEditingController _pinnedCtrl;
  late final TextEditingController _welcomeEnCtrl;
  late final TextEditingController _welcomeHiCtrl;
  late final TextEditingController _welcomeGuCtrl;
  late final TextEditingController _fallbackEnCtrl;
  late final TextEditingController _fallbackHiCtrl;
  late final TextEditingController _fallbackGuCtrl;
  late final TextEditingController _toneCtrl;
  late final TextEditingController _landingSugCtrl;
  late final TextEditingController _invSugCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _waCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _maxLenCtrl;
  late final TextEditingController _capCtrl;
  late final TextEditingController _budgetCtrl;
  late final TextEditingController _retentionCtrl;

  @override
  void initState() {
    super.initState();
    final s = ref.read(chatbotSettingsProvider);
    _draft = s;
    _botNameCtrl = TextEditingController(text: s.botName);
    _pinnedCtrl = TextEditingController(text: s.pinnedAnnouncement);
    _welcomeEnCtrl = TextEditingController(text: s.welcomeMessage['en'] ?? '');
    _welcomeHiCtrl = TextEditingController(text: s.welcomeMessage['hi'] ?? '');
    _welcomeGuCtrl = TextEditingController(text: s.welcomeMessage['gu'] ?? '');
    _fallbackEnCtrl = TextEditingController(text: s.fallbackMessage['en'] ?? '');
    _fallbackHiCtrl = TextEditingController(text: s.fallbackMessage['hi'] ?? '');
    _fallbackGuCtrl = TextEditingController(text: s.fallbackMessage['gu'] ?? '');
    _toneCtrl = TextEditingController(text: s.systemPromptAdditions);
    _landingSugCtrl = TextEditingController(
        text: (s.suggestedQuestions['landing']?['en'] ?? []).join('\n'));
    _invSugCtrl = TextEditingController(
        text: (s.suggestedQuestions['invigilator']?['en'] ?? []).join('\n'));
    _phoneCtrl = TextEditingController(text: s.handoffContact.phone);
    _waCtrl = TextEditingController(text: s.handoffContact.whatsapp);
    _emailCtrl = TextEditingController(text: s.handoffContact.email);
    _maxLenCtrl = TextEditingController(text: '${s.maxInputLength}');
    _capCtrl = TextEditingController(text: '${s.perSessionMessageCap}');
    _budgetCtrl = TextEditingController(text: '${s.dailyTokenBudget}');
    _retentionCtrl = TextEditingController(text: '${s.retentionDays}');
  }

  @override
  void dispose() {
    for (final c in [
      _botNameCtrl,
      _pinnedCtrl,
      _welcomeEnCtrl,
      _welcomeHiCtrl,
      _welcomeGuCtrl,
      _fallbackEnCtrl,
      _fallbackHiCtrl,
      _fallbackGuCtrl,
      _toneCtrl,
      _landingSugCtrl,
      _invSugCtrl,
      _phoneCtrl,
      _waCtrl,
      _emailCtrl,
      _maxLenCtrl,
      _capCtrl,
      _budgetCtrl,
      _retentionCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final base = _draft;
    setState(() => _saving = true);

    try {
      final updated = base.copyWith(
        botName: _botNameCtrl.text.trim(),
        pinnedAnnouncement: _pinnedCtrl.text.trim(),
        welcomeMessage: {
          'en': _welcomeEnCtrl.text.trim(),
          'hi': _welcomeHiCtrl.text.trim(),
          'gu': _welcomeGuCtrl.text.trim(),
        },
        fallbackMessage: {
          'en': _fallbackEnCtrl.text.trim(),
          'hi': _fallbackHiCtrl.text.trim(),
          'gu': _fallbackGuCtrl.text.trim(),
        },
        systemPromptAdditions: _toneCtrl.text.trim(),
        suggestedQuestions: {
          'landing': {
            ...base.suggestedQuestions['landing'] ?? {},
            'en': _landingSugCtrl.text
                .split('\n')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList(),
          },
          'invigilator': {
            ...base.suggestedQuestions['invigilator'] ?? {},
            'en': _invSugCtrl.text
                .split('\n')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList(),
          },
        },
        handoffContact: HandoffContact(
          phone: _phoneCtrl.text.trim(),
          whatsapp: _waCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
        ),
        maxInputLength: int.tryParse(_maxLenCtrl.text) ?? 500,
        perSessionMessageCap: int.tryParse(_capCtrl.text) ?? 50,
        dailyTokenBudget: int.tryParse(_budgetCtrl.text) ?? 500000,
        retentionDays: int.tryParse(_retentionCtrl.text) ?? 90,
      );

      await saveChatbotSettings(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved! Changes apply live immediately.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _draft;
    const brandColor = Color(0xFF007A87);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            title: const Text('Enable Chatbot on Landing Page (Public)'),
            value: current.landingEnabled,
            onChanged: (v) =>
                setState(() => _draft = current.copyWith(landingEnabled: v)),
          ),
          SwitchListTile(
            title: const Text('Enable Chatbot on Invigilator Dashboard'),
            value: current.invigilatorEnabled,
            onChanged: (v) =>
                setState(() => _draft = current.copyWith(invigilatorEnabled: v)),
          ),
          SwitchListTile(
            title: const Text('Answer ONLY from Documents & Approved FAQs'),
            subtitle: const Text(
                'When enabled, low-confidence queries return the fallback message and log to Unanswered.'),
            value: current.answerOnlyFromDocuments,
            onChanged: (v) => setState(
                () => _draft = current.copyWith(answerOnlyFromDocuments: v)),
          ),
          const Divider(height: 24),
          TextField(
            controller: _botNameCtrl,
            decoration: const InputDecoration(labelText: 'Bot Name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _pinnedCtrl,
            decoration:
                const InputDecoration(labelText: 'Pinned Announcement (optional)'),
          ),
          const SizedBox(height: 14),
          const Text('Welcome Messages',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
              controller: _welcomeEnCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Welcome (English)')),
          TextField(
              controller: _welcomeHiCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Welcome (Hindi)')),
          TextField(
              controller: _welcomeGuCtrl,
              maxLines: 2,
              decoration:
                  const InputDecoration(labelText: 'Welcome (Gujarati)')),
          const SizedBox(height: 14),
          const Text('Fallback Messages (When Unanswered)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(
              controller: _fallbackEnCtrl,
              maxLines: 2,
              decoration:
                  const InputDecoration(labelText: 'Fallback (English)')),
          TextField(
              controller: _fallbackHiCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Fallback (Hindi)')),
          TextField(
              controller: _fallbackGuCtrl,
              maxLines: 2,
              decoration:
                  const InputDecoration(labelText: 'Fallback (Gujarati)')),
          const SizedBox(height: 14),
          TextField(
            controller: _landingSugCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Suggested Questions — Landing (one per line)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _invSugCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Suggested Questions — Invigilator (one per line)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _toneCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Tone / System Prompt Additions',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          Text(
              'Similarity Threshold: ${current.similarityThreshold.toStringAsFixed(2)}'),
          Slider(
            value: current.similarityThreshold.clamp(0.1, 0.95),
            min: 0.1,
            max: 0.95,
            divisions: 17,
            onChanged: (v) => setState(
                () => _draft = current.copyWith(similarityThreshold: v)),
          ),
          Text('Temperature: ${current.temperature.toStringAsFixed(2)}'),
          Slider(
            value: current.temperature.clamp(0.0, 1.0),
            min: 0.0,
            max: 1.0,
            divisions: 10,
            onChanged: (v) =>
                setState(() => _draft = current.copyWith(temperature: v)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _maxLenCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Max Input Length'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _capCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Session Msg Cap'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _budgetCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Daily Token Budget'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _retentionCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Retention Days'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Human Handoff Contact',
              style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Support Phone')),
          TextField(
              controller: _waCtrl,
              decoration: const InputDecoration(labelText: 'WhatsApp Number')),
          TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Support Email')),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: brandColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            label: const Text('Save All Chatbot Settings',
                style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
