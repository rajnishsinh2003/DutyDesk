import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:duty_desk/l10n/app_localizations.dart';
import '../providers/center_provider.dart';

class ManageCentersScreen extends ConsumerWidget {
  const ManageCentersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final centers = ref.watch(centerProvider);
    final s = S.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.manageCenters),
      ),
      body: centers.isEmpty
          ? Center(child: Text(s.noCentersFound))
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
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${center.location} • ${s.capacityLabel(center.capacity)}'),
                        const SizedBox(height: 4),
                        if (center.latitude != null && center.longitude != null)
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.green.withValues(alpha: 0.4), width: 0.8),
                                ),
                                child: Text(
                                  'GPS: ${center.latitude!.toStringAsFixed(3)}, ${center.longitude!.toStringAsFixed(3)} (${center.allowedRadiusMeters}m)',
                                  style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  s.noGpsGeofenceConfigured,
                                  style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
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
    final s = S.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteCenter),
        content: Text(s.deleteCenterConfirm(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(centerProvider.notifier).deleteCenter(id);
              Navigator.pop(ctx);
            },
            child: Text(s.delete),
          ),
        ],
      ),
    );
  }
}
