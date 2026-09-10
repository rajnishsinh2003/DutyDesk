import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:duty_desk/l10n/app_localizations.dart';
import '../providers/master_data_provider.dart';
import '../../../core/utils/month_filter_utils.dart';

class MaintainModuleListScreen extends ConsumerStatefulWidget {
  final String type;
  final String title;

  const MaintainModuleListScreen({super.key, required this.type, required this.title});

  @override
  ConsumerState<MaintainModuleListScreen> createState() => _MaintainModuleListScreenState();
}

class _MaintainModuleListScreenState extends ConsumerState<MaintainModuleListScreen> {
  String _searchQuery = '';
  int _selectedMonth = getCurrentMonth();

  void _showAddEditDialog(BuildContext context, {MasterRecord? existingRecord}) {
    final s = S.of(context)!;
    final nameCtrl = TextEditingController(text: existingRecord?.name ?? '');
    bool isActive = existingRecord?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(existingRecord == null ? '${s.addNew} ${widget.title}' : '${s.edit} ${widget.title}', style: const TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: s.name,
                    labelStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text('${s.status} (${s.active})', style: const TextStyle(color: Colors.white)),
                  value: isActive,
                  activeThumbColor: Colors.blue,
                  onChanged: (val) => setState(() => isActive = val),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(s.cancel, style: const TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;

                  if (existingRecord == null) {
                    await ref.read(masterDataProvider.notifier).addRecord(widget.type, name);
                  } else {
                    await ref.read(masterDataProvider.notifier).updateRecord(widget.type, existingRecord.id, name, isActive);
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text(s.save),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final state = ref.watch(masterDataProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark Theme
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddEditDialog(context),
      ),
      body: Stack(
        children: [
          // Background subtle gradients for glassmorphism effect
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withValues(alpha: 0.1),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  state.maybeWhen(
                    data: (data) {
                      final list = data[widget.type] ?? [];
                      final monthFiltered = list.where((item) {
                        if (item.createdAt == null) return true;
                        return item.createdAt!.month == _selectedMonth;
                      }).toList();
                      final filteredList = monthFiltered.where((item) => item.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                      return Row(
                        children: [
                          Expanded(
                            child: MonthFilterDropdown(
                              selectedMonth: _selectedMonth,
                              onChanged: (val) => setState(() => _selectedMonth = val),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            s.records(filteredList.length),
                            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      );
                    },
                    orElse: () => Row(
                      children: [
                        Expanded(
                          child: MonthFilterDropdown(
                            selectedMonth: _selectedMonth,
                            onChanged: (val) => setState(() => _selectedMonth = val),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '${s.search} ${widget.title}...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                        prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.6)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: state.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('${s.error}: $e', style: const TextStyle(color: Colors.red))),
                      data: (data) {
                        final list = data[widget.type] ?? [];
                        final monthFiltered = list.where((item) {
                          if (item.createdAt == null) return true;
                          return item.createdAt!.month == _selectedMonth;
                        }).toList();
                        final filteredList = monthFiltered.where((item) => item.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

                        if (filteredList.isEmpty) {
                          return Center(child: Text(s.noRecords, style: TextStyle(color: Colors.white.withValues(alpha: 0.5))));
                        }

                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final record = filteredList[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                title: Text(record.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  record.isActive ? s.active : s.unavailable,
                                  style: TextStyle(color: record.isActive ? Colors.green : Colors.red, fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                      onPressed: () => _showAddEditDialog(context, existingRecord: record),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            backgroundColor: const Color(0xFF1E293B),
                                            title: Text(s.confirmDelete, style: const TextStyle(color: Colors.white)),
                                            content: Text('${record.name}?', style: const TextStyle(color: Colors.grey)),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.cancel, style: const TextStyle(color: Colors.grey))),
                                              TextButton(onPressed: () => Navigator.pop(context, true), child: Text(s.delete, style: const TextStyle(color: Colors.red))),
                                            ],
                                          )
                                        );
                                        if (confirm == true) {
                                          ref.read(masterDataProvider.notifier).deleteRecord(widget.type, record.id);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
