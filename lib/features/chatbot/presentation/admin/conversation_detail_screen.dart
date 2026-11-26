import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/chatbot_message.dart';
import '../../models/chatbot_session.dart';
import '../../providers/chatbot_admin_provider.dart';
import '../../services/chatbot_api_service.dart';

class ConversationDetailScreen extends StatefulWidget {
  final ChatbotSession session;
  final bool isReadOnly;

  const ConversationDetailScreen({
    super.key,
    required this.session,
    this.isReadOnly = false,
  });

  @override
  State<ConversationDetailScreen> createState() =>
      _ConversationDetailScreenState();
}

class _ConversationDetailScreenState extends State<ConversationDetailScreen> {
  late bool _flagged;

  @override
  void initState() {
    super.initState();
    _flagged = widget.session.flagged;
  }

  Future<void> _toggleFlag() async {
    final next = !_flagged;
    setState(() => _flagged = next);
    await ChatbotApiService.flagSession(
      sessionId: widget.session.id,
      flagged: next,
    );
  }

  void _exportCsv(List<ChatbotMessage> msgs) {
    final buf = StringBuffer();
    buf.writeln('Timestamp,Role,Text,Answered,Confidence,Model,LatencyMs,TokensIn,TokensOut,Feedback,AdminReview');
    for (final m in msgs) {
      final ts = m.createdAt != null
          ? DateFormat('yyyy-MM-dd HH:mm:ss').format(m.createdAt!)
          : '';
      final escapedText = '"${m.text.replaceAll('"', '""')}"';
      buf.writeln(
        '$ts,${m.role},$escapedText,${m.answered},${m.confidence},${m.model ?? ""},${m.latencyMs},${m.tokensIn},${m.tokensOut},${m.feedback?.value ?? ""},${m.adminReview?.status ?? ""}',
      );
    }
    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conversation CSV copied to clipboard!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _reviewMessage(
    ChatbotMessage assistantMsg,
    String? previousUserQuestion,
    String status,
  ) async {
    String? correctedAnswer;
    bool saveAsFaq = false;

    if (status == 'incorrect') {
      final ctrl = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDlg) => AlertDialog(
            title: const Text('Review & Correct Answer'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (previousUserQuestion != null)
                  Text('Question: $previousUserQuestion',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                const SizedBox(height: 10),
                TextField(
                  controller: ctrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Corrected Answer',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: saveAsFaq,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Save corrected answer as Approved FAQ',
                      style: TextStyle(fontSize: 13)),
                  onChanged: (v) => setDlg(() => saveAsFaq = v ?? false),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Submit Review')),
            ],
          ),
        ),
      );
      if (ok != true) return;
      correctedAnswer = ctrl.text.trim();
    }

    await ChatbotApiService.adminReviewMessage(
      sessionId: widget.session.id,
      messageId: assistantMsg.id,
      status: status,
      correctedAnswer: correctedAnswer,
      questionText: previousUserQuestion,
      saveAsFaq: saveAsFaq,
      audience: widget.session.surface == 'invigilator'
          ? ['invigilator']
          : ['public', 'invigilator'],
      language: widget.session.locale,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(saveAsFaq
              ? 'Reviewed & saved as new FAQ!'
              : 'Message marked as $status.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;

    return StreamBuilder<List<ChatbotMessage>>(
      stream: streamSessionMessages(s.id),
      builder: (context, snapshot) {
        final msgs = snapshot.data ?? [];

        return Scaffold(
          appBar: AppBar(
            title: Text(
              s.userName?.isNotEmpty == true
                  ? '${s.userName} (${s.surface})'
                  : 'Session ${s.id.substring(0, s.id.length > 10 ? 10 : s.id.length)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.download_rounded),
                tooltip: 'Export CSV',
                onPressed: msgs.isEmpty ? null : () => _exportCsv(msgs),
              ),
              if (!widget.isReadOnly)
                IconButton(
                  icon: Icon(
                    _flagged ? Icons.flag_rounded : Icons.outlined_flag_rounded,
                    color: _flagged ? Colors.red : null,
                  ),
                  tooltip: _flagged ? 'Unflag Session' : 'Flag Session',
                  onPressed: _toggleFlag,
                ),
            ],
          ),
          body: msgs.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: msgs.length,
                  itemBuilder: (ctx, i) {
                    final m = msgs[i];
                    final prevQuestion = i > 0 && msgs[i - 1].isUser
                        ? msgs[i - 1].text
                        : null;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: m.isUser
                          ? const Color(0xFF007A87).withValues(alpha: 0.08)
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  m.role.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: m.isUser
                                        ? const Color(0xFF007A87)
                                        : Colors.indigo,
                                  ),
                                ),
                                Text(
                                  m.createdAt != null
                                      ? DateFormat('dd MMM, HH:mm:ss')
                                          .format(m.createdAt!)
                                      : '',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SelectableText(m.text,
                                style: const TextStyle(fontSize: 13.5)),
                            if (m.isAssistant) ...[
                              const Divider(height: 18),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  _metaChip('Answered: ${m.answered}'),
                                  _metaChip('Conf: ${(m.confidence * 100).toStringAsFixed(0)}%'),
                                  if (m.model != null) _metaChip('Model: ${m.model}'),
                                  _metaChip('${m.latencyMs}ms'),
                                  _metaChip('Tokens: ${m.tokensIn}+${m.tokensOut}'),
                                ],
                              ),
                              if (m.sources.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Sources: ${m.sources.map((src) => "${src.title} (${(src.score * 100).toStringAsFixed(0)}%)").join(", ")}',
                                  style: const TextStyle(
                                      fontSize: 11.5, color: Colors.grey),
                                ),
                              ],
                              if (m.feedback != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    'User Feedback: ${m.feedback!.value.toUpperCase()} ${m.feedback!.comment.isNotEmpty ? "- \"${m.feedback!.comment}\"" : ""}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: m.feedback!.value == 'up'
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ),
                              if (m.adminReview != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    'Admin Review: ${m.adminReview!.status.toUpperCase()}'
                                    '${m.adminReview!.correctedAnswer.isNotEmpty ? " • Correction: ${m.adminReview!.correctedAnswer}" : ""}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.deepPurple,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              if (!widget.isReadOnly) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.check,
                                          size: 15, color: Colors.green),
                                      label: const Text('Mark Correct',
                                          style: TextStyle(fontSize: 12)),
                                      onPressed: () => _reviewMessage(
                                          m, prevQuestion, 'correct'),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.edit_note,
                                          size: 15, color: Colors.orange),
                                      label: const Text('Mark Incorrect / Fix',
                                          style: TextStyle(fontSize: 12)),
                                      onPressed: () => _reviewMessage(
                                          m, prevQuestion, 'incorrect'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _metaChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10.5)),
    );
  }
}
