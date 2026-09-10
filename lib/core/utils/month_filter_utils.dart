import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Month abbreviation to month-number map (1-indexed).
const Map<String, int> _monthAbbrevToNumber = {
  'Jan': 1,
  'Feb': 2,
  'Mar': 3,
  'Apr': 4,
  'May': 5,
  'Jun': 6,
  'Jul': 7,
  'Aug': 8,
  'Sep': 9,
  'Oct': 10,
  'Nov': 11,
  'Dec': 12,
};

/// Full month names for the dropdown display (index 0 = January).
const List<String> monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Returns the current month number (1–12).
int getCurrentMonth() => DateTime.now().month;

/// Checks whether a date string in `dd-MMM` format (e.g. "01-Jun")
/// belongs to the given [monthNumber] (1–12).
///
/// Returns `true` if the date's month matches, or if the date cannot
/// be parsed (so unknown-format records are never hidden).
bool matchesMonth(String dateStr, int monthNumber) {
  if (dateStr.isEmpty) return true; // keep records with empty dates visible

  // Try to extract the 3-letter month abbreviation after the dash.
  final parts = dateStr.split('-');
  if (parts.length >= 2) {
    final abbrev = parts[1].trim();
    // Capitalise first letter to normalise ("jun" → "Jun").
    final normalised =
        abbrev.isEmpty ? '' : abbrev[0].toUpperCase() + abbrev.substring(1).toLowerCase();
    final mapped = _monthAbbrevToNumber[normalised];
    if (mapped != null) return mapped == monthNumber;
  }

  // Fallback: try parsing with intl DateFormat.
  try {
    final parsed = DateFormat('dd-MMM').parse(dateStr);
    return parsed.month == monthNumber;
  } catch (_) {
    return true; // unparseable → keep visible
  }
}

/// A styled month-filter dropdown widget consistent with the dark theme
/// used throughout the Maintain Data screens.
class MonthFilterDropdown extends StatelessWidget {
  /// Currently selected month (1–12).
  final int selectedMonth;

  /// Called when the user picks a different month.
  final ValueChanged<int> onChanged;

  const MonthFilterDropdown({
    super.key,
    required this.selectedMonth,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.grey.shade300,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedMonth,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
          ),
          dropdownColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          items: List.generate(12, (i) {
            final monthNum = i + 1;
            return DropdownMenuItem<int>(
              value: monthNum,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 16,
                    color: monthNum == getCurrentMonth()
                        ? const Color(0xFF007A87)
                        : (isDarkMode ? Colors.white54 : Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    monthNames[i],
                    style: TextStyle(
                      fontWeight: monthNum == getCurrentMonth()
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: monthNum == selectedMonth
                          ? const Color(0xFF007A87)
                          : null,
                    ),
                  ),
                ],
              ),
            );
          }),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }
}
