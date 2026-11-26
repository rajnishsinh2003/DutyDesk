import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/chatbot_stats.dart';
import '../../../providers/chatbot_admin_provider.dart';

class OverviewTab extends ConsumerStatefulWidget {
  const OverviewTab({super.key});

  @override
  ConsumerState<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<OverviewTab> {
  int _windowDays = 7; // 1, 7, 30

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(chatbotStatsProvider);
    final unanswered = ref.watch(chatbotUnansweredProvider);
    final docs = ref.watch(chatbotDocumentsProvider);
    final sessions = ref.watch(chatbotSessionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const brandColor = Color(0xFF007A87);

    final filteredStats = stats.take(_windowDays).toList().reversed.toList();

    int totalConvs = 0;
    int totalMsgs = 0;
    int totalAnswered = 0;
    int totalUnanswered = 0;
    int totalUp = 0;
    int totalDown = 0;
    int totalTokens = 0;
    int totalLatency = 0;
    final surfaceMap = <String, int>{'landing': 0, 'invigilator': 0};
    final langMap = <String, int>{'en': 0, 'hi': 0, 'gu': 0};

    for (final s in filteredStats) {
      totalConvs += s.conversations;
      totalMsgs += s.messages;
      totalAnswered += s.answered;
      totalUnanswered += s.unanswered;
      totalUp += s.thumbsUp;
      totalDown += s.thumbsDown;
      totalTokens += s.tokens;
      totalLatency += s.totalLatencyMs;
      s.surfaces.forEach((k, v) => surfaceMap[k] = (surfaceMap[k] ?? 0) + v);
      s.languages.forEach((k, v) => langMap[k] = (langMap[k] ?? 0) + v);
    }

    final answeredPct =
        totalMsgs > 0 ? (totalAnswered / totalMsgs * 100).toStringAsFixed(1) : '0.0';
    final totalFeedback = totalUp + totalDown;
    final thumbsUpPct = totalFeedback > 0
        ? (totalUp / totalFeedback * 100).toStringAsFixed(1)
        : '—';
    final avgLatencyMs =
        totalAnswered > 0 ? (totalLatency / totalAnswered).round() : 0;
    // Approximate blended LLM cost (~$0.15 per 1M tokens for Flash / GPT-4o-mini)
    final estCostUsd = (totalTokens / 1000000.0 * 0.15).toStringAsFixed(4);
    final uniqueUsers = sessions
        .map((s) => s.userId ?? s.ownerUid)
        .where((e) => e.isNotEmpty)
        .toSet()
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time window filter chips
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Today'),
                selected: _windowDays == 1,
                onSelected: (_) => setState(() => _windowDays = 1),
              ),
              ChoiceChip(
                label: const Text('Last 7 Days'),
                selected: _windowDays == 7,
                onSelected: (_) => setState(() => _windowDays = 7),
              ),
              ChoiceChip(
                label: const Text('Last 30 Days'),
                selected: _windowDays == 30,
                onSelected: (_) => setState(() => _windowDays = 30),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // KPI Grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _kpiCard('Conversations', '$totalConvs', Icons.chat_outlined, brandColor, isDark),
              _kpiCard('Messages', '$totalMsgs', Icons.message_outlined, Colors.indigo, isDark),
              _kpiCard('Unique Users', '$uniqueUsers', Icons.people_outline, Colors.teal, isDark),
              _kpiCard('Answered %', '$answeredPct%', Icons.check_circle_outline, Colors.green, isDark),
              _kpiCard('Unanswered', '$totalUnanswered', Icons.help_outline, Colors.orange, isDark),
              _kpiCard('Thumbs Up %', thumbsUpPct == '—' ? '—' : '$thumbsUpPct%', Icons.thumb_up_outlined, Colors.blue, isDark),
              _kpiCard('Avg Latency', '${avgLatencyMs}ms', Icons.speed_rounded, Colors.purple, isDark),
              _kpiCard('Tokens / Est.', '$totalTokens (\$$estCostUsd)', Icons.token_outlined, Colors.deepOrange, isDark),
            ],
          ),
          const SizedBox(height: 20),

