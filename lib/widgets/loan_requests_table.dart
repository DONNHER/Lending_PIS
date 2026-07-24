import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../models/lending_models.dart';

class LoanRequestsTable extends StatelessWidget {
  final List<LoanRequestModel> requests;
  final Function(LoanRequestModel) onView;
  final bool isLoading;

  const LoanRequestsTable({
    super.key,
    required this.requests,
    required this.onView,
    this.isLoading = false,
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
              Expanded(flex: 3, child: Text('Shareholder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 2, child: Text('Amount', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 2, child: Text('Term', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 2, child: Text('Purpose', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 2, child: Text('Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 2, child: Text('Date', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 1, child: Align(alignment: Alignment.centerRight, child: Text('', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
            ],
          ),
        ),
        // Table Body
        Expanded(
          child: requests.isEmpty
              ? const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No loan requests found', style: TextStyle(color: AppTheme.textMuted)),
            ),
          )
              : ListView.separated(
            itemCount: requests.length,
            padding: EdgeInsets.zero,
            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
            itemBuilder: (context, index) {
              final req = requests[index];
              return InkWell(
                onTap: () => onView(req),
                hoverColor: const Color(0xFFC06C4D).withValues(alpha: 0.05),
                child: _buildRow(req),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRow(LoanRequestModel req) {
    final currencyFormat = NumberFormat('#,##0.00');
    final dateFormat = DateFormat('MMM dd, yyyy');

    Color statusColor;
    switch (req.status) {
      case LoanStatus.pending: statusColor = Colors.orange; break;
      case LoanStatus.approved: statusColor = Colors.blue; break;
      case LoanStatus.released: statusColor = const Color(0xFF10B981); break;
      case LoanStatus.rejected: statusColor = Colors.red; break;
      case LoanStatus.fullyPaid: statusColor = Colors.green; break;
      case LoanStatus.overdue: statusColor = Colors.redAccent; break;
      default: statusColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              req.shareholderName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '₱${currencyFormat.format(req.requestedAmount)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textDark),
            ),
          ),
          Expanded(flex: 2, child: Text('${req.months} mo.', style: const TextStyle(fontSize: 12, color: AppTheme.textDark))),
          Expanded(
              flex: 2,
              child: Text(
                req.purpose.isEmpty ? 'N/A' : req.purpose,
                style: const TextStyle(fontSize: 11, color: AppTheme.textDark),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
          ),

          // Status Badge
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  req.status.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ),
          ),

          Expanded(flex: 2, child: Text(dateFormat.format(req.createdAt), style: const TextStyle(fontSize: 11, color: AppTheme.textMuted))),

          const Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}