import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/auth_provider.dart';
import 'tabs/audit_log_tab.dart';
import 'tabs/conversations_tab.dart';
import 'tabs/knowledge_base_tab.dart';
import 'tabs/overview_tab.dart';
import 'tabs/settings_tab.dart';
import 'tabs/unanswered_tab.dart';
import 'tabs/users_tab.dart';

class ChatbotStudioScreen extends ConsumerWidget {
  const ChatbotStudioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final isAuditor = auth.role == UserRole.auditor;
    final isFinance = auth.role == UserRole.finance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const brandColor = Color(0xFF007A87);

    if (isFinance) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chatbot Studio')),
        body: const Center(
          child: Text('Access Denied: Chatbot Studio is restricted for Finance role.'),
        ),
      );
    }

    // Auditors have read-only access to Conversations only
    if (isAuditor) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('Chatbot Studio (Auditor Read-Only)'),
        ),
        body: const ConversationsTab(isReadOnly: true),
      );
    }

    return DefaultTabController(
      length: 7,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/admin_dashboard');
              }
            },
          ),
          title: const Row(
            children: [
              Icon(Icons.smart_toy_rounded, color: brandColor, size: 22),
              SizedBox(width: 8),
              Text(
                'Chatbot Studio',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: brandColor,
            labelColor: brandColor,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.analytics_outlined, size: 18), text: 'Overview'),
              Tab(icon: Icon(Icons.menu_book_outlined, size: 18), text: 'Knowledge Base'),
              Tab(icon: Icon(Icons.forum_outlined, size: 18), text: 'Conversations'),
              Tab(icon: Icon(Icons.people_outline, size: 18), text: 'Users'),
              Tab(icon: Icon(Icons.help_outline, size: 18), text: 'Unanswered'),
              Tab(icon: Icon(Icons.tune_rounded, size: 18), text: 'Messages & Settings'),
              Tab(icon: Icon(Icons.history_rounded, size: 18), text: 'Audit Log'),
            ],
          ),
        ),
        body: Column(
          children: [
            if (Firebase.apps.isNotEmpty &&
                (FirebaseAuth.instance.currentUser == null ||
                    FirebaseAuth.instance.currentUser!.isAnonymous))
              MaterialBanner(
                backgroundColor: Colors.amber.withValues(alpha: 0.16),
                leading: const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                content: const Text(
                  'Firebase Admin session not active (you may be using Demo Login or an anonymous session). Sign out and sign in with your admin email & password to save/read Chatbot Studio data.',
                  style: TextStyle(fontSize: 12),
                ),
                actions: [
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Go to Login'),
                  ),
                ],
              ),
            const Expanded(
              child: TabBarView(
                children: [
                  OverviewTab(),
                  KnowledgeBaseTab(),
                  ConversationsTab(isReadOnly: false),
                  UsersTab(),
                  UnansweredTab(),
                  SettingsTab(),
                  AuditLogTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
