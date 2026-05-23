import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  final _dateController = TextEditingController();
  String? _selectedCenterId;
  bool _isCreating = false;

  @override
  void dispose() {
    _examNameController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _showCreateSessionModal() {
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
                  const Text(
                    'Create New Exam Session',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _examNameController,
                    decoration: const InputDecoration(labelText: 'Exam Name', prefixIcon: Icon(Icons.book)),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _dateController,
                    decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)', prefixIcon: Icon(Icons.calendar_today)),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Select Center', prefixIcon: Icon(Icons.business)),
                    initialValue: _selectedCenterId,
                    items: centers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (val) => setModalState(() => _selectedCenterId = val),
                    validator: (val) => val == null ? 'Required' : null,
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
                                    date: _dateController.text.trim(),
                                    centerId: center.id,
                                    centerName: center.name,
                                  );
                              setModalState(() => _isCreating = false);
                              if (context.mounted) {
                                _examNameController.clear();
                                _dateController.clear();
                                _selectedCenterId = null;
                                Navigator.pop(context);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: _isCreating ? const CircularProgressIndicator() : const Text('Create Session', style: TextStyle(fontSize: 16)),
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
    final sessions = ref.watch(examSessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Sessions'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSessionModal,
        icon: const Icon(Icons.add),
        label: const Text('New Session'),
      ),
      body: sessions.isEmpty
          ? const Center(child: Text('No Exam Sessions found. Create one to assign duties.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
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
                              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(session.date, style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                          const SizedBox(height: 4),
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
