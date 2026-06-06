import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../app_theme.dart';
import '../../viewmodels/shareholder_transaction_viewmodel.dart';
import 'details_page/loan_details.dart';
import 'details_page/repayment_details.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  static const Color textGrey = Color(0xFF9CA3AF);
  static const Color borderGrey = Color(0xFFF3F4F6);

  @override
  Widget build(BuildContext context) {
    // Connect to the ViewModel
    final viewModel = Provider.of<ShareholderTransactionViewModel>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Text("History",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        ),
        _buildFilterChips(viewModel),
        const SizedBox(height: 10),
        _buildDateHeader("Recent Transactions"),
        Expanded(
          child: viewModel.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : viewModel.transactions.isEmpty
                  ? _buildEmptyState()
                  : _buildTransactionList(viewModel),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: borderGrey),
          SizedBox(height: 16),
          Text("No transactions found", style: TextStyle(color: textGrey)),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ShareholderTransactionViewModel viewModel) {
    final filters = ["All", "Loans", "Repayments", "Capital Contributions"];
    return SizedBox(
      height: 64,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final filter = filters[index];
          bool isSelected = viewModel.selectedFilter == filter;
          return GestureDetector(
            onTap: () => viewModel.setFilter(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? AppTheme.primary : borderGrey),
                boxShadow: isSelected ? [BoxShadow(color: AppTheme.primary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))] : [],
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textDark,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: textGrey, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const Divider(height: 24, color: borderGrey),
        ],
      ),
    );
  }

  Widget _buildTransactionList(ShareholderTransactionViewModel viewModel) {
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱ ');
    final dateFormat = DateFormat('MMM dd, yyyy');

    return RefreshIndicator(
      onRefresh: () => viewModel.fetchData(),
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        itemCount: viewModel.transactions.length,
        itemBuilder: (context, index) {
          final item = viewModel.transactions[index];
          final type = item.type.toLowerCase();

          // Determine Card Styles
          IconData icon;
          Color iconColor;
          if (type.contains('loan')) {
            icon = Icons.south_west_rounded;
            iconColor = Colors.blue;
          } else if (type.contains('payment') || type.contains('repayment')) {
            icon = Icons.north_east_rounded;
            iconColor = Colors.green;
          } else if (type.contains('capital')) {
            icon = Icons.account_balance_rounded;
            iconColor = const Color(0xFFC06C4D);
          } else {
            icon = Icons.receipt_long_rounded;
            iconColor = textGrey;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderGrey),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: InkWell(
              onTap: () {
                if (type.contains('payment') || type.contains('repayment') || type.contains('capital')) {
                  // Repayments and Capital Contributions go to RepaymentDetailsScreen (in repayment_details.dart)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RepaymentDetailsScreen(transaction: item),
                    ),
                  );
                } else if (type.contains('loan')) {
                  // Loan transactions go to ActiveLoanDetailsScreen (in loan_details.dart)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ActiveLoanDetailsScreen(loanId: item.referenceId),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.type,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                          const SizedBox(height: 4),
                          Text(dateFormat.format(item.date), style: const TextStyle(fontSize: 11, color: textGrey)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(currencyFormat.format(item.amount),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.textDark)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(item.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.status.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(item.status), 
                              fontSize: 9, 
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'successful':
      case 'completed':
      case 'released':
        return Colors.green;
      case 'pending':
      case 'awaiting':
      case 'under review':
        return Colors.orange;
      case 'failed':
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
