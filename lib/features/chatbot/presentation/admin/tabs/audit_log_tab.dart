import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/chatbot_admin_provider.dart';

class AuditLogTab extends ConsumerWidget {
  const AuditLogTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(chatbotAuditProvider);

    if (logs.isEmpty) {
      return const Center(
        child: Text('No admin audit entries yet.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: logs.length,
      itemBuilder: (ctx, i) {
        final entry = logs[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.security_rounded, color: Color(0xFF007A87)),
            title: Text(
              entry.action.replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            subtitle: Text(
              'Actor: ${entry.actorUid}\nTarget: ${entry.targetId ?? '-'}\nDetails: ${entry.details}',
              style: const TextStyle(fontSize: 11.5),
            ),
            trailing: Text(
              entry.createdAt != null
                  ? DateFormat('dd MMM, HH:mm').format(entry.createdAt!)
                  : '',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }
}
