import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/chatbot_admin_provider.dart';
import '../conversation_detail_screen.dart';

class ConversationsTab extends ConsumerStatefulWidget {
  final bool isReadOnly;

  const ConversationsTab({super.key, this.isReadOnly = false});

  @override
  ConsumerState<ConversationsTab> createState() => _ConversationsTabState();
}

class _ConversationsTabState extends ConsumerState<ConversationsTab> {
  String _surfaceFilter = 'all';
  String _localeFilter = 'all';
  bool _flaggedOnly = false;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(chatbotSessionsProvider);

    final filtered = sessions.where((s) {
      if (_surfaceFilter != 'all' && s.surface != _surfaceFilter) return false;
      if (_localeFilter != 'all' && s.locale != _localeFilter) return false;
      if (_flaggedOnly && !s.flagged) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final matchName = (s.userName ?? '').toLowerCase().contains(q);
        final matchId = (s.userId ?? s.id).toLowerCase().contains(q);
        if (!matchName && !matchId) return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search by user name or session ID...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  DropdownButton<String>(
                    value: _surfaceFilter,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Surfaces')),
                      DropdownMenuItem(value: 'landing', child: Text('Landing')),
                      DropdownMenuItem(value: 'invigilator', child: Text('Invigilator')),
                    ],
                    onChanged: (v) => setState(() => _surfaceFilter = v ?? 'all'),
                  ),
                  DropdownButton<String>(
                    value: _localeFilter,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Languages')),
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                      DropdownMenuItem(value: 'gu', child: Text('Gujarati')),
                    ],
                    onChanged: (v) => setState(() => _localeFilter = v ?? 'all'),
                  ),
                  FilterChip(
                    label: const Text('Flagged Only'),
                    selected: _flaggedOnly,
                    onSelected: (v) => setState(() => _flaggedOnly = v),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text('No conversations match the current filters.',
                      style: TextStyle(color: Colors.grey)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final s = filtered[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: Icon(
                          s.flagged
                              ? Icons.flag_rounded
                              : Icons.chat_bubble_outline_rounded,
                          color: s.flagged ? Colors.red : const Color(0xFF007A87),
                        ),
                        title: Text(
                          s.userType == 'invigilator'
                              ? '${s.userName ?? "Invigilator"} (${s.userId ?? "-"})'
                              : 'Visitor (${s.id.substring(0, s.id.length > 10 ? 10 : s.id.length)})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          '${s.surface.toUpperCase()} • ${s.locale.toUpperCase()} • ${s.messageCount} msgs • ${s.platform}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              s.lastMessageAt != null
                                  ? DateFormat('dd MMM, HH:mm').format(s.lastMessageAt!)
                                  : '',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            const Icon(Icons.chevron_right, size: 18),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ConversationDetailScreen(
                                session: s,
                                isReadOnly: widget.isReadOnly,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
