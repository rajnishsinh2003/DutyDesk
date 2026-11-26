import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/chatbot_widget_provider.dart';
import 'chatbot_panel.dart';

/// Responsive AI Chatbot Launcher.
/// - On wide web/tablet screens (>= 650px): opens a floating bottom-right panel.
/// - On mobile phones (< 650px): opens a full-height modal bottom sheet.
class ChatbotLauncher extends ConsumerWidget {
  final String surface; // 'landing' | 'invigilator'
  final String? userId;
  final String? userName;

  const ChatbotLauncher({
    super.key,
    required this.surface,
    this.userId,
    this.userName,
  });

  void _openChat(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final provider = surface == 'invigilator'
        ? invigilatorChatProvider
        : landingChatProvider;

    if (width < 650) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.85,
            child: ChatbotPanel(
              surface: surface,
              userId: userId,
              userName: userName,
              onClose: () => Navigator.of(ctx).pop(),
            ),
          ),
        ),
      );
    } else {
      final isOpen = ref.read(provider).isOpen;
      ref.read(provider.notifier).setOpen(!isOpen);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(chatbotSettingsProvider);
    final isEnabled = surface == 'invigilator'
        ? settings.invigilatorEnabled
        : settings.landingEnabled;

    if (!isEnabled) return const SizedBox.shrink();

    final provider = surface == 'invigilator'
        ? invigilatorChatProvider
        : landingChatProvider;
    final chatState = ref.watch(provider);
    final isWide = MediaQuery.of(context).size.width >= 650;
    const brandColor = Color(0xFF007A87);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (isWide && chatState.isOpen) ...[
          SizedBox(
            width: 390,
            height: 540,
            child: ChatbotPanel(
              surface: surface,
              userId: userId,
              userName: userName,
              onClose: () => ref.read(provider.notifier).setOpen(false),
            ),
          ),
          const SizedBox(height: 12),
        ],
        FloatingActionButton.extended(
          heroTag: 'chatbot_launcher_$surface',
          backgroundColor: brandColor,
          foregroundColor: Colors.white,
          elevation: 6,
          onPressed: () => _openChat(context, ref),
          icon: Icon(
            isWide && chatState.isOpen
                ? Icons.close_rounded
                : Icons.smart_toy_rounded,
          ),
          label: Text(
            isWide && chatState.isOpen ? 'Close' : 'Ask AI',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
