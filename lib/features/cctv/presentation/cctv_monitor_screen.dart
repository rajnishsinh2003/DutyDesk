import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Simulated camera feed model
class CameraFeed {
  final String id;
  final String label;        // e.g. "Exam Hall A – Room 201"
  final String centerName;
  final String roomName;
  final String streamUrl;    // RTSP/HLS URL (placeholder)
  final bool isOnline;
  final bool isRecording;
  final DateTime? lastHeartbeat;

  const CameraFeed({
    required this.id,
    required this.label,
    required this.centerName,
    required this.roomName,
    required this.streamUrl,
    this.isOnline = true,
    this.isRecording = true,
    this.lastHeartbeat,
  });
}

/// Provider: In production, replace with Firestore / IP camera API
final cctvFeedsProvider = Provider<List<CameraFeed>>((ref) {
  final now = DateTime.now();
  return [
    CameraFeed(id: 'cam-01', label: 'Main Hall A – Room 101', centerName: 'Main Examination Hall', roomName: 'Room 101', streamUrl: 'rtsp://192.168.1.101/live', isOnline: true, isRecording: true, lastHeartbeat: now),
    CameraFeed(id: 'cam-02', label: 'Main Hall A – Room 102', centerName: 'Main Examination Hall', roomName: 'Room 102', streamUrl: 'rtsp://192.168.1.102/live', isOnline: true, isRecording: true, lastHeartbeat: now.subtract(const Duration(seconds: 30))),
    CameraFeed(id: 'cam-03', label: 'Science Block – Lab 1', centerName: 'Science Complex', roomName: 'Lab 1', streamUrl: 'rtsp://192.168.1.103/live', isOnline: true, isRecording: true, lastHeartbeat: now.subtract(const Duration(minutes: 1))),
    CameraFeed(id: 'cam-04', label: 'Science Block – Lab 2', centerName: 'Science Complex', roomName: 'Lab 2', streamUrl: 'rtsp://192.168.1.104/live', isOnline: false, isRecording: false, lastHeartbeat: now.subtract(const Duration(minutes: 12))),
    CameraFeed(id: 'cam-05', label: 'Engineering Wing – Seminar Hall', centerName: 'Engineering Campus', roomName: 'Seminar Hall', streamUrl: 'rtsp://192.168.1.105/live', isOnline: true, isRecording: true, lastHeartbeat: now),
    CameraFeed(id: 'cam-06', label: 'Gate Entry Point A', centerName: 'Main Campus', roomName: 'Gate A', streamUrl: 'rtsp://192.168.1.106/live', isOnline: true, isRecording: true, lastHeartbeat: now.subtract(const Duration(seconds: 10))),
    CameraFeed(id: 'cam-07', label: 'Gate Entry Point B', centerName: 'Main Campus', roomName: 'Gate B', streamUrl: 'rtsp://192.168.1.107/live', isOnline: true, isRecording: true, lastHeartbeat: now),
    CameraFeed(id: 'cam-08', label: 'Strong Room Vault', centerName: 'Administrative Block', roomName: 'Vault Room', streamUrl: 'rtsp://192.168.1.108/live', isOnline: true, isRecording: true, lastHeartbeat: now.subtract(const Duration(seconds: 5))),
  ];
});

class CctvMonitorScreen extends ConsumerStatefulWidget {
  const CctvMonitorScreen({super.key});

  @override
  ConsumerState<CctvMonitorScreen> createState() => _CctvMonitorScreenState();
}

