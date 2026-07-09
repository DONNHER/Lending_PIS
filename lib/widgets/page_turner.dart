import 'package:flutter/material.dart';
import '../app_theme.dart';

class PageTurner extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalRows;
  final int rowsPerPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int?> onRowsPerPageChanged;

  const PageTurner({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalRows,
    required this.rowsPerPage,
    required this.onPageChanged,
    required this.onRowsPerPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildRowsSelector(),
          _buildSimplePager(),
        ],
      ),
    );
  }

  Widget _buildRowsSelector() {
    // Standard rows options
    final options = [10, 20, 50];
    // Ensure the value is in the list to prevent dropdown crash
    final val = options.contains(rowsPerPage) ? rowsPerPage : 10;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Rows: ', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        DropdownButton<int>(
          value: val,
          underline: const SizedBox(),
          style: const TextStyle(fontSize: 11, color: AppTheme.textDark, fontWeight: FontWeight.bold),
          items: options.map((int v) => DropdownMenuItem<int>(value: v, child: Text('$v'))).toList(),
          onChanged: onRowsPerPageChanged,
        ),
        const SizedBox(width: 8),
        Text('of $totalRows', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _buildSimplePager() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn(Icons.chevron_left, currentPage - 1, currentPage > 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('$currentPage / ${totalPages > 0 ? totalPages : 1}', 
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        _btn(Icons.chevron_right, currentPage + 1, currentPage < totalPages),
      ],
    );
  }

  Widget _btn(IconData icon, int target, bool active) {
    return IconButton(
      icon: Icon(icon, size: 18),
      onPressed: active ? () => onPageChanged(target) : null,
      visualDensity: VisualDensity.compact,
      color: const Color(0xFFC06C4D),
      disabledColor: AppTheme.textMuted.withOpacity(0.2),
    );
  }
}
