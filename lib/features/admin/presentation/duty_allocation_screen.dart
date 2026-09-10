import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:duty_desk/l10n/app_localizations.dart';
import '../providers/exam_session_provider.dart';
import '../providers/center_provider.dart';

class DutyAllocationScreen extends ConsumerStatefulWidget {
  const DutyAllocationScreen({super.key});

  @override
  ConsumerState<DutyAllocationScreen> createState() => _DutyAllocationScreenState();
}

class _DutyAllocationScreenState extends ConsumerState<DutyAllocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _examNameController = TextEditingController();
  String? _selectedCenterId;
  bool _isCreating = false;

  @override
  void dispose() {
    _examNameController.dispose();
    super.dispose();
  }

  void _showCreateSessionModal() {
    final s = S.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            final centers = ref.watch(centerProvider);
            return Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    s.registerNewExam,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _examNameController,
                    decoration: InputDecoration(labelText: s.examName, prefixIcon: const Icon(Icons.book)),
                    validator: (val) => val == null || val.isEmpty ? s.required : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: s.selectCenter, prefixIcon: const Icon(Icons.business)),
                    initialValue: _selectedCenterId,
                    items: centers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (val) => setModalState(() => _selectedCenterId = val),
                    validator: (val) => val == null ? s.required : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isCreating
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate() && _selectedCenterId != null) {
                              setModalState(() => _isCreating = true);
                              final center = centers.firstWhere((c) => c.id == _selectedCenterId);
                              await ref.read(examSessionProvider.notifier).addSession(
                                    examName: _examNameController.text.trim(),
                                    date: '', // Created without a static date template
                                    centerId: center.id,
                                    centerName: center.name,
                                  );
                              setModalState(() => _isCreating = false);
                              if (context.mounted) {
                                _examNameController.clear();
                                _selectedCenterId = null;
                                Navigator.pop(context);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF007A87),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isCreating ? const CircularProgressIndicator(color: Colors.white) : Text(s.registerExam, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final sessions = ref.watch(examSessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.registeredExams),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSessionModal,
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF007A87),
        foregroundColor: Colors.white,
        label: Text(s.newExam),
      ),
      body: sessions.isEmpty
          ? Center(child: Text(s.noRegisteredExams))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.assignment, color: Theme.of(context).colorScheme.primary),
                    ),
                    title: Text(session.examName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.business, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(session.centerName, style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                        ],
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      context.push('/admin_dashboard/allocate_duty/session/${session.id}');
                    },
                  ),
                );
              },
            ),
    );
  }
}
