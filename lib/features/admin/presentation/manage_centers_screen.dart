import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/center_provider.dart';

class ManageCentersScreen extends ConsumerWidget {
  const ManageCentersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final centers = ref.watch(centerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Centers'),
      ),
      body: centers.isEmpty
          ? const Center(child: Text('No centers found. Add one!'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: centers.length,
              itemBuilder: (context, index) {
                final center = centers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: const Icon(Icons.business),
                    ),
                    title: Text(center.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${center.location}\nCapacity: ${center.capacity}'),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            context.push('/admin_dashboard/manage_centers/edit', extra: center);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _showDeleteDialog(context, ref, center.id, center.name);
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
          context.push('/admin_dashboard/manage_centers/add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Center'),
        content: Text('Are you sure you want to delete $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(centerProvider.notifier).deleteCenter(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
