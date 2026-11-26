import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duty_desk/features/chatbot/models/chatbot_message.dart';
import 'package:duty_desk/features/chatbot/models/chatbot_settings.dart';
import 'package:duty_desk/features/chatbot/presentation/widget/chatbot_bubble.dart';
import 'package:duty_desk/features/chatbot/presentation/widget/chatbot_panel.dart';

void main() {
  testWidgets('ChatbotPanel shows privacy consent notice before first chat',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ChatbotPanel(
              surface: 'landing',
              onClose: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Privacy & AI Notice'), findsOneWidget);
    expect(find.text('Accept & Start Chat'), findsOneWidget);
  });

  testWidgets('ChatbotBubble renders sources and handoff contact when unanswered',
      (WidgetTester tester) async {
    final msg = ChatbotMessage(
      id: 'm1',
      role: 'assistant',
      text: 'I could not find that in our documents.',
      answered: false,
      sources: const [
        ChatSource(
          docId: 'd1',
          title: 'Exam Guidelines 2026',
          chunkId: 'c1',
          score: 0.84,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatbotBubble(
            message: msg,
            handoffContact: const HandoffContact(
              phone: '+91-9999999999',
              email: 'support@dutydesk.com',
            ),
            onFeedback: (_, __) async {},
          ),
        ),
      ),
    );

    expect(find.text('Exam Guidelines 2026 (84%)'), findsOneWidget);
    expect(find.textContaining('+91-9999999999'), findsOneWidget);
    expect(find.textContaining('support@dutydesk.com'), findsOneWidget);
  });
}
