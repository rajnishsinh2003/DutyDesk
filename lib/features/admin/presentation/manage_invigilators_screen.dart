import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/invigilator_provider.dart';

class ManageInvigilatorsScreen extends ConsumerWidget {
  const ManageInvigilatorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invigilators = ref.watch(invigilatorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Invigilators'),
      ),
      body: invigilators.isEmpty
          ? const Center(child: Text('No invigilators found.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: invigilators.length,
              itemBuilder: (context, index) {
                final inv = invigilators[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: const Icon(Icons.person),
                    ),
                    title: Text('${inv.name} (Res: ${inv.resourceId})', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Mobile: ${inv.mobile}\nMock Duties: ${inv.mockDutyCount}'),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            context.push('/admin_dashboard/manage_invigilators/edit', extra: inv);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _showDeleteDialog(context, ref, inv.id, inv.name);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/admin_dashboard/manage_invigilators/add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Invigilator'),
        content: Text('Are you sure you want to delete $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(invigilatorProvider.notifier).deleteInvigilator(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
