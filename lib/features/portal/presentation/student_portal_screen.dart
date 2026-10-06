import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Read-only examination information for parent/student portal
class PublicExamInfo {
  final String examName;
  final String date;
  final String session;      // 'Morning', 'Afternoon'
  final String time;         // '10:00 AM - 1:00 PM'
  final String centerName;
  final String centerAddress;
  final String room;
  final String seatNumber;
  final String subject;
  final String subjectCode;
  final String status;       // 'upcoming', 'in_progress', 'completed'

  const PublicExamInfo({
    required this.examName,
    required this.date,
    required this.session,
    required this.time,
    required this.centerName,
    required this.centerAddress,
    required this.room,
    required this.seatNumber,
    required this.subject,
    required this.subjectCode,
    required this.status,
  });
}

/// Sample data provider — in production, replace with student-auth-gated Firestore queries
final publicExamProvider = Provider<List<PublicExamInfo>>((ref) {
  return [
    PublicExamInfo(
      examName: 'B.Tech Sem-6 End Term 2026',
      date: DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 2))),
      session: 'Morning',
      time: '10:00 AM – 1:00 PM',
      centerName: 'Main Examination Hall',
      centerAddress: 'Block A, Ground Floor, University Campus',
      room: 'Room 201',
      seatNumber: 'A-14',
      subject: 'Data Structures & Algorithms',
      subjectCode: 'CS-301',
      status: 'upcoming',
    ),
    PublicExamInfo(
      examName: 'B.Tech Sem-6 End Term 2026',
      date: DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 5))),
      session: 'Afternoon',
      time: '2:00 PM – 5:00 PM',
      centerName: 'Science Complex',
      centerAddress: 'Block C, First Floor, Science Wing',
      room: 'Lab 3',
      seatNumber: 'B-07',
      subject: 'Database Management Systems',
      subjectCode: 'CS-305',
      status: 'upcoming',
    ),
    PublicExamInfo(
      examName: 'B.Tech Sem-6 End Term 2026',
      date: DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1))),
      session: 'Morning',
      time: '10:00 AM – 1:00 PM',
      centerName: 'Engineering Campus',
      centerAddress: 'Block B, Second Floor, Eng Wing',
      room: 'Room 105',
      seatNumber: 'A-22',
      subject: 'Operating Systems',
      subjectCode: 'CS-303',
      status: 'completed',
    ),
  ];
});

class StudentPortalScreen extends ConsumerStatefulWidget {
  const StudentPortalScreen({super.key});

  @override
  ConsumerState<StudentPortalScreen> createState() => _StudentPortalScreenState();
}

