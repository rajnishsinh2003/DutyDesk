import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:duty_desk/l10n/app_localizations.dart';
import '../../providers/chatbot_widget_provider.dart';
import 'chatbot_bubble.dart';

class ChatbotPanel extends ConsumerStatefulWidget {
  final String surface; // 'landing' | 'invigilator'
  final String? userId;
  final String? userName;
  final VoidCallback onClose;

  const ChatbotPanel({
    super.key,
    required this.surface,
    this.userId,
    this.userName,
    required this.onClose,
  });

  @override
  ConsumerState<ChatbotPanel> createState() => _ChatbotPanelState();
}

class _ChatbotPanelState extends ConsumerState<ChatbotPanel> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    final locale = Localizations.localeOf(context).languageCode;
    final provider = widget.surface == 'invigilator'
        ? invigilatorChatProvider
        : landingChatProvider;
    _inputCtrl.clear();
    await ref.read(provider.notifier).sendMessage(
          text: text,
          locale: locale,
          userId: widget.userId,
          userName: widget.userName,
        );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const brandColor = Color(0xFF007A87);

    final settings = ref.watch(chatbotSettingsProvider);
    final provider = widget.surface == 'invigilator'
        ? invigilatorChatProvider
        : landingChatProvider;
    final chatState = ref.watch(provider);

    final bg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final headerBg = brandColor;
    final suggestions = settings.suggestionsFor(widget.surface, locale);

    if (chatState.messages.isNotEmpty) {
      _scrollToBottom();
    }

    return Material(
      color: bg,
      elevation: 12,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: headerBg,
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.botName.isNotEmpty
                            ? settings.botName
                            : (s?.chatbotTitle ?? 'DutyDesk AI Assistant'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.surface == 'invigilator'
                            ? 'Invigilator Support'
                            : 'Public Help Desk',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white, size: 20),
                  tooltip: s?.chatbotClearChat ?? 'Clear chat',
                  onPressed: () => ref.read(provider.notifier).clearChat(),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),

          // Pinned Announcement
          if (settings.pinnedAnnouncement.trim().isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              color: Colors.amber.withValues(alpha: 0.14),
              child: Row(
                children: [
                  const Icon(Icons.campaign_rounded, size: 16, color: Colors.amber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      settings.pinnedAnnouncement,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Consent gate on first open
          if (!chatState.consentGiven)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: brandColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.privacy_tip_outlined, color: brandColor, size: 36),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      s?.chatbotConsentTitle ?? 'Privacy & AI Notice',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s?.chatbotConsentBody ??
                          'Your questions are processed by DutyDesk AI using official examination documents. Do not share sensitive passwords or personal IDs.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => ref.read(provider.notifier).acceptConsent(),
                        child: Text(
                          s?.chatbotConsentAccept ?? 'Accept & Start Chat',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Messages List
            Expanded(
              child: ListView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(12),
                children: [
                  // Welcome Message bubble
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: brandColor.withValues(alpha: isDark ? 0.16 : 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: brandColor.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      settings.welcomeForLocale(locale),
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),

                  // Suggested question chips when chat is empty
                  if (chatState.messages.isEmpty && suggestions.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: suggestions.map((q) {
                        return ActionChip(
                          label: Text(q, style: const TextStyle(fontSize: 11.5)),
                          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                          side: BorderSide(color: brandColor.withValues(alpha: 0.35)),
                          onPressed: chatState.isSending ? null : () => _send(q),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Conversation bubbles
                  for (final msg in chatState.messages)
                    ChatbotBubble(
                      message: msg,
                      handoffContact: settings.handoffContact,
                      onFeedback: (val, comment) async {
                        await ref.read(provider.notifier).submitFeedback(
                              messageId: msg.id,
                              value: val,
                              comment: comment,
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(s?.chatbotFeedbackThanks ?? 'Thanks for your feedback!'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),

                  // Typing indicator
                  if (chatState.isSending)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: brandColor),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              s?.chatbotTyping ?? 'Thinking...',
                              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Error banner
                  if (chatState.errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Text(
                        chatState.errorMessage!,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),

            // Input bar
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      enabled: !chatState.isSending,
                      maxLength: settings.maxInputLength,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (val) {
                        if (!chatState.isSending && val.trim().isNotEmpty) {
                          _send(val);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: s?.chatbotAskHint ?? 'Ask a question...',
                        counterText: '',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: brandColor),
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    onPressed: chatState.isSending
                        ? null
                        : () {
                            if (_inputCtrl.text.trim().isNotEmpty) {
                              _send(_inputCtrl.text);
                            }
                          },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
