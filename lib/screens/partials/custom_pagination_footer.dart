import 'package:flutter/material.dart';

class CustomPaginationFooter extends StatelessWidget {
  final int currentPage;
  final int totalRows;
  final int rowsPerPage;
  final Function(int) onPageChanged;
  final Function(int?) onRowsPerPageChanged;

  const CustomPaginationFooter({
    super.key,
    required this.currentPage,
    required this.totalRows,
    this.rowsPerPage = 10,
    required this.onPageChanged,
    required this.onRowsPerPageChanged,
  });

  // Colors matching your theme
  static const Color darkBrown = Color(0xFF3A2318);
  static const Color textMuted = Color(0xFF8B7365);
  static const Color borderLine = Color(0xFFE6DED8);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        children: [
          // --- Rows Per Page Selector ---
          const Text("Rows per page: ",
              style: TextStyle(color: textMuted, fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: borderLine),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: rowsPerPage,
                isDense: true,
                items: [10, 25, 50].map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(value.toString(), style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: onRowsPerPageChanged,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text("of $totalRows rows",
              style: const TextStyle(color: textMuted, fontSize: 13)),

          const Spacer(),

          // --- Navigation Controls ---
          _buildArrowButton(Icons.keyboard_double_arrow_left, () => onPageChanged(1)),
          _buildArrowButton(Icons.keyboard_arrow_left, () => onPageChanged(currentPage - 1)),

          const SizedBox(width: 8),
          _buildPageNumber("1", currentPage == 1),
          _buildPageNumber("2", currentPage == 2),
          _buildPageNumber("3", currentPage == 3),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text("...", style: TextStyle(color: textMuted)),
          ),
          _buildPageNumber("10", currentPage == 10),

          const SizedBox(width: 8),
          _buildArrowButton(Icons.keyboard_arrow_right, () => onPageChanged(currentPage + 1)),
          _buildArrowButton(Icons.keyboard_double_arrow_right, () => onPageChanged(10)), // Placeholder max
        ],
      ),
    );
  }

  Widget _buildArrowButton(IconData icon, VoidCallback? onTap) {
    return IconButton(
      icon: Icon(icon, size: 18, color: Colors.grey),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildPageNumber(String label, bool isActive) {
    return GestureDetector(
      onTap: () => onPageChanged(int.parse(label)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? darkBrown : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : textMuted,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}