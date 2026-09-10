import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:duty_desk/l10n/app_localizations.dart';
import '../providers/notification_provider.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends ConsumerState<NotificationCenterScreen> {
  String _selectedFilter = 'all'; // 'all', 'unread', 'duties', 'alerts'

  String _formatRelativeTime(BuildContext context, DateTime dt) {
    final s = S.of(context)!;
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) {
      return s.justNow;
    } else if (diff.inMinutes < 60) {
      return s.minutesAgo(diff.inMinutes);
    } else if (diff.inHours < 24) {
      return s.hoursAgo(diff.inHours);
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'duty_assigned':
        return Icons.assignment_turned_in;
      case 'duty_accepted':
        return Icons.check_circle;
      case 'duty_rejected':
        return Icons.cancel;
      case 'duty_reassigned':
        return Icons.swap_horiz;
      case 'duty_reminder':
        return Icons.alarm;
      case 'geofence_alert':
        return Icons.radar;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'duty_assigned':
        return const Color(0xFF007A87);
      case 'duty_accepted':
        return Colors.green;
      case 'duty_rejected':
        return Colors.red;
      case 'duty_reassigned':
        return Colors.orange.shade800;
      case 'duty_reminder':
        return Colors.deepPurple;
      case 'geofence_alert':
        return Colors.amber.shade900;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final notifications = ref.watch(notificationProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    final filtered = notifications.where((n) {
      if (_selectedFilter == 'unread') return !n.isRead;
      if (_selectedFilter == 'duties') {
        return n.type == 'duty_assigned' || n.type == 'duty_accepted' || n.type == 'duty_rejected' || n.type == 'duty_reassigned' || n.type == 'duty_reminder';
      }
      if (_selectedFilter == 'alerts') {
        return n.type == 'geofence_alert' || n.type == 'duty_rejected';
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.notificationCenter, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              icon: const Icon(Icons.done_all, size: 16, color: Color(0xFF007A87)),
              label: Text(s.markAllRead, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF007A87))),
              onPressed: () {
                ref.read(notificationProvider.notifier).markAllAsRead();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('${s.all} (${notifications.length})', 'all'),
                  _buildFilterChip('${s.unread} ($unreadCount)', 'unread'),
                  _buildFilterChip(s.dutyUpdates, 'duties'),
                  _buildFilterChip(s.alerts, 'alerts'),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Notifications List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_outlined, size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(s.noNotifications, style: const TextStyle(fontSize: 15, color: Colors.grey)),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
                    itemBuilder: (context, index) {
                      final n = filtered[index];
                      final iconColor = _getColorForType(n.type);
                      final icon = _getIconForType(n.type);

                      return Dismissible(
                        key: ValueKey(n.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red.shade400,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          ref.read(notificationProvider.notifier).deleteNotification(n.id);
                        },
                        child: InkWell(
                          onTap: () {
                            if (!n.isRead) {
                              ref.read(notificationProvider.notifier).markAsRead(n.id);
                            }
                          },
                          child: Container(
                            color: n.isRead ? Colors.transparent : iconColor.withValues(alpha: 0.05),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: iconColor.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(icon, color: iconColor, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              n.title,
                                              style: TextStyle(
                                                fontWeight: n.isRead ? FontWeight.w600 : FontWeight.bold,
                                                fontSize: 13.5,
                                              ),
                                            ),
                                          ),
                                          if (!n.isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: iconColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        n.message,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: n.isRead ? Colors.grey.shade700 : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _formatRelativeTime(context, n.timestamp),
                                        style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
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
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        selected: isSelected,
        selectedColor: const Color(0xFF007A87),
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
        onSelected: (selected) {
          if (selected) setState(() => _selectedFilter = value);
        },
      ),
    );
  }
}