class _StudentPortalScreenState extends ConsumerState<StudentPortalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final exams = ref.watch(publicExamProvider);
    final upcoming = exams.where((e) => e.status == 'upcoming').toList();
    final completed = exams.where((e) => e.status == 'completed').toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Examination Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
            Text('Student & Parent Read-Only Access', style: TextStyle(fontSize: 11, color: subtitleColor)),
          ],
        ),
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF007A87),
          labelColor: const Color(0xFF007A87),
          unselectedLabelColor: subtitleColor,
          labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 12.5),
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Guidelines'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: UPCOMING EXAMS
          _buildExamList(upcoming, cardBg, borderColor, textColor, subtitleColor, isDark, isEmpty: upcoming.isEmpty, emptyMsg: 'No upcoming examinations scheduled.'),

          // TAB 2: COMPLETED EXAMS
          _buildExamList(completed, cardBg, borderColor, textColor, subtitleColor, isDark, isEmpty: completed.isEmpty, emptyMsg: 'No completed examinations yet.'),

          // TAB 3: GUIDELINES
          _buildGuidelinesTab(cardBg, borderColor, textColor, subtitleColor, isDark),
        ],
      ),
    );
  }

  Widget _buildExamList(List<PublicExamInfo> exams, Color cardBg, Color borderColor, Color textColor, Color subtitleColor, bool isDark, {required bool isEmpty, required String emptyMsg}) {
    if (isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available_rounded, size: 56, color: Colors.grey.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(emptyMsg, style: TextStyle(color: subtitleColor, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: exams.length,
      itemBuilder: (context, index) {
        final exam = exams[index];
        final isUpcoming = exam.status == 'upcoming';
        final accentColor = isUpcoming ? const Color(0xFF007A87) : const Color(0xFF059669);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              // HEADER
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor.withValues(alpha: 0.12), accentColor.withValues(alpha: 0.04)],
                  ),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                      child: Icon(isUpcoming ? Icons.event_note_rounded : Icons.check_circle_rounded, color: accentColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(exam.subject, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                          const SizedBox(height: 2),
                          Text('${exam.subjectCode} • ${exam.examName}', style: TextStyle(fontSize: 11, color: subtitleColor)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        isUpcoming ? 'UPCOMING' : 'COMPLETED',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: accentColor),
                      ),
                    ),
                  ],
                ),
              ),

              // DETAILS GRID
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _detailRow(Icons.calendar_today_rounded, 'Date', _formatDate(exam.date), textColor, subtitleColor),
                    _detailRow(Icons.access_time_rounded, 'Session', '${exam.session} — ${exam.time}', textColor, subtitleColor),
                    _detailRow(Icons.location_city_rounded, 'Center', exam.centerName, textColor, subtitleColor),
                    _detailRow(Icons.map_rounded, 'Address', exam.centerAddress, textColor, subtitleColor),
                    _detailRow(Icons.meeting_room_rounded, 'Room', exam.room, textColor, subtitleColor),
                    _detailRow(Icons.event_seat_rounded, 'Seat Number', exam.seatNumber, textColor, subtitleColor),
                  ],
                ),
              ),

              // IMPORTANT NOTE
              if (isUpcoming)
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Report 30 minutes before exam time. Carry your hall ticket and valid photo ID.',
                          style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFFF59E0B) : const Color(0xFFB45309), height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGuidelinesTab(Color cardBg, Color borderColor, Color textColor, Color subtitleColor, bool isDark) {
    final guidelines = [
      _GuidelineItem(
        icon: Icons.badge_rounded,
        title: 'Identity Verification',
        desc: 'Carry your original hall ticket and a valid government-issued photo ID (Aadhaar, Voter ID, Passport, or PAN card).',
        color: const Color(0xFF007A87),
      ),
      _GuidelineItem(
        icon: Icons.access_time_filled_rounded,
        title: 'Reporting Time',
        desc: 'Report at the examination center at least 30 minutes before the scheduled start time. Gates close 15 minutes before the exam.',
        color: const Color(0xFF6366F1),
      ),
      _GuidelineItem(
        icon: Icons.phone_disabled_rounded,
        title: 'Electronic Devices',
        desc: 'Mobile phones, smartwatches, Bluetooth devices, and any electronic gadgets are strictly prohibited inside the exam hall.',
        color: const Color(0xFFDC2626),
      ),
      _GuidelineItem(
        icon: Icons.edit_rounded,
        title: 'Permitted Materials',
        desc: 'Only blue/black ballpoint pens, pencils, erasers, sharpeners, and transparent water bottles are allowed unless otherwise specified.',
        color: const Color(0xFF059669),
      ),
      _GuidelineItem(
        icon: Icons.assignment_rounded,
        title: 'Answer Sheet Protocol',
        desc: 'Write your roll number and subject code clearly on the OMR sheet. Do not write anything on the question paper unless instructed.',
        color: const Color(0xFFB45309),
      ),
      _GuidelineItem(
        icon: Icons.warning_rounded,
        title: 'Malpractice Policy',
        desc: 'Any form of cheating or possession of unauthorized material will lead to immediate cancellation and disciplinary action.',
        color: const Color(0xFFDC2626),
      ),
      _GuidelineItem(
        icon: Icons.medical_services_rounded,
        title: 'Medical Emergencies',
        desc: 'If you feel unwell during the exam, raise your hand. The invigilator will assist you. First-aid is available at every center.',
        color: const Color(0xFF0284C7),
      ),
      _GuidelineItem(
        icon: Icons.support_agent_rounded,
        title: 'Helpline',
        desc: 'For queries, contact the Exam Cell helpline: 1800-XXX-XXXX (toll-free) or email: examcell@university.edu',
        color: const Color(0xFF7C3AED),
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: guidelines.length,
      itemBuilder: (context, index) {
        final g = guidelines[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: g.color.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: g.color.withValues(alpha: 0.3)),
                ),
                child: Icon(g.icon, color: g.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                    const SizedBox(height: 4),
                    Text(g.desc, style: TextStyle(fontSize: 12, color: subtitleColor, height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color textColor, Color subtitleColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: subtitleColor),
          const SizedBox(width: 10),
          SizedBox(width: 80, child: Text(label, style: TextStyle(fontSize: 11.5, color: subtitleColor, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textColor))),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEEE, d MMMM yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }
}

class _GuidelineItem {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;

  const _GuidelineItem({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
  });
}
