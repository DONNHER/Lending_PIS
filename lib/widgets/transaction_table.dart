import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../models/lending_models.dart';

class TransactionTable extends StatelessWidget {
  final List<TransactionModel> transactions;
  final Function(TransactionModel) onView;

  const TransactionTable({
    super.key,
    required this.transactions,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: const BoxDecoration(
            color: Color(0xFFC06C4D),
            borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
          ),
          child: const Row(
            children: [
              Expanded(flex: 2, child: Text('Trans ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 3, child: Text('Client', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 2, child: Text('Type', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 2, child: Text('Method', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 2, child: Text('Amount', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 2, child: Text('Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 2, child: Text('Date', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 1, child: Align(alignment: Alignment.centerRight, child: Text('', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
            ],
          ),
        ),
        // Table Body
        Expanded(
          child: transactions.isEmpty 
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No transactions found', style: TextStyle(color: AppTheme.textMuted)),
                ),
              )
            : ListView.separated(
                itemCount: transactions.length,
                padding: EdgeInsets.zero,
                separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  return InkWell(
                    onTap: () => onView(tx),
                    child: _buildRow(tx),
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildRow(TransactionModel tx) {
    final currencyFormat = NumberFormat('#,##0.00');
    final dateFormat = DateFormat('MMM dd, yyyy');

    // Status color (Successful is green)
    final statusColor = tx.status.toLowerCase() == 'successful' ? const Color(0xFF10B981) : AppTheme.textMuted;
    final statusBg = statusColor.withOpacity(0.1);

    // ✨ TRUNCATION HELPER: Formats full UUID string to short, clean UI blocks (e.g., 68601ec4...)
    final String displayId = tx.id.length > 8 ? '${tx.id.substring(0, 8)}...' : tx.id;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          // ✨ UPDATED: Shortened display wrapped inside a tooltip for seamless user inspection
          Expanded(
            flex: 2,
            child: Tooltip(
              message: tx.id, // Shows complete raw UUID on hover/long press
              preferBelow: false,
              child: Text(
                displayId,
                style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
              ),
            ),
          ),

          Expanded(flex: 3, child: Text(tx.clientName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark))),
          Expanded(flex: 2, child: Text(tx.type, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark))),
          Expanded(flex: 2, child: Text(tx.method, style: const TextStyle(fontSize: 12, color: AppTheme.textDark))),
          Expanded(flex: 2, child: Text('₱${currencyFormat.format(tx.amount)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textDark))),

          // Status Badge
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tx.status,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ),
          ),

          Expanded(flex: 2, child: Text(dateFormat.format(tx.date), style: const TextStyle(fontSize: 12, color: AppTheme.textMuted))),

          // Actions
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
