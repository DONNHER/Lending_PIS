import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:capstone_application/app_theme.dart';
import 'package:capstone_application/viewmodels/loan_details_viewmodel.dart';
import 'package:capstone_application/models/lending_models.dart';

class ActiveLoanDetailsScreen extends StatefulWidget {
  final String loanId;

  const ActiveLoanDetailsScreen({super.key, required this.loanId});

  @override
  State<ActiveLoanDetailsScreen> createState() => _ActiveLoanDetailsScreenState();
}

class _ActiveLoanDetailsScreenState extends State<ActiveLoanDetailsScreen> {
  static const Color primaryGreen = Color(0xFF2ECC71);
  static const Color bgLight = Color(0xFFF9FAFB);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color borderGrey = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    final viewModel = context.read<LoanDetailsViewModel>();
    await viewModel.fetchLoanDetails(widget.loanId, forceRefresh: forceRefresh);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoanDetailsViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: bgLight,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDark, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text("Loan Details",
                style: TextStyle(color: AppTheme.textDark, fontSize: 18, fontWeight: FontWeight.w800)),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
                onPressed: () => _loadData(forceRefresh: true),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: viewModel.isLoading && !viewModel.isInitialized
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : viewModel.errorMessage != null && viewModel.loan == null && viewModel.request == null
              ? _buildErrorView(viewModel)
              : _buildContentView(viewModel),
        );
      },
    );
  }

  Widget _buildErrorView(LoanDetailsViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              viewModel.errorMessage ?? "Failed to load loan details.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _loadData(forceRefresh: true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: const Text("Retry"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildContentView(LoanDetailsViewModel viewModel) {
    final dynamic loan = viewModel.loan;
    final dynamic request = viewModel.request;
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    if (loan == null && request == null) {
      return _buildErrorView(viewModel);
    }

    return RefreshIndicator(
      onRefresh: () => _loadData(forceRefresh: true),
      color: AppTheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (loan != null) ...[
              _buildAestheticStatusHeader(loan, currencyFormat),
              const SizedBox(height: 24),
              _buildAestheticPaymentProgress(loan, currencyFormat),
            ] else if (request != null) ...[
              _buildRequestOnlyHeader(request, currencyFormat),
            ],
            const SizedBox(height: 32),
            const Text("Financial Breakdown",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
            const SizedBox(height: 16),
            _buildBreakdownCard(loan, request, currencyFormat),
            const SizedBox(height: 32),
            if (viewModel.paymentHistory.isNotEmpty) ...[
              const Text("Payment History",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
              const SizedBox(height: 16),
              _buildPaymentHistoryList(viewModel.paymentHistory, currencyFormat),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAestheticStatusHeader(dynamic loan, NumberFormat format) {
    final double amount = loan.monthlyAmortization;
    final DateTime? dueDate = loan.nextRepaymentDate;
    String dueLabel = "No upcoming payment";
    Color statusColor = Colors.orange;

    if (dueDate != null) {
      final days = dueDate.difference(DateTime.now()).inDays;
      if (days == 0) {
        dueLabel = "Due today";
        statusColor = Colors.redAccent;
      } else if (days > 0) {
        dueLabel = "Due in $days days";
      } else {
        dueLabel = "Overdue by ${days.abs()} days";
        statusColor = Colors.red;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderGrey),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          const Text("UPCOMING PAYMENT",
              style: TextStyle(color: textGrey, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(format.format(amount),
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppTheme.textDark)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule_rounded, size: 14, color: statusColor),
                const SizedBox(width: 6),
                Text(dueLabel,
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestOnlyHeader(dynamic request, NumberFormat format) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderGrey),
      ),
      child: Column(
        children: [
          const Text("LOAN STATUS",
              style: TextStyle(color: textGrey, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Text(request.status.name.toUpperCase(),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _getComakerStatusColor(request.status))),
          const SizedBox(height: 8),
          Text("Requested: ${format.format(request.requestedAmount)}",
              style: const TextStyle(color: textGrey, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildAestheticPaymentProgress(dynamic loan, NumberFormat format) {
    final double total = loan.totalRepayable;
    final double remaining = loan.remainingBalance;
    final double paid = total - remaining;
    final double progress = total > 0 ? (paid / total) : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderGrey),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Payment Progress", style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textDark)),
              Text("${(progress * 100).toStringAsFixed(0)}%",
                  style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.w900, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(6)),
              ),
              LayoutBuilder(builder: (context, constraints) {
                return Container(
                  height: 12,
                  width: constraints.maxWidth * progress,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [primaryGreen, primaryGreen.withValues(alpha: 0.7)]),
                    borderRadius: BorderRadius.circular(6),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _progressInfoItem("Amount Paid", format.format(paid), primaryGreen)),
              Container(height: 30, width: 1, color: borderGrey),
              Expanded(child: _progressInfoItem("Balance Left", format.format(remaining), Colors.redAccent)),
            ],
          )
        ],
      ),
    );
  }

  Widget _progressInfoItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: textGrey, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: valueColor)),
      ],
    );
  }

  Widget _buildBreakdownCard(dynamic loan, dynamic request, NumberFormat format) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderGrey),
      ),
      child: Column(
        children: [
          if (request != null) ...[
            _aestheticDetailRow(Icons.account_balance_wallet_outlined, "Principal", format.format(request.requestedAmount)),
            _aestheticDetailRow(Icons.percent_rounded, "Interest Rate", "${(request.interestRate * 100).toStringAsFixed(1)}% p.m."),
            _aestheticDetailRow(Icons.calendar_month_outlined, "Duration", "${request.tenureMonths} Months"),
            _aestheticDetailRow(Icons.payments_outlined, "Monthly Payment",
                format.format((request.requestedAmount * (1 + request.interestRate * request.tenureMonths)) / request.tenureMonths)),
            _aestheticDetailRow(Icons.receipt_outlined, "Processing Fee", "₱150.00"),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 24)),
            _aestheticDetailRow(Icons.summarize_outlined, "Total Repayable",
                format.format(request.requestedAmount * (1 + request.interestRate * request.tenureMonths) + 150),
                isBold: true),
          ] else if (loan != null) ...[
            _aestheticDetailRow(Icons.account_balance_wallet_outlined, "Principal", format.format(loan.principalAmount)),
            _aestheticDetailRow(Icons.calendar_month_outlined, "Duration", "${loan.tenureMonths} Months"),
            _aestheticDetailRow(Icons.payments_outlined, "Monthly Payment", format.format(loan.monthlyAmortization)),
            _aestheticDetailRow(Icons.receipt_long_outlined, "Total Repayable", format.format(loan.totalRepayable)),
            _aestheticDetailRow(Icons.money_off_csred_outlined, "Remaining", format.format(loan.remainingBalance), isBold: true),
          ],
        ],
      ),
    );
  }

  Widget _aestheticDetailRow(IconData icon, String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: AppTheme.primary),
          ),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(color: textGrey, fontWeight: FontWeight.w500, fontSize: 14)),
          const Spacer(),
          Text(value, style: TextStyle(
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            fontSize: isBold ? 16 : 14,
            color: isBold ? AppTheme.primary : AppTheme.textDark,
          )),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryList(List<dynamic> history, NumberFormat format) {
    return Column(
      children: history.map((dynamic tx) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderGrey),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: primaryGreen.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_outline_rounded, color: primaryGreen, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Loan Repayment", style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                    const SizedBox(height: 2),
                    Text(DateFormat('MMM dd, yyyy').format(tx.date), style: const TextStyle(color: textGrey, fontSize: 11)),
                  ],
                ),
              ),
              Text(format.format(tx.amount),
                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textDark, fontSize: 14)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getComakerStatusColor(ComakerStatus status) {
    switch (status) {
      case ComakerStatus.approved: return Colors.blue;
      case ComakerStatus.released: return primaryGreen;
      case ComakerStatus.rejected: return Colors.red;
      case ComakerStatus.cancelled: return Colors.grey;
      default: return Colors.orange;
    }
  }
}