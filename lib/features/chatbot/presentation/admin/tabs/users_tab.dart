import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/chatbot_admin_provider.dart';

class UsersTab extends ConsumerWidget {
  const UsersTab({super.key});

  String _maskMobile(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    if (raw.length <= 4) return '****';
    return '${'*' * (raw.length - 4)}${raw.substring(raw.length - 4)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(chatbotSessionsProvider);

    // Aggregate by user key (invigilator userId or anonymous ownerUid)
    final grouped = <String, _ChatterSummary>{};
    for (final s in sessions) {
      final isInv = s.userType == 'invigilator' && (s.userId?.isNotEmpty ?? false);
      final key = isInv ? 'inv_${s.userId}' : 'anon_${s.ownerUid.isNotEmpty ? s.ownerUid : s.id}';
      final existing = grouped[key];
      if (existing == null) {
        grouped[key] = _ChatterSummary(
          name: isInv ? (s.userName ?? 'Invigilator') : 'Anonymous Visitor',
          role: s.userType,
          invigilatorId: isInv ? _maskMobile(s.userId) : '—',
          chatCount: 1,
          messageCount: s.messageCount,
          lastActive: s.lastMessageAt,
          locale: s.locale,
          platform: s.platform,
        );
      } else {
        existing.chatCount += 1;
        existing.messageCount += s.messageCount;
        if (s.lastMessageAt != null &&
            (existing.lastActive == null ||
                s.lastMessageAt!.isAfter(existing.lastActive!))) {
          existing.lastActive = s.lastMessageAt;
        }
      }
    }

    final users = grouped.values.toList()
      ..sort((a, b) => (b.lastActive ?? DateTime(2000))
          .compareTo(a.lastActive ?? DateTime(2000)));

    if (users.isEmpty) {
      return const Center(
        child: Text('No chatbot users recorded yet.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: users.length,
      itemBuilder: (ctx, i) {
        final u = users[i];
        final isInv = u.role == 'invigilator';
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isInv
                  ? const Color(0xFF007A87).withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.15),
              child: Icon(
                isInv ? Icons.badge_outlined : Icons.person_outline,
                color: isInv ? const Color(0xFF007A87) : Colors.grey,
              ),
            ),
            title: Text(u.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              'Role: ${u.role.toUpperCase()} • ID: ${u.invigilatorId}\n'
              'Platform: ${u.platform} • Lang: ${u.locale.toUpperCase()} • Last: ${u.lastActive != null ? DateFormat('dd MMM, HH:mm').format(u.lastActive!) : '-'}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${u.chatCount} chats',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12)),
                Text('${u.messageCount} msgs',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChatterSummary {
  final String name;
  final String role;
  final String invigilatorId;
  int chatCount;
  int messageCount;
  DateTime? lastActive;
  final String locale;
  final String platform;

  _ChatterSummary({
    required this.name,
    required this.role,
    required this.invigilatorId,
    required this.chatCount,
    required this.messageCount,
    required this.lastActive,
    required this.locale,
    required this.platform,
  });
}
