import 'package:flutter/material.dart';

class CalendarNotificationOverlay extends StatelessWidget {
  const CalendarNotificationOverlay({super.key});

  // Theme Colors
  static const Color primaryGreen = Color(0xFF66FF66);
  static const Color lightGreenCircle = Color(0xFFE8F5E9);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Due dates", 
              style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            const Text("Mon, Aug 17", 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Divider(),
            
            // Calendar Header
            Row(
              children: [
                const Text("August 2023", 
                  style: TextStyle(fontWeight: FontWeight.w600)),
                const Icon(Icons.arrow_drop_down, size: 20),
                const Spacer(),
                const Icon(Icons.settings_outlined, size: 20, color: Colors.grey),
                const SizedBox(width: 12),
                const Icon(Icons.settings_outlined, size: 20, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 16),

            // Weekday Labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ["S", "M", "T", "W", "T", "F", "S"]
                  .map((day) => Text(day, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))
                  .toList(),
            ),
            const SizedBox(height: 12),

            // Calendar Grid Mockup
            _buildCalendarGrid(),

            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK", 
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    // Basic representation of the August 2023 grid
    return Column(
      children: [
        _calendarRow(["", "", "1", "2", "3", "4", "5"], specialDay: "5", isOutline: true),
        _calendarRow(["6", "7", "8", "9", "10", "11", "12"]),
        _calendarRow(["13", "14", "15", "16", "17", "18", "19"], specialDay: "17", isSolid: true),
        _calendarRow(["20", "21", "22", "23", "24", "25", "26"]),
        _calendarRow(["27", "28", "29", "30", "31", "", ""]),
      ],
    );
  }

  Widget _calendarRow(List<String> days, {String? specialDay, bool isOutline = false, bool isSolid = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.map((day) {
          bool isSpecial = day == specialDay;
          return Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isSpecial && isSolid) ? primaryGreen : Colors.transparent,
              border: (isSpecial && isOutline) ? Border.all(color: primaryGreen) : null,
            ),
            child: Text(
              day,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSpecial ? FontWeight.bold : FontWeight.normal,
                color: (isSpecial && isSolid) ? Colors.black : Colors.black87,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}