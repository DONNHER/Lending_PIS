import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../models/lending_models.dart';
import '../models/user_model.dart';
import '../repositories/shareholder_repository.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/lending_repository.dart';
import '../repositories/activity_log_repository.dart';
import '../repositories/auth_repository.dart';
import '../viewmodels/shareholder_detail_viewmodel.dart';
import 'loans_page.dart';
import 'activity_logs_page.dart';
import 'add_share_capital_page.dart';

class ShareholderDetailPage extends StatelessWidget {
  final String shareholderId;

  const ShareholderDetailPage({
    super.key,
    required this.shareholderId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ShareholderDetailViewModel(
        shareholderRepo: context.read<ShareholderRepository>(),
        transactionRepo: context.read<TransactionRepository>(),
        lendingRepo: context.read<LendingRepository>(),
        activityRepo: context.read<ActivityLogRepository>(),
        authRepo: context.read<AuthRepository>(),
        shareholderId: shareholderId,
      ),
      child: const _ShareholderDetailBody(),
    );
  }
}

class _ShareholderDetailBody extends StatelessWidget {
  const _ShareholderDetailBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<ShareholderDetailViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFFFDF8F5),
            body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          );
        }

        final sh = viewModel.shareholder;
        if (sh == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFFDF8F5),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF32211A)),
                onPressed: () => Navigator.maybePop(context),
              ),
              title: const Text('Shareholder Profile', style: TextStyle(color: Color(0xFF32211A), fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            body: Center(child: Text(viewModel.errorMessage ?? 'Shareholder not found')),
          );
        }

        final currencyFormat = NumberFormat.currency(symbol: '₱ ', decimalDigits: 2);
        final dateFormat = DateFormat('MMM dd, yyyy');

        return Scaffold(
          backgroundColor: const Color(0xFFFDF8F5),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF32211A)),
              onPressed: () => Navigator.maybePop(context),
            ),
            title: const Text('Shareholder Profile', style: TextStyle(color: Color(0xFF32211A), fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Column 1: User's Profile Card
                    Expanded(
                      flex: 1,
                      child: _buildInfoCard(
                        title: "User's Profile",
                        content: [
                          Center(
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: AppTheme.primary.withOpacity(0.1),
                              backgroundImage: sh.idImageUrl != null ? NetworkImage(sh.idImageUrl!) : null,
                              child: sh.idImageUrl == null ? const Icon(Icons.person, size: 40, color: AppTheme.primary) : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailItem('Full Name', sh.fullName),
                          _buildDetailItem('Email', sh.email, icon: Icons.email_outlined),
                          _buildDetailItem('Contact', sh.contactNumber, icon: Icons.phone_outlined),
                          _buildDetailItem('Status', 
                            sh.idImageUrl != null ? 'Active Member' : 'Needs Verification', 
                            isStatus: true,
                            onStatusTap: () => _showStatusDialog(context, viewModel)
                          ),
                          _buildDetailItem('Credit Score', '${sh.creditScore} - Excellent', showMeter: true),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Column 2: Share Capital Contributions & Investment Portfolio
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          _buildInfoCard(
                            title: "Capital Contributions",
                            trailing: TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddShareCapitalPage(
                                      shareholder: sh,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.account_balance_wallet_outlined, size: 16),
                              label: const Text('Add Capital', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.primary,
                                backgroundColor: AppTheme.primary.withOpacity(0.08),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            content: [
                              Text(currencyFormat.format(sh.totalShareCapital),
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                              const Text('Total Shares Owned', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                              const SizedBox(height: 16),
                              const Text('Last Contribution', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                              const Text('March 15, 2025', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildInfoCard(
                            title: "Investment Portfolio",
                            content: [
                              Text(currencyFormat.format(viewModel.estimatedPortfolio),
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                              const Text('(estimated value)', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                              const SizedBox(height: 16),
                              const Text('Invested Assets Allocation', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                              Text('${viewModel.investedFunds} Dynamic Funds', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              const SizedBox(height: 16),
                              const Text('ROI Rate of Return', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                              Text('+${viewModel.roi}% Total Gain', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Column 3: Loan Details Card
                    Expanded(
                      flex: 1,
                      child: _buildInfoCard(
                        title: "Loan Details",
                        trailing: TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoansPage(
                                  shareholderId: sh.id,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.list_alt_rounded, size: 16),
                          label: const Text('View Loans', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            backgroundColor: AppTheme.primary.withOpacity(0.08),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        content: [
                          Text(currencyFormat.format(viewModel.outstandingBalance),
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                          const Text('Outstanding Balance', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                          const SizedBox(height: 16),
                          const Text('Active Loans', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                          Text('${viewModel.activeLoans}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          const SizedBox(height: 16),
                          const Text('Repayment Due', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                          Text(dateFormat.format(viewModel.repaymentDue), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          const SizedBox(height: 20),
                          const Text('Payment Progress', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${currencyFormat.format(viewModel.totalPaid)} paid', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                              Text('${(viewModel.paymentProgress * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: viewModel.paymentProgress,
                            backgroundColor: Colors.grey[200],
                            color: Colors.green,
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Activity Log',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ActivityLogsPage(
                              shareholderId: sh.id,
                            ),
                          ),
                        );
                      },
                      child: const Text('See All', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildActivityTable(viewModel.activities),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () => Navigator.maybePop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Close', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showStatusDialog(BuildContext context, ShareholderDetailViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Account Status'),
        content: const Text('Change this user\'s account status?'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await viewModel.updateAccountStatus(UserStatus.active);
            },
            child: const Text('Active', style: TextStyle(color: Colors.green)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await viewModel.updateAccountStatus(UserStatus.inactive);
            },
            child: const Text('Inactive', style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await viewModel.updateAccountStatus(UserStatus.suspended);
            },
            child: const Text('Suspended', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, Widget? trailing, required List<Widget> content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing,
              ],
            ],
          ),
          const SizedBox(height: 20),
          ...content,
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {IconData? icon, bool isStatus = false, bool showMeter = false, VoidCallback? onStatusTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 4),
          InkWell(
            onTap: isStatus ? onStatusTap : null,
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: AppTheme.textMuted),
                  const SizedBox(width: 6),
                ],
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isStatus ? Colors.green : AppTheme.textDark,
                    decoration: isStatus ? TextDecoration.underline : null,
                  ),
                ),
                if (showMeter) ...[
                  const Spacer(),
                  const Icon(Icons.speed, size: 20, color: AppTheme.textMuted),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTable(List<TransactionModel> activities) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '₱ ', decimalDigits: 2);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF3E2723),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('Date', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Action', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 4, child: Text('Reference ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Amount', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          if (activities.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('No recent activities found', style: TextStyle(color: AppTheme.textMuted)),
            )
          else
            ...activities.take(2).map((tx) {
              final dynamic txDate = tx.date;
              final String typeLabel = tx.type.toString().toUpperCase();
              final String referenceId = tx.referenceId.toString();
              final String statusLabel = tx.status.toString();

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(txDate is DateTime ? dateFormat.format(txDate) : txDate.toString(), style: const TextStyle(fontSize: 14)),
                    ),
                    Expanded(flex: 2, child: Text(typeLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
                    Expanded(
                      flex: 4,
                      child: Text(
                        referenceId,
                        style: const TextStyle(fontSize: 14, color: AppTheme.textMuted, fontFamily: 'monospace'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(flex: 2, child: Text(currencyFormat.format(tx.amount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                    Expanded(
                      flex: 2,
                      child: Text(
                        statusLabel.toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: statusLabel.toLowerCase() == 'successful' || statusLabel.toLowerCase() == 'completed'
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
