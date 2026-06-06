import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../models/lending_models.dart';

class RecentLoansTable extends StatelessWidget {
  final List<TransactionModel> transactions;
  final Function(TransactionModel)? onTap;
  final VoidCallback? onSeeAll;

  const RecentLoansTable({
    super.key,
    required this.transactions,
    this.onTap,
    this.onSeeAll,
  });

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESSFUL':
      case 'APPROVED':
      case 'COMPLETED':
      case 'RELEASED':
      case 'DISBURSED':
        return const Color(0xFF10B981); // Green
      case 'CANCELLED':
      case 'REJECTED':
      case 'FAILED':
        return AppTheme.error;
      case 'PENDING':
      default:
        return const Color(0xFFF4A460); // Orange/SandyBrown
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transaction History',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppTheme.textDark,
              ),
            ),
            if (onSeeAll != null)
              TextButton(
                onPressed: onSeeAll,
                child: const Text(
                  'See all',
                  style: TextStyle(
                    color: Color(0xFFC06C4D),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Table Header (Terracotta)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: const BoxDecoration(
                  color: Color(0xFFC06C4D),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 2, child: Text('Ref ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                    Expanded(flex: 3, child: Text('Client', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                    Expanded(flex: 2, child: Text('Amount', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                    Expanded(flex: 2, child: Text('Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                    Expanded(flex: 2, child: Text('Date', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                ),
              ),
              // Table Rows
              if (transactions.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No transactions found', style: TextStyle(color: AppTheme.textMuted)),
                )
              else
                ...transactions.map((tx) => InkWell(
                  onTap: () => onTap?.call(tx),
                  hoverColor: const Color(0xFF32211A).withOpacity(0.01),
                  splashColor: const Color(0xFFC06C4D).withOpacity(0.04),
                  child: _buildRow(tx),
                )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRow(TransactionModel tx) {
    final statusColor = _getStatusColor(tx.status);
    final statusBg = statusColor.withOpacity(0.1);
    final displayId = tx.referenceId.length > 7 
        ? '${tx.referenceId.substring(0, 7)}...' 
        : tx.referenceId;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              displayId,
              style: const TextStyle(fontSize: 11, color: AppTheme.textDark, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              tx.clientName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '₱${NumberFormat('#,##0.00').format(tx.amount)}',
              style: const TextStyle(fontSize: 13, color: AppTheme.textDark, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.2)),
                ),
                child: Text(
                  tx.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('MMM dd, yyyy').format(tx.date),
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
