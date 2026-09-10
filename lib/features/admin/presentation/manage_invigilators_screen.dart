import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:duty_desk/l10n/app_localizations.dart';
import '../providers/invigilator_provider.dart';

class ManageInvigilatorsScreen extends ConsumerStatefulWidget {
  const ManageInvigilatorsScreen({super.key});

  @override
  ConsumerState<ManageInvigilatorsScreen> createState() => _ManageInvigilatorsScreenState();
}

class _ManageInvigilatorsScreenState extends ConsumerState<ManageInvigilatorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showBulkImportModal(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.file_upload_outlined, color: Color(0xFF007A87), size: 28),
                const SizedBox(width: 8),
                Text('${s.addStaff} (${s.exportExcel})', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Copy rows directly from your Excel sheet and paste them below.\nExpected column order:\nName | Mobile | Resource ID | Email | Address',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'Rajnish Sinh\t9876543210\tRS1024\trajnish@email.com\tHall A Road\nJane Smith\t9876543211\tRS1025\tjane@email.com\tHall B Lane',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                fillColor: Colors.grey[50],
                filled: true,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final text = textController.text.trim();
                if (text.isEmpty) return;

                int count = 0;
                final lines = text.split('\n');
                for (final line in lines) {
                  final cols = line.split('\t');
                  if (cols.length >= 3) {
                    final name = cols[0].trim();
                    final mobile = cols[1].trim();
                    final resourceId = cols[2].trim();
                    final email = cols.length > 3 ? cols[3].trim() : '';
                    final address = cols.length > 4 ? cols[4].trim() : '';

                    if (name.isNotEmpty && mobile.isNotEmpty && resourceId.isNotEmpty) {
                      await ref.read(invigilatorProvider.notifier).addInvigilator(
                            name,
                            mobile,
                            resourceId,
                            email,
                            address,
                          );
                      count++;
                    }
                  }
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Successfully imported $count staff members!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF007A87),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(s.save, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final invigilators = ref.watch(invigilatorProvider);

    // Dynamic search filtering by Name, Mobile Number, or Resource Number
    final filteredStaff = invigilators.where((inv) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final matchesName = inv.name.toLowerCase().contains(q);
      final matchesMobile = inv.mobile.toLowerCase().contains(q);
      final matchesResource = inv.resourceId.toLowerCase().contains(q);
      return matchesName || matchesMobile || matchesResource;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.manageStaff),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.blue),
            tooltip: s.availabilityCalendar,
            onPressed: () {
              context.push('/admin_dashboard/manage_invigilators/availability');
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined, color: Color(0xFF007A87)),
            tooltip: s.exportExcel,
            onPressed: () => _showBulkImportModal(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Dynamic Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '${s.searchStaff}...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF007A87)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                ),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.trim());
              },
            ),
          ),

          // Count indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredStaff.length} / ${invigilators.length} ${s.staff}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
                if (_searchQuery.isNotEmpty)
                  Text(
                    'Filter: "$_searchQuery"',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF007A87), fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),

          // Staff List
          Expanded(
            child: filteredStaff.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? s.noResultsFound
                              : s.noInvigilatorsFound,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: filteredStaff.length,
                    itemBuilder: (context, index) {
                      final inv = filteredStaff[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: InkWell(
                          onTap: () {
                            context.push('/admin_dashboard/manage_invigilators/profile/${inv.id}');
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Row: Avatar + Full Name + Active/Blocked Badge
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: inv.isActive
                                          ? const Color(0xFF007A87).withValues(alpha: 0.12)
                                          : Colors.red.withValues(alpha: 0.12),
                                      child: Text(
                                        inv.name.isNotEmpty
                                            ? inv.name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join('').toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          color: inv.isActive ? const Color(0xFF007A87) : Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        inv.name, // COMPLETE FULL NAME
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: inv.isActive
                                            ? Colors.green.withValues(alpha: 0.12)
                                            : Colors.red.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        inv.isActive ? s.active : s.blocked,
                                        style: TextStyle(
                                          color: inv.isActive ? Colors.green.shade800 : Colors.red.shade800,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 10),

                                // Middle Row: Resource ID & Mobile Number
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(Icons.badge_outlined, size: 14, color: Colors.grey),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              'ID: ${inv.resourceId}',
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              inv.mobile,
                                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Bottom Row: Active switch and Actions
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          inv.isActive ? '${s.status}: ${s.active}' : '${s.status}: ${s.blocked}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: inv.isActive ? Colors.green.shade700 : Colors.red.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Transform.scale(
                                          scale: 0.75,
                                          child: Switch(
                                            value: inv.isActive,
                                            activeThumbColor: Colors.green,
                                            inactiveThumbColor: Colors.red,
                                            onChanged: (val) {
                                              ref.read(invigilatorProvider.notifier).toggleInvigilatorActiveStatus(inv.id, val);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(val ? '${inv.name} (${s.active})' : '${inv.name} (${s.blocked})'),
                                                  backgroundColor: val ? Colors.green : Colors.red,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                                          tooltip: s.editStaff,
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () {
                                            context.push('/admin_dashboard/manage_invigilators/edit', extra: inv);
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                          tooltip: s.deleteStaff,
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () {
                                            _showDeleteDialog(context, ref, inv.id, inv.name);
                                          },
                                        ),
                                      ],
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/admin_dashboard/manage_invigilators/add');
        },
        backgroundColor: const Color(0xFF007A87),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: Text(s.addStaff),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, String id, String name) {
    final s = S.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteInvigilator),
        content: Text(s.deleteInvigilatorConfirm(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(invigilatorProvider.notifier).deleteInvigilator(id);
              Navigator.pop(ctx);
            },
            child: Text(s.delete),
          ),
        ],
      ),
    );
  }
}