          // Trend Chart
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Message Volume (Answered vs Unanswered)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 170,
                    width: double.infinity,
                    child: filteredStats.isEmpty
                        ? const Center(
                            child: Text(
                              'No daily traffic recorded yet.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : CustomPaint(
                            painter: _TrendBarPainter(
                              stats: filteredStats,
                              isDark: isDark,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Surface & Language Splits
          LayoutBuilder(
            builder: (ctx, constraints) {
              final isWide = constraints.maxWidth > 700;
              final surfaceCard = _splitCard(
                'Per-Surface Split',
                [
                  _splitRow('Landing (Public)', surfaceMap['landing'] ?? 0, brandColor),
                  _splitRow('Invigilator Portal', surfaceMap['invigilator'] ?? 0, Colors.indigo),
                ],
              );
              final langCard = _splitCard(
                'Language Split',
                [
                  _splitRow('English (en)', langMap['en'] ?? 0, Colors.teal),
                  _splitRow('Hindi (hi)', langMap['hi'] ?? 0, Colors.orange),
                  _splitRow('Gujarati (gu)', langMap['gu'] ?? 0, Colors.purple),
                ],
              );
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: surfaceCard),
                    const SizedBox(width: 12),
                    Expanded(child: langCard),
                  ],
                );
              }
              return Column(
                children: [surfaceCard, const SizedBox(height: 12), langCard],
              );
            },
          ),
          const SizedBox(height: 16),

          // Top Unanswered / Frequent Questions & Knowledge Base Summary
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top 10 Frequent Unanswered Questions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  if (unanswered.isEmpty)
                    const Text('No unanswered questions logged.',
                        style: TextStyle(color: Colors.grey, fontSize: 13))
                  else
                    for (final item in unanswered.take(10))
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 13,
                          backgroundColor: Colors.orange.withValues(alpha: 0.15),
                          child: Text('${item.count}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange)),
                        ),
                        title: Text(item.question,
                            style: const TextStyle(fontSize: 13)),
                        trailing: Text(item.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: item.status == 'open'
                                  ? Colors.red
                                  : Colors.green,
                            )),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Knowledge Base Documents Ready',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  if (docs.isEmpty)
                    const Text('No documents uploaded yet.',
                        style: TextStyle(color: Colors.grey, fontSize: 13))
                  else
                    for (final doc in docs.where((d) => d.enabled).take(8))
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.description_outlined,
                            color: brandColor, size: 18),
                        title: Text(doc.title,
                            style: const TextStyle(fontSize: 13)),
                        subtitle: Text(
                            '${doc.category} • ${doc.chunkCount} chunks',
                            style: const TextStyle(fontSize: 11)),
                        trailing: Text(doc.audience.join(', '),
                            style: const TextStyle(fontSize: 11)),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _splitCard(String title, List<Widget> rows) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _splitRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 13)),
            ],
          ),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _TrendBarPainter extends CustomPainter {
  final List<ChatbotDailyStats> stats;
  final bool isDark;

  _TrendBarPainter({required this.stats, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (stats.isEmpty) return;
    final maxVal = stats
        .map((s) => s.messages)
        .fold<int>(1, (a, b) => a > b ? a : b);

    final barAreaWidth = size.width / stats.length;
    final barWidth = (barAreaWidth * 0.55).clamp(6.0, 28.0);
    final answeredPaint = Paint()..color = const Color(0xFF007A87);
    final unansweredPaint = Paint()..color = Colors.orange;
    final axisPaint = Paint()
      ..color = isDark ? Colors.white24 : Colors.grey.shade300
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(0, size.height - 20),
      Offset(size.width, size.height - 20),
      axisPaint,
    );

    final chartHeight = size.height - 26;

    for (var i = 0; i < stats.length; i++) {
      final s = stats[i];
      final x = i * barAreaWidth + (barAreaWidth - barWidth) / 2;
      final ansH = (s.answered / maxVal) * chartHeight;
      final unansH = (s.unanswered / maxVal) * chartHeight;

      // Answered bottom segment
      canvas.drawRect(
        Rect.fromLTWH(x, size.height - 20 - ansH, barWidth, ansH),
        answeredPaint,
      );
      // Unanswered stacked segment
      canvas.drawRect(
        Rect.fromLTWH(x, size.height - 20 - ansH - unansH, barWidth, unansH),
        unansweredPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrendBarPainter oldDelegate) =>
      oldDelegate.stats != stats;
}
