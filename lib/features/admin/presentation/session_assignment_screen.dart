import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/exam_session_provider.dart';
import '../providers/invigilator_provider.dart';
import '../../invigilator/providers/duty_provider.dart';

class SessionAssignmentScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const SessionAssignmentScreen({super.key, required this.sessionId});

  @override
  ConsumerState<SessionAssignmentScreen> createState() => _SessionAssignmentScreenState();
}

class _SessionAssignmentScreenState extends ConsumerState<SessionAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _paymentController = TextEditingController(text: '₹500');
  String? _selectedInvigilatorId;
  String _selectedRole = 'inv';
  String _selectedShift = '1';
  String _selectedLunch = 'No';
  bool _isAllocating = false;

  @override
  void dispose() {
    _paymentController.dispose();
    super.dispose();
  }

  void _showAssignStaffModal(ExamSession session, List<Invigilator> invigilators) {
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
            return Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Assign Staff Member',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Select Staff', prefixIcon: Icon(Icons.person)),
                    initialValue: _selectedInvigilatorId,
                    isExpanded: true,
                    items: invigilators.map((inv) {
                      return DropdownMenuItem(
                        value: inv.id,
                        child: Text('${inv.name} (Res: ${inv.resourceId})'),
                      );
                    }).toList(),
                    onChanged: (val) => setModalState(() => _selectedInvigilatorId = val),
                    validator: (val) => val == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Role', prefixIcon: Icon(Icons.badge)),
                          initialValue: _selectedRole,
                          items: const [
                            DropdownMenuItem(value: 'inv', child: Text('Invigilator')),
                            DropdownMenuItem(value: 'ls', child: Text('Lab Staff')),
                            DropdownMenuItem(value: 'mtoe', child: Text('MTOE')),
                          ],
                          onChanged: (val) => setModalState(() => _selectedRole = val!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Shift', prefixIcon: Icon(Icons.schedule)),
                          initialValue: _selectedShift,
                          items: const [
                            DropdownMenuItem(value: '1', child: Text('Shift 1')),
                            DropdownMenuItem(value: '2', child: Text('Shift 2')),
                            DropdownMenuItem(value: '3', child: Text('Shift 3')),
                          ],
                          onChanged: (val) => setModalState(() => _selectedShift = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Lunch', prefixIcon: Icon(Icons.restaurant)),
                          initialValue: _selectedLunch,
                          items: const [
                            DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                            DropdownMenuItem(value: 'No', child: Text('No')),
                          ],
                          onChanged: (val) => setModalState(() => _selectedLunch = val!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _paymentController,
                          decoration: const InputDecoration(labelText: 'Payment', prefixIcon: Icon(Icons.currency_rupee)),
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isAllocating
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate() && _selectedInvigilatorId != null) {
                              setModalState(() => _isAllocating = true);
                              try {
                                await ref.read(dutyProvider.notifier).allocateDuty(
                                      date: session.date,
                                      examName: session.examName,
                                      centerName: session.centerName,
                                      invigilatorId: _selectedInvigilatorId!,
                                      role: _selectedRole,
                                      shift: _selectedShift,
                                      payment: _paymentController.text.trim(),
                                      lunch: _selectedLunch,
                                      sessionId: session.id,
                                    );
                                setModalState(() => _isAllocating = false);
                                if (context.mounted) {
                                  _selectedInvigilatorId = null;
                                  _paymentController.text = '₹500';
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Staff Assigned & Email Sent!'), backgroundColor: Colors.green),
                                  );
                                }
                              } catch (e) {
                                setModalState(() => _isAllocating = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: _isAllocating ? const CircularProgressIndicator() : const Text('Assign & Notify', style: TextStyle(fontSize: 16)),
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
    final invigilators = ref.watch(invigilatorProvider);
    final allDuties = ref.watch(globalDutyProvider);
    
    final session = sessions.firstWhere(
      (s) => s.id == widget.sessionId, 
      orElse: () => ExamSession(id: '', examName: 'Unknown', date: '', centerId: '', centerName: '')
    );

    final assignedDuties = allDuties.where((d) => d.sessionId == session.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Details'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAssignStaffModal(session, invigilators),
        icon: const Icon(Icons.person_add),
        label: const Text('Assign Staff'),
      ),
      body: session.id.isEmpty
          ? const Center(child: Text('Session not found'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Session Details Header
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(session.examName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          Text(session.date, style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.business, size: 16),
                          const SizedBox(width: 8),
                          Text(session.centerName, style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Assigned Staff List
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Assigned Staff (${assignedDuties.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: assignedDuties.isEmpty
                      ? const Center(child: Text('No staff assigned yet. Tap "Assign Staff" to begin.'))
                      : ListView.builder(
                          itemCount: assignedDuties.length,
                          itemBuilder: (context, index) {
                            final duty = assignedDuties[index];
                            final inv = invigilators.firstWhere(
                              (i) => i.id == duty.invigilatorId,
                              orElse: () => Invigilator(id: '', name: 'Unknown', resourceId: '', mobile: '', mockDutyCount: 0)
                            );
                            return ListTile(
                              leading: CircleAvatar(child: Text(inv.name.isNotEmpty ? inv.name[0] : '?')),
                              title: Text(inv.name),
                              subtitle: Text('Role: ${duty.role.toUpperCase()} • Shift: ${duty.shift} • Lunch: ${duty.lunch} • Pay: ${duty.payment}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  ref.read(dutyProvider.notifier).deleteDuty(duty.id);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