class _CctvMonitorScreenState extends ConsumerState<CctvMonitorScreen> {
  String _selectedLayout = '2x2'; // '2x2', '3x3', 'list'
  String _filterCenter = 'all';
  String? _expandedCameraId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0E1A) : const Color(0xFF111827);
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFF1F2937);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFF374151);
    const textColor = Colors.white;
    final subtitleColor = Colors.grey.shade400;

    final feeds = ref.watch(cctvFeedsProvider);
    final onlineCount = feeds.where((f) => f.isOnline).length;
    final offlineCount = feeds.length - onlineCount;

    final centerNames = <String>{'all', ...feeds.map((f) => f.centerName)};
    final filteredFeeds = _filterCenter == 'all' ? feeds : feeds.where((f) => f.centerName == _filterCenter).toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CCTV Surveillance Monitor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
            Text('Live IP Camera Feed Console', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
        actions: [
          // Layout toggle
          _layoutButton('2x2', Icons.grid_view_rounded),
          _layoutButton('3x3', Icons.apps_rounded),
          _layoutButton('list', Icons.view_list_rounded),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // STATUS BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.black.withValues(alpha: 0.3),
              child: Row(
                children: [
                  _statusDot(true),
                  const SizedBox(width: 6),
                  Text('$onlineCount Online', style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  _statusDot(false),
                  const SizedBox(width: 6),
                  Text('$offlineCount Offline', style: TextStyle(color: Colors.red.shade400, fontSize: 12, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  // Center filter dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filterCenter,
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 18),
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                        items: centerNames.map((c) => DropdownMenuItem(value: c, child: Text(c == 'all' ? 'All Centers' : c, style: const TextStyle(fontSize: 11)))).toList(),
                        onChanged: (val) => setState(() => _filterCenter = val ?? 'all'),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // FEED GRID / LIST
            Expanded(
              child: _expandedCameraId != null
                  ? _buildExpandedView(filteredFeeds.firstWhere((f) => f.id == _expandedCameraId, orElse: () => filteredFeeds.first), cardBg, borderColor, subtitleColor)
                  : (_selectedLayout == 'list'
                      ? _buildListView(filteredFeeds, cardBg, borderColor, subtitleColor)
                      : _buildGridView(filteredFeeds, cardBg, borderColor, subtitleColor)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(List<CameraFeed> feeds, Color cardBg, Color borderColor, Color subtitleColor) {
    final crossAxisCount = _selectedLayout == '3x3' ? 3 : 2;
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 16 / 10,
      ),
      itemCount: feeds.length,
      itemBuilder: (context, index) => _buildFeedTile(feeds[index], cardBg, borderColor, subtitleColor, compact: crossAxisCount == 3),
    );
  }

  Widget _buildListView(List<CameraFeed> feeds, Color cardBg, Color borderColor, Color subtitleColor) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      physics: const BouncingScrollPhysics(),
      itemCount: feeds.length,
      itemBuilder: (context, index) {
        final feed = feeds[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: feed.isOnline ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: feed.isOnline ? Colors.green.withValues(alpha: 0.4) : Colors.red.withValues(alpha: 0.4)),
              ),
              child: Icon(
                feed.isOnline ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                color: feed.isOnline ? Colors.green : Colors.red.shade400,
                size: 22,
              ),
            ),
            title: Text(feed.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
            subtitle: Text(
              '${feed.centerName} • ${feed.isRecording ? "🔴 REC" : "⏸ PAUSED"} • ${feed.lastHeartbeat != null ? DateFormat('HH:mm:ss').format(feed.lastHeartbeat!) : "N/A"}',
              style: TextStyle(color: subtitleColor, fontSize: 11),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.fullscreen_rounded, color: Colors.white54),
              onPressed: () => setState(() => _expandedCameraId = feed.id),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeedTile(CameraFeed feed, Color cardBg, Color borderColor, Color subtitleColor, {bool compact = false}) {
    return GestureDetector(
      onTap: () => setState(() => _expandedCameraId = feed.id),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: feed.isOnline ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3)),
        ),
        child: Stack(
          children: [
            // SIMULATED FEED BACKGROUND
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: feed.isOnline
                        ? [const Color(0xFF0A1628), const Color(0xFF111D2E)]
                        : [const Color(0xFF1A0A0A), const Color(0xFF2A1010)],
                  ),
                ),
                child: Center(
                  child: Icon(
                    feed.isOnline ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                    size: compact ? 28 : 40,
                    color: feed.isOnline ? Colors.white.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),

            // TOP OVERLAY: Status + Recording
            Positioned(
              top: 6,
              left: 6,
              right: 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _statusDot(feed.isOnline),
                      const SizedBox(width: 4),
                      if (!compact) Text(feed.isOnline ? 'LIVE' : 'OFFLINE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: feed.isOnline ? Colors.green : Colors.red.shade400)),
                    ],
                  ),
                  if (feed.isRecording)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(4)),
                      child: const Text('● REC', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                ],
              ),
            ),

            // BOTTOM OVERLAY: Label + Time
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 8, vertical: compact ? 3 : 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                  ),
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        feed.label,
                        style: TextStyle(color: Colors.white, fontSize: compact ? 8 : 10, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      feed.lastHeartbeat != null ? DateFormat('HH:mm').format(feed.lastHeartbeat!) : '',
                      style: TextStyle(color: subtitleColor, fontSize: compact ? 7 : 9),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedView(CameraFeed feed, Color cardBg, Color borderColor, Color subtitleColor) {
    return Column(
      children: [
        // EXPANDED FEED AREA
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1628),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: feed.isOnline ? Colors.green.withValues(alpha: 0.4) : Colors.red.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        feed.isOnline ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                        size: 64,
                        color: feed.isOnline ? Colors.white.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        feed.isOnline ? 'Live Stream — ${feed.streamUrl}' : 'Camera Offline',
                        style: TextStyle(color: feed.isOnline ? Colors.white38 : Colors.red.shade300, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Connect RTSP/HLS stream for live preview',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                      ),
                    ],
                  ),
                ),

                // Top overlay
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _statusDot(feed.isOnline),
                          const SizedBox(width: 6),
                          Text(feed.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      if (feed.isRecording)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                          child: const Text('● RECORDING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                    ],
                  ),
                ),

                // Bottom info
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${feed.centerName} • ${feed.roomName}', style: TextStyle(color: subtitleColor, fontSize: 11)),
                      Text(DateFormat('dd MMM yyyy HH:mm:ss').format(DateTime.now()), style: TextStyle(color: subtitleColor, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // BACK TO GRID BUTTON
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.grid_view_rounded),
            label: const Text('Return to Grid View'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007A87),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => setState(() => _expandedCameraId = null),
          ),
        ),
      ],
    );
  }

  Widget _statusDot(bool isOnline) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isOnline ? Colors.green : Colors.red.shade400,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: (isOnline ? Colors.green : Colors.red).withValues(alpha: 0.4), blurRadius: 4)],
      ),
    );
  }

  Widget _layoutButton(String layout, IconData icon) {
    final isActive = _selectedLayout == layout;
    return IconButton(
      icon: Icon(icon, size: 20, color: isActive ? const Color(0xFF007A87) : Colors.white38),
      tooltip: layout == '2x2' ? '2×2 Grid' : (layout == '3x3' ? '3×3 Grid' : 'List View'),
      onPressed: () => setState(() {
        _selectedLayout = layout;
        _expandedCameraId = null;
      }),
    );
  }
}
