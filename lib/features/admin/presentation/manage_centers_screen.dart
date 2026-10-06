import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:duty_desk/l10n/app_localizations.dart';
import '../providers/center_provider.dart';
import '../../centers/providers/center_hierarchy_provider.dart';

class ManageCentersScreen extends ConsumerWidget {
  const ManageCentersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final centers = ref.watch(centerProvider);
    final allRooms = ref.watch(roomProvider);
    final allReadiness = ref.watch(centerReadinessProvider);
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
                final rooms = allRooms.where((r) => r.centerId == center.id).toList();
                final totalComputers = rooms.fold<int>(0, (sum, r) => sum + r.computerCount);
                final centerReadiness = allReadiness.where((r) => r.centerId == center.id).toList();
                final isReady = centerReadiness.isNotEmpty && centerReadiness.first.isFullyCompliant;

                return Card(
                  margin: const EdgeInsets.only(bottom: 14.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 1.5,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      context.push('/admin_dashboard/manage_centers/details/${center.id}');
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                child: const Icon(Icons.business_rounded, color: Color(0xFF007A87)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      center.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${center.location} • ${s.capacityLabel(center.capacity)}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                                    tooltip: 'Edit Center',
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () {
                                      context.push('/admin_dashboard/manage_centers/edit', extra: center);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    tooltip: 'Delete Center',
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () {
                                      _showDeleteDialog(context, ref, center.id, center.name);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              // GPS Badge
                              if (center.latitude != null && center.longitude != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.green.withValues(alpha: 0.4), width: 0.8),
                                  ),
                                  child: Text(
                                    'GPS Geofence: ${center.allowedRadiusMeters}m',
                                    style: const TextStyle(fontSize: 10.5, color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    s.noGpsGeofenceConfigured,
                                    style: const TextStyle(fontSize: 10.5, color: Colors.orange, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              // Rooms Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF007A87).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${rooms.length} Rooms configured',
                                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF007A87), fontWeight: FontWeight.bold),
                                ),
                              ),
                              // CBT PCs Badge
                              if (totalComputers > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '$totalComputers CBT PCs',
                                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
                                  ),
                                ),
                              // Readiness Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isReady ? Colors.green.withValues(alpha: 0.1) : Colors.amber.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isReady ? Icons.check_circle : Icons.warning_amber_rounded,
                                      size: 12,
                                      color: isReady ? Colors.green.shade700 : Colors.amber.shade900,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      centerReadiness.isNotEmpty
                                          ? (isReady ? 'Readiness 100%' : 'Readiness ${centerReadiness.first.completionPercentage.toInt()}%')
                                          : 'Audit Pending',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: isReady ? Colors.green.shade800 : Colors.amber.shade900,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.layers_outlined, size: 16),
                                label: const Text('Rooms, Floors & Readiness Audit →', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                style: TextButton.styleFrom(foregroundColor: const Color(0xFF007A87)),
                                onPressed: () {
                                  context.push('/admin_dashboard/manage_centers/details/${center.id}');
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
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
