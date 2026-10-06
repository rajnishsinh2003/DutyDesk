import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/room_model.dart';
import '../providers/center_hierarchy_provider.dart';
import '../services/center_readiness_pdf_service.dart';
import '../../admin/providers/center_provider.dart';

class CenterHierarchyScreen extends ConsumerStatefulWidget {
  final String centerId;

  const CenterHierarchyScreen({super.key, required this.centerId});

  @override
  ConsumerState<CenterHierarchyScreen> createState() => _CenterHierarchyScreenState();
}

class _CenterHierarchyScreenState extends ConsumerState<CenterHierarchyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedBuildingFilter = 'all';

  // Readiness Form state
  final _examNameCtrl = TextEditingController(text: 'National Level Examination 2026');
  final _inspectorCtrl = TextEditingController(text: 'Center Superintendent');
  final _remarksCtrl = TextEditingController();
  String _examDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  // Readiness Checklist values
  bool _powerBackupReady = false;
  bool _cctvOperational = false;
  bool _jammersOperational = false;
  bool _strongRoomSecured = false;
  bool _waterSanitationReady = false;
  bool _clockSyncVerified = false;
  bool _firstAidReady = false;
  bool _securityFriskingReady = false;
  bool _seatingPlanPasted = false;
  bool _computersTested = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _examNameCtrl.dispose();
    _inspectorCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  void _loadExistingReadiness(List<ExamCenterReadiness> allReports) {
    if (_isInitialized) return;
    final existing = allReports.where((r) => r.centerId == widget.centerId).toList();
    if (existing.isNotEmpty) {
      final rep = existing.first;
      _examNameCtrl.text = rep.examName;
      _inspectorCtrl.text = rep.inspectorName;
      if (rep.examDate.isNotEmpty) _examDate = rep.examDate;
      _remarksCtrl.text = rep.generalRemarks ?? '';
      _powerBackupReady = rep.powerBackupReady;
      _cctvOperational = rep.cctvOperational;
      _jammersOperational = rep.jammersOperational;
      _strongRoomSecured = rep.strongRoomSecured;
      _waterSanitationReady = rep.waterSanitationReady;
      _clockSyncVerified = rep.clockSyncVerified;
      _firstAidReady = rep.firstAidReady;
      _securityFriskingReady = rep.securityFriskingReady;
      _seatingPlanPasted = rep.seatingPlanPasted;
      _computersTested = rep.computersTested;
    }
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final centers = ref.watch(centerProvider);
    final allRooms = ref.watch(roomProvider);
    final allReadiness = ref.watch(centerReadinessProvider);

    final center = centers.firstWhere(
      (c) => c.id == widget.centerId,
      orElse: () => ExamCenter(id: widget.centerId, name: 'Examination Center', location: '', capacity: 0),
    );

    _loadExistingReadiness(allReadiness);

    final centerRooms = allRooms.where((r) => r.centerId == widget.centerId).toList();

    // Summary calculations
    final totalCapacity = centerRooms.fold<int>(0, (sum, r) => sum + r.capacity);
    final totalComputers = centerRooms.fold<int>(0, (sum, r) => sum + r.computerCount);
    final totalInvigilators = centerRooms.fold<int>(0, (sum, r) => sum + r.invigilatorRequired);

    // Extract unique buildings
    final buildings = {'all', ...centerRooms.map((r) => r.buildingName)};

    final filteredRooms = _selectedBuildingFilter == 'all'
        ? centerRooms
        : centerRooms.where((r) => r.buildingName == _selectedBuildingFilter).toList();

    // Group rooms by Floor
    final Map<String, List<ExamRoom>> roomsByFloor = {};
    for (final room in filteredRooms) {
      roomsByFloor.putIfAbsent(room.floorName, () => []).add(room);
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(center.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text('${center.location} • Hierarchy & Readiness', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(icon: const Icon(Icons.apartment_rounded, size: 20), text: 'Rooms & Floors (${centerRooms.length})'),
            Tab(icon: const Icon(Icons.fact_check_rounded, size: 20), text: 'Readiness Audit'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // -------------------------------------------------------------------
          // TAB 1: BUILDING / FLOOR / ROOM HIERARCHY
          // -------------------------------------------------------------------
          _buildHierarchyTab(center, centerRooms, buildings, roomsByFloor, totalCapacity, totalComputers, totalInvigilators),

          // -------------------------------------------------------------------
          // TAB 2: CENTER READINESS CHECKLIST
          // -------------------------------------------------------------------
          _buildReadinessTab(center, centerRooms),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1 WIDGET: ROOMS & FLOORS
  // ===========================================================================
  Widget _buildHierarchyTab(
    ExamCenter center,
    List<ExamRoom> allRooms,
    Set<String> buildings,
    Map<String, List<ExamRoom>> roomsByFloor,
    int totalCapacity,
    int totalComputers,
    int totalInvigilators,
  ) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Capacity & Infrastructure Metrics Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF007A87), Color(0xFF0F766E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF007A87).withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.meeting_room_outlined,
                          title: 'Total Rooms',
                          value: '${allRooms.length}',
                        ),
                      ),
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.airline_seat_recline_normal,
                          title: 'Candidate Seats',
                          value: '$totalCapacity',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.computer_rounded,
                          title: 'CBT Terminals',
                          value: '$totalComputers',
                        ),
                      ),
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.badge_outlined,
                          title: 'Staff Required',
                          value: '$totalInvigilators',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Building Filter & Action Bar
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: buildings.map((b) {
                        final isSelected = _selectedBuildingFilter == b;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(b == 'all' ? 'All Buildings' : b),
                            selected: isSelected,
                            selectedColor: const Color(0xFF007A87),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _selectedBuildingFilter = b);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.flash_auto, size: 16),
                  label: const Text('Bulk Add', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => _showBulkAddRoomsDialog(center),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Room List Grouped By Floor
            if (roomsByFloor.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.meeting_room_outlined, size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('No rooms configured for this center yet.', style: TextStyle(color: Colors.grey, fontSize: 15)),
                    const SizedBox(height: 8),
                    const Text('Tap "Add Room" or "Bulk Add" below to set up rooms & floors.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              )
            else
              ...roomsByFloor.entries.map((entry) {
                final floor = entry.key;
                final rooms = entry.value;
                final floorCapacity = rooms.fold<int>(0, (sum, r) => sum + r.capacity);
                final floorComputers = rooms.fold<int>(0, (sum, r) => sum + r.computerCount);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Floor Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.layers_rounded, color: Color(0xFF007A87), size: 20),
                                const SizedBox(width: 8),
                                Text(floor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            Text(
                              '${rooms.length} Rooms • $floorCapacity Seats${floorComputers > 0 ? " • $floorComputers PCs" : ""}',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                        const Divider(height: 20),

                        // Rooms inside Floor
                        ...rooms.map((room) => _buildRoomTile(room, center)),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 70),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF007A87),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Room'),
        onPressed: () => _showAddOrEditRoomDialog(center: center),
      ),
    );
  }

  Widget _buildMetricTile({required IconData icon, required String title, required String value}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ],
    );
  }

  Widget _buildRoomTile(ExamRoom room, ExamCenter center) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007A87).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Room ${room.roomNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF007A87), fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    room.buildingName,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Edit Room',
                    onPressed: () => _showAddOrEditRoomDialog(center: center, existingRoom: room),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Delete Room',
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('Delete Room ${room.roomNumber}?'),
                          content: const Text('Are you sure you want to remove this room from the examination center?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await ref.read(roomProvider.notifier).deleteRoom(room.id);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildFeatureBadge(Icons.airline_seat_recline_normal, '${room.capacity} Seats', const Color(0xFF0284C7)),
              if (room.hasComputers)
                _buildFeatureBadge(Icons.computer, '${room.computerCount} CBT PCs', const Color(0xFF059669)),
              _buildFeatureBadge(Icons.person, '${room.invigilatorRequired} Invigilator${room.invigilatorRequired > 1 ? "s" : ""}', const Color(0xFFD97706)),
              if (room.hasCctv)
                _buildFeatureBadge(Icons.videocam_outlined, 'CCTV', Colors.grey.shade800),
              if (room.hasJammer)
                _buildFeatureBadge(Icons.signal_cellular_off_rounded, 'Jammer', Colors.deepOrange),
              if (room.isAccessible)
                _buildFeatureBadge(Icons.accessible, 'Accessible', Colors.teal.shade800),
            ],
          ),
          if (room.notes != null && room.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(room.notes!, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2 WIDGET: PRE-EXAM READINESS CHECKLIST
  // ===========================================================================
  Widget _buildReadinessTab(ExamCenter center, List<ExamRoom> rooms) {
    int passedCount = 0;
    if (_powerBackupReady) passedCount++;
    if (_cctvOperational) passedCount++;
    if (_jammersOperational) passedCount++;
    if (_strongRoomSecured) passedCount++;
    if (_waterSanitationReady) passedCount++;
    if (_clockSyncVerified) passedCount++;
    if (_firstAidReady) passedCount++;
    if (_securityFriskingReady) passedCount++;
    if (_seatingPlanPasted) passedCount++;
    if (_computersTested) passedCount++;

    final percentage = (passedCount / 10.0) * 100;
    final isCompliant = passedCount == 10;
    final statusColor = isCompliant ? const Color(0xFF10B981) : (passedCount < 5 ? const Color(0xFFDC2626) : const Color(0xFFF59E0B));
    final statusText = isCompliant ? '100% READY FOR EXAMINATION' : (passedCount < 5 ? 'CRITICAL ACTIONS REQUIRED' : 'INSPECTION IN PROGRESS');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Status Progress Hero
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text('$passedCount of 10 audit parameters verified', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Text('${percentage.toInt()}%', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 28)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: passedCount / 10.0,
                    minHeight: 8,
                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Exam Context Fields
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Audit Context', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _examNameCtrl,
                    decoration: const InputDecoration(labelText: 'Examination Name *', prefixIcon: Icon(Icons.assignment, size: 20)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inspectorCtrl,
                          decoration: const InputDecoration(labelText: 'Inspector / Auditor *', prefixIcon: Icon(Icons.person, size: 20)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.tryParse(_examDate) ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                            );
                            if (picked != null) {
                              setState(() => _examDate = DateFormat('yyyy-MM-dd').format(picked));
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_examDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                const Icon(Icons.calendar_today, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. 10 Verification Checklist Items
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _buildChecklistTile(
                    title: '1. Power Backup (Generator / Online UPS)',
                    subtitle: 'Generator fuel tested & instant UPS switchover verified without rebooting exam systems.',
                    value: _powerBackupReady,
                    onChanged: (v) => setState(() => _powerBackupReady = v ?? false),
                  ),
                  const Divider(height: 1),
                  _buildChecklistTile(
                    title: '2. CCTV Surveillance & DVR Recording',
                    subtitle: 'Full coverage of all examination halls, control room, and staircases with active DVR storage.',
                    value: _cctvOperational,
                    onChanged: (v) => setState(() => _cctvOperational = v ?? false),
                  ),
                  const Divider(height: 1),
                  _buildChecklistTile(
                    title: '3. Mobile Signal Jammers Operational',
                    subtitle: 'Signal suppressors tested to eliminate 2G/3G/4G/5G and Bluetooth transmissions.',
                    value: _jammersOperational,
                    onChanged: (v) => setState(() => _jammersOperational = v ?? false),
                  ),
                  const Divider(height: 1),
                  _buildChecklistTile(
                    title: '4. Strong Room & Confidential Storage',
                    subtitle: 'Double-lock custody room secured with armed security guard stationed outside.',
                    value: _strongRoomSecured,
                    onChanged: (v) => setState(() => _strongRoomSecured = v ?? false),
                  ),
                  const Divider(height: 1),
                  _buildChecklistTile(
                    title: '5. Drinking Water & Sanitized Restrooms',
                    subtitle: 'Hygienic restrooms and sufficient potable water dispensers set up per floor.',
                    value: _waterSanitationReady,
                    onChanged: (v) => setState(() => _waterSanitationReady = v ?? false),
                  ),
                  const Divider(height: 1),
                  _buildChecklistTile(
                    title: '6. Room Clocks Synchronized (IST)',
                    subtitle: 'All room wall clocks synchronized with Indian Standard Time without time drift.',
                    value: _clockSyncVerified,
                    onChanged: (v) => setState(() => _clockSyncVerified = v ?? false),
                  ),
                  const Divider(height: 1),
                  _buildChecklistTile(
                    title: '7. First Aid & Medical Emergency Desk',
                    subtitle: 'First aid medical kit, ORS/glucose, and nursing paramedic available on center premises.',
                    value: _firstAidReady,
                    onChanged: (v) => setState(() => _firstAidReady = v ?? false),
                  ),
                  const Divider(height: 1),
                  _buildChecklistTile(
                    title: '8. Security & Gate Frisking Booths',
                    subtitle: 'Hand-held metal detectors (HHMD), door frames, and separate gender frisking enclosures ready.',
                    value: _securityFriskingReady,
                    onChanged: (v) => setState(() => _securityFriskingReady = v ?? false),
                  ),
                  const Divider(height: 1),
                  _buildChecklistTile(
                    title: '9. Seating Plans Pasted on Doors',
                    subtitle: 'Candidate roll number charts pasted at main entrance gate and on room entry doors.',
                    value: _seatingPlanPasted,
                    onChanged: (v) => setState(() => _seatingPlanPasted = v ?? false),
                  ),
                  const Divider(height: 1),
                  _buildChecklistTile(
                    title: '10. CBT Computers & LAN Network Tested',
                    subtitle: 'Exam terminals, browser security lock, and mock exam servers fully validated.',
                    value: _computersTested,
                    onChanged: (v) => setState(() => _computersTested = v ?? false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Remarks
          TextField(
            controller: _remarksCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'General Auditor Remarks / Action Items (Optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          // 5. Actions (Save & Export PDF)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  label: const Text('Export Certificate (PDF)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final report = _buildCurrentReport(center);
                    await CenterReadinessPdfService.generateAndPrintCertificate(
                      center: center,
                      report: report,
                      rooms: rooms,
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save Audit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007A87),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final report = _buildCurrentReport(center);
                    final messenger = ScaffoldMessenger.of(context);
                    await ref.read(centerReadinessProvider.notifier).saveReadinessReport(report);
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('✅ Center Readiness Audit saved successfully!'), backgroundColor: Colors.green),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  ExamCenterReadiness _buildCurrentReport(ExamCenter center) {
    return ExamCenterReadiness(
      id: widget.centerId,
      centerId: widget.centerId,
      centerName: center.name,
      examName: _examNameCtrl.text.trim().isNotEmpty ? _examNameCtrl.text.trim() : 'Upcoming Examination',
      examDate: _examDate,
      inspectorName: _inspectorCtrl.text.trim().isNotEmpty ? _inspectorCtrl.text.trim() : 'Center Superintendent',
      powerBackupReady: _powerBackupReady,
      cctvOperational: _cctvOperational,
      jammersOperational: _jammersOperational,
      strongRoomSecured: _strongRoomSecured,
      waterSanitationReady: _waterSanitationReady,
      clockSyncVerified: _clockSyncVerified,
      firstAidReady: _firstAidReady,
      securityFriskingReady: _securityFriskingReady,
      seatingPlanPasted: _seatingPlanPasted,
      computersTested: _computersTested,
      generalRemarks: _remarksCtrl.text.trim(),
    );
  }

  Widget _buildChecklistTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF007A87),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    );
  }

  // ===========================================================================
  // DIALOGS: ADD / EDIT ROOM & BULK GENERATE
  // ===========================================================================
  void _showAddOrEditRoomDialog({required ExamCenter center, ExamRoom? existingRoom}) {
    final isEdit = existingRoom != null;
    final buildingCtrl = TextEditingController(text: existingRoom?.buildingName ?? 'Main Academic Block');
    final floorCtrl = TextEditingController(text: existingRoom?.floorName ?? 'Ground Floor');
    final roomCtrl = TextEditingController(text: existingRoom?.roomNumber ?? '');
    final capacityCtrl = TextEditingController(text: existingRoom != null ? '${existingRoom.capacity}' : '30');
    final computerCountCtrl = TextEditingController(text: existingRoom != null ? '${existingRoom.computerCount}' : '0');
    final notesCtrl = TextEditingController(text: existingRoom?.notes ?? '');

    bool hasComputers = existingRoom?.hasComputers ?? false;
    bool hasCctv = existingRoom?.hasCctv ?? true;
    bool hasJammer = existingRoom?.hasJammer ?? false;
    bool isAccessible = existingRoom?.isAccessible ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(isEdit ? 'Edit Room' : 'Add Examination Room', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: buildingCtrl,
                  decoration: const InputDecoration(labelText: 'Building / Block Name *', hintText: 'e.g. Science Block'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: floorCtrl,
                  decoration: const InputDecoration(labelText: 'Floor Name *', hintText: 'e.g. 1st Floor'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: roomCtrl,
                  decoration: const InputDecoration(labelText: 'Room Number / Identifier *', hintText: 'e.g. 101 / Hall A'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: capacityCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Candidate Seats *', hintText: 'e.g. 30'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: computerCountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'CBT Computers', hintText: 'e.g. 30'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('CBT Computer Lab?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  value: hasComputers,
                  onChanged: (v) => setDialogState(() => hasComputers = v),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('CCTV Surveillance?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  value: hasCctv,
                  onChanged: (v) => setDialogState(() => hasCctv = v),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Signal Jammer Coverage?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  value: hasJammer,
                  onChanged: (v) => setDialogState(() => hasJammer = v),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Wheelchair / Lift Accessible?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  value: isAccessible,
                  onChanged: (v) => setDialogState(() => isAccessible = v),
                  contentPadding: EdgeInsets.zero,
                ),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes / Remarks', hintText: 'e.g. Near restroom, 2 ACs'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007A87), foregroundColor: Colors.white),
              onPressed: () async {
                final roomNum = roomCtrl.text.trim();
                if (roomNum.isEmpty) return;

                final cap = int.tryParse(capacityCtrl.text.trim()) ?? 30;
                final pcs = int.tryParse(computerCountCtrl.text.trim()) ?? 0;

                final room = ExamRoom(
                  id: existingRoom?.id ?? '',
                  centerId: center.id,
                  buildingName: buildingCtrl.text.trim().isNotEmpty ? buildingCtrl.text.trim() : 'Main Block',
                  floorName: floorCtrl.text.trim().isNotEmpty ? floorCtrl.text.trim() : 'Ground Floor',
                  roomNumber: roomNum,
                  capacity: cap,
                  hasComputers: hasComputers || pcs > 0,
                  computerCount: pcs,
                  hasCctv: hasCctv,
                  hasJammer: hasJammer,
                  isAccessible: isAccessible,
                  notes: notesCtrl.text.trim(),
                );

                if (isEdit) {
                  await ref.read(roomProvider.notifier).updateRoom(room);
                } else {
                  await ref.read(roomProvider.notifier).addRoom(room);
                }

                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(isEdit ? 'Update' : 'Add Room'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkAddRoomsDialog(ExamCenter center) {
    final buildingCtrl = TextEditingController(text: 'Science Wing');
    final floorCtrl = TextEditingController(text: '1st Floor');
    final startNumCtrl = TextEditingController(text: '101');
    final countCtrl = TextEditingController(text: '10');
    final capacityCtrl = TextEditingController(text: '30');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.flash_auto, color: Color(0xFF0F766E)),
            SizedBox(width: 8),
            Text('Bulk Generate Rooms', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: buildingCtrl,
                decoration: const InputDecoration(labelText: 'Building Name *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: floorCtrl,
                decoration: const InputDecoration(labelText: 'Floor Name *'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startNumCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Start Number *', hintText: '101'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: countCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Total Rooms *', hintText: '10'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: capacityCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Capacity Per Room *', hintText: '30'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
            onPressed: () async {
              final start = int.tryParse(startNumCtrl.text.trim()) ?? 101;
              final count = int.tryParse(countCtrl.text.trim()) ?? 10;
              final cap = int.tryParse(capacityCtrl.text.trim()) ?? 30;

              await ref.read(roomProvider.notifier).bulkGenerateRooms(
                    centerId: center.id,
                    buildingName: buildingCtrl.text.trim().isNotEmpty ? buildingCtrl.text.trim() : 'Main Block',
                    floorName: floorCtrl.text.trim().isNotEmpty ? floorCtrl.text.trim() : 'Ground Floor',
                    startNumber: start,
                    count: count,
                    capacityPerRoom: cap,
                  );

              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Generate Rooms'),
          ),
        ],
      ),
    );
  }
}
