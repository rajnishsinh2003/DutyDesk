import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/chatbot_unanswered.dart';
import '../../../providers/chatbot_admin_provider.dart';
import '../../../services/chatbot_api_service.dart';

class UnansweredTab extends ConsumerWidget {
  const UnansweredTab({super.key});

  Future<void> _resolveDialog(
    BuildContext context,
    WidgetRef ref,
    ChatbotUnanswered item,
  ) async {
    final answerCtrl = TextEditingController();
    final docs = ref.read(chatbotDocumentsProvider);
    String? linkedDocId;
    final audience = <String>{'public', 'invigilator'};

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Resolve Unanswered Question'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Question: "${item.question}"',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: answerCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Official Answer (creates an Approved FAQ)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String?>(
                    initialValue: linkedDocId,
                    decoration: const InputDecoration(
                        labelText: 'Or Link Existing Document (optional)'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      ...docs.map((d) =>
                          DropdownMenuItem(value: d.id, child: Text(d.title))),
                    ],
                    onChanged: (v) => setDlg(() => linkedDocId = v),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: ['public', 'invigilator', 'admin'].map((aud) {
                      return FilterChip(
                        label: Text(aud),
                        selected: audience.contains(aud),
                        onSelected: (sel) => setDlg(() {
                          sel ? audience.add(aud) : audience.remove(aud);
                        }),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save & Resolve')),
          ],
        ),
      ),
    );

    if (ok == true) {
      await ChatbotApiService.resolveUnanswered(
        unansweredId: item.id,
        answer: answerCtrl.text.trim().isNotEmpty ? answerCtrl.text.trim() : null,
        linkedDocId: linkedDocId,
        audience: audience.isEmpty ? ['public'] : audience.toList(),
        language: item.locale,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marked resolved & updated Knowledge Base!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(chatbotUnansweredProvider);

    if (items.isEmpty) {
      return const Center(
        child: Text('No unanswered questions! Great job.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        final isOpen = item.status == 'open';
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isOpen
                  ? Colors.orange.withValues(alpha: 0.15)
                  : Colors.green.withValues(alpha: 0.15),
              child: Text(
                '${item.count}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isOpen ? Colors.orange.shade800 : Colors.green,
                ),
              ),
            ),
            title: Text(item.question,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              'Surface: ${item.surface} • Lang: ${item.locale.toUpperCase()} • Status: ${item.status.toUpperCase()}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: isOpen
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007A87),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _resolveDialog(context, ref, item),
                    child: const Text('Answer / Resolve'),
                  )
                : const Icon(Icons.check_circle, color: Colors.green),
          ),
        );
      },
    );
  }
}
