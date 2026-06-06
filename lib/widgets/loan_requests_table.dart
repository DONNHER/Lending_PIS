import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../models/lending_models.dart';

class LoanRequestsTable extends StatelessWidget {
  final List<LoanRequestModel> loanRequests;
  final Function(LoanRequestModel) onView;

  const LoanRequestsTable({
    super.key,
    required this.loanRequests,
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
              Expanded(flex: 1, child: Text('ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 3, child: Text('Client', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 2, child: Text('Amount', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 2, child: Text('Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 1, child: Text('Rate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 2, child: Text('Created At', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 1, child: Align(alignment: Alignment.centerRight, child: Text('Actions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))),
            ],
          ),
        ),
        // Table Body
        Expanded(
          child: loanRequests.isEmpty 
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No records found', style: TextStyle(color: AppTheme.textMuted)),
                ),
              )
            : ListView.separated(
                itemCount: loanRequests.length,
                padding: EdgeInsets.zero,
                separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () => onView(loanRequests[index]),
                    child: _buildRow(loanRequests[index]),
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
    
    final displayId = req.id.length > 7 
        ? '${req.id.substring(0, 7)}...' 
        : req.id;

    Color statusColor;
    switch (req.status) {
      case LoanStatus.approved:
      case LoanStatus.released:
      case LoanStatus.fullyPaid:
        statusColor = AppTheme.success;
        break;
      case LoanStatus.pending:
        statusColor = const Color(0xFFF4A460);
        break;
      case LoanStatus.rejected:
      case LoanStatus.cancelled:
        statusColor = AppTheme.error;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text(displayId, style: const TextStyle(fontSize: 12, color: AppTheme.textDark))),
          Expanded(
            flex: 3,
            child: Text(
              req.shareholderName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '₱${currencyFormat.format(req.requestedAmount)}', 
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.2)),
                ),
                child: Text(
                  req.status.name.toUpperCase(),
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
            flex: 1,
            child: Text(
              '${(req.interestRate * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              dateFormat.format(req.createdAt),
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ActionButton(icon: Icons.chevron_right, color: AppTheme.textMuted, onTap: () => onView(req)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(icon, size: 18, color: color),
    );
  }
}
