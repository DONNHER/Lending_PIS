import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:capstone_application/app_theme.dart';
import 'package:capstone_application/viewmodels/shareholder_transaction_viewmodel.dart';
import 'package:capstone_application/viewmodels/auth_viewmodel.dart';
import 'details_page/loan_details.dart';
import '../../../widgets/transaction_detail_dialog.dart';
import 'details_page/loan_request_approval.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  static const Color textGrey = Color(0xFF9CA3AF);
  static const Color borderGrey = Color(0xFFF3F4F6);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthViewModel>();
      final viewModel = context.read<ShareholderTransactionViewModel>();
      if (auth.currentUser != null) {
        viewModel.fetchData(userId: auth.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Consumer<ShareholderTransactionViewModel>(
        builder: (context, viewModel, child) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Text("History",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  ),
                  _buildFilterChips(viewModel),
                  
                  if (viewModel.selectedFilter == 'Loan Requests') ...[
                    const SizedBox(height: 4),
                    _buildRoleSelector(viewModel),
                  ],

                  const SizedBox(height: 10),
                  _buildDateHeader(viewModel.selectedFilter == 'Loan Requests' 
                      ? "Recent Requests" 
                      : "Recent Transactions"),
                      
                  Expanded(
                    child: _buildBody(viewModel),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(ShareholderTransactionViewModel viewModel) {
    if (viewModel.isLoading && !viewModel.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (viewModel.errorMessage != null && (viewModel.transactions.isEmpty && viewModel.loanRequests.isEmpty)) {
      return _buildErrorState(viewModel);
    }

    if (viewModel.selectedFilter == 'Loan Requests') {
      return viewModel.loanRequests.isEmpty ? _buildEmptyState("No loan requests found") : _buildLoanRequestList(viewModel);
    } else {
      return viewModel.transactions.isEmpty ? _buildEmptyState("No transactions found") : _buildTransactionList(viewModel);
    }
  }

  Widget _buildErrorState(ShareholderTransactionViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              viewModel.errorMessage ?? "An error occurred",
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final auth = context.read<AuthViewModel>();
                if (auth.currentUser != null) {
                  viewModel.fetchData(userId: auth.currentUser!.id, forceRefresh: true);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: const Text("Retry"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history_rounded, size: 64, color: borderGrey),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: textGrey)),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ShareholderTransactionViewModel viewModel) {
    final filters = ["All", "Loans", "Repayments", "Capital Contributions", "Loan Requests"];
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
                boxShadow: isSelected ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))] : [],
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

  Widget _buildRoleSelector(ShareholderTransactionViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRoleButton(
              label: 'Borrower',
              isSelected: viewModel.roleFilter == 'Borrower',
              onTap: () => viewModel.setRoleFilter('Borrower'),
            ),
            _buildRoleButton(
              label: 'Co-maker',
              isSelected: viewModel.roleFilter == 'Co-maker',
              onTap: () => viewModel.setRoleFilter('Co-maker'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleButton({required String label, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppTheme.primary : textGrey,
          ),
        ),
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
      onRefresh: () {
        final auth = context.read<AuthViewModel>();
        if (auth.currentUser != null) {
          return viewModel.fetchData(userId: auth.currentUser!.id, forceRefresh: true);
        }
        return Future.value();
      },
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        itemCount: viewModel.transactions.length,
        itemBuilder: (context, index) {
          final item = viewModel.transactions[index];
          final type = item.type.toLowerCase();

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
                BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: InkWell(
              onTap: () {
                if (type.contains('payment') || type.contains('repayment') || type.contains('capital')) {
                  showDialog(
                    context: context,
                    builder: (context) => TransactionDetailDialog(transaction: item),
                  );
                } else if (type.contains('loan')) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ActiveLoanDetailsScreen(loanId: item.referenceId ?? '')));
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.type, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                          const SizedBox(height: 4),
                          Text(dateFormat.format(item.date), style: const TextStyle(fontSize: 11, color: textGrey)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(currencyFormat.format(item.amount), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.textDark)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: _getStatusColor(item.status).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(item.status.toUpperCase(), style: TextStyle(color: _getStatusColor(item.status), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
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

  Widget _buildLoanRequestList(ShareholderTransactionViewModel viewModel) {
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱ ');
    final dateFormat = DateFormat('MMM dd, yyyy');

    return RefreshIndicator(
      onRefresh: () {
        final auth = context.read<AuthViewModel>();
        if (auth.currentUser != null) {
          return viewModel.fetchData(userId: auth.currentUser!.id, forceRefresh: true);
        }
        return Future.value();
      },
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        itemCount: viewModel.loanRequests.length,
        itemBuilder: (context, index) {
          final item = viewModel.loanRequests[index];
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderGrey),
            ),
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoanRequestDetailsScreen(loanRequestId: item.id))),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.assignment_outlined, color: AppTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Loan Request", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                          const SizedBox(height: 4),
                          Text(dateFormat.format(item.createdAt), style: const TextStyle(fontSize: 11, color: textGrey)),
                          if (viewModel.roleFilter == 'Co-maker')
                             Padding(
                               padding: const EdgeInsets.only(top: 2),
                               child: Text("From: ${item.shareholderName}", style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.w600)),
                             ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(currencyFormat.format(item.requestedAmount), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.textDark)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: _getStatusColor(item.status.name).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(item.status.name.toUpperCase(), style: TextStyle(color: _getStatusColor(item.status.name), fontSize: 9, fontWeight: FontWeight.w900)),
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
      case 'approved':
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
