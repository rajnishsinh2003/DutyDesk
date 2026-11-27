import 'package:flutter/material.dart';

/// Read-only profile detail row used in the Invigilator Profile tab.
class InvigilatorReadOnlyRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InvigilatorReadOnlyRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF007A87)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Compact status pill badge for duty cards.
class InvigilatorStatusBadge extends StatelessWidget {
  final String status;
  final String acceptedLabel;
  final String rejectedLabel;
  final String pendingLabel;

  const InvigilatorStatusBadge({
    super.key,
    required this.status,
    required this.acceptedLabel,
    required this.rejectedLabel,
    required this.pendingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    switch (status.toLowerCase()) {
      case 'accepted':
        color = Colors.green;
        label = acceptedLabel;
        break;
      case 'rejected':
        color = Colors.red;
        label = rejectedLabel;
        break;
      default:
        color = Colors.orange;
        label = pendingLabel;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Icon + text row used across duty cards.
class InvigilatorInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const InvigilatorInfoRow({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
