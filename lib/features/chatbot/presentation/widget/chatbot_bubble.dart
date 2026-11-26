import 'package:flutter/material.dart';
import 'package:duty_desk/l10n/app_localizations.dart';
import '../../models/chatbot_message.dart';
import '../../models/chatbot_settings.dart';
import 'chatbot_source_chip.dart';

class ChatbotBubble extends StatelessWidget {
  final ChatbotMessage message;
  final HandoffContact handoffContact;
  final Future<void> Function(String value, String? comment) onFeedback;

  const ChatbotBubble({
    super.key,
    required this.message,
    required this.handoffContact,
    required this.onFeedback,
  });

  void _showFeedbackCommentDialog(BuildContext context, String value) {
    final s = S.of(context);
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          value == 'up' ? '👍 ${s?.chatbotHelpful ?? "Feedback"}' : '👎 ${s?.chatbotHelpful ?? "Feedback"}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: s?.chatbotFeedbackCommentHint ?? 'Optional comment...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onFeedback(value, null);
            },
            child: const Text('Skip'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007A87),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final comment = ctrl.text.trim();
              Navigator.pop(ctx);
              onFeedback(value, comment.isEmpty ? null : comment);
            },
            child: Text(s?.chatbotSend ?? 'Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const brandColor = Color(0xFF007A87);
    final isUser = message.isUser;

    final bubbleColor = isUser
        ? brandColor
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9));
    final textColor = isUser
        ? Colors.white
        : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A));

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 14),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              message.text,
              style: TextStyle(
                color: textColor,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),

            // Sources under assistant messages
            if (!isUser && message.sources.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                s?.chatbotSources ?? 'Sources',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 5,
                children: message.sources
                    .map((src) => ChatbotSourceChip(source: src))
                    .toList(),
              ),
            ],

            // Handoff contact when unanswered
            if (!isUser && !message.answered && handoffContact.hasAny) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade400, width: 0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s?.chatbotNeedMoreHelp ?? 'Need human assistance?',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (handoffContact.phone.isNotEmpty)
                      Text('📞 ${handoffContact.phone}',
                          style: const TextStyle(fontSize: 11)),
                    if (handoffContact.whatsapp.isNotEmpty)
                      Text('💬 WhatsApp: ${handoffContact.whatsapp}',
                          style: const TextStyle(fontSize: 11)),
                    if (handoffContact.email.isNotEmpty)
                      Text('✉️ ${handoffContact.email}',
                          style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            ],

            // Thumbs Up / Down feedback bar
            if (!isUser && message.id.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      message.feedback?.value == 'up'
                          ? Icons.thumb_up_rounded
                          : Icons.thumb_up_outlined,
                      size: 14,
                      color: message.feedback?.value == 'up'
                          ? Colors.green
                          : Colors.grey,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                    tooltip: 'Helpful',
                    onPressed: () => _showFeedbackCommentDialog(context, 'up'),
                  ),
                  IconButton(
                    icon: Icon(
                      message.feedback?.value == 'down'
                          ? Icons.thumb_down_rounded
                          : Icons.thumb_down_outlined,
                      size: 14,
                      color: message.feedback?.value == 'down'
                          ? Colors.red
                          : Colors.grey,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                    tooltip: 'Not helpful',
                    onPressed: () => _showFeedbackCommentDialog(context, 'down'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
