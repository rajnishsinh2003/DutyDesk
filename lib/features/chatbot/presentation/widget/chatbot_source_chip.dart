import 'package:flutter/material.dart';
import '../../models/chatbot_message.dart';

class ChatbotSourceChip extends StatelessWidget {
  final ChatSource source;

  const ChatbotSourceChip({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const brandColor = Color(0xFF007A87);
    final pct = (source.score * 100).clamp(0, 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: brandColor.withValues(alpha: isDark ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: brandColor.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            source.title.startsWith('FAQ:')
                ? Icons.quiz_outlined
                : Icons.description_outlined,
            size: 12,
            color: isDark ? const Color(0xFF22D3EE) : brandColor,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '${source.title} ($pct%)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFBAE6FD) : brandColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
