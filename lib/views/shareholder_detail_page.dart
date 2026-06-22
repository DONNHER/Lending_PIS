import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../models/user_model.dart';
import '../models/activity_log_model.dart';
import '../repositories/shareholder_repository.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/lending_repository.dart';
import '../repositories/activity_log_repository.dart';
import '../repositories/auth_repository.dart';
import '../viewmodels/shareholder_detail_viewmodel.dart';
import '../services/email_service.dart';
import 'loans_page.dart';
import 'activity_logs_page.dart';
import 'add_share_capital_page.dart';
import 'address_selector_page.dart';

class ShareholderDetailPage extends StatelessWidget {
  final String? shareholderId;
  final String? userId;

  const ShareholderDetailPage({
    super.key,
    this.shareholderId,
    this.userId,
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
        emailService: context.read<EmailService>(),
        shareholderId: shareholderId,
        userId: userId,
      ),
      child: const _ShareholderDetailBody(),
    );
  }
}

class _ShareholderDetailBody extends StatefulWidget {
  const _ShareholderDetailBody();

  @override
  State<_ShareholderDetailBody> createState() => _ShareholderDetailBodyState();
}

class _ShareholderDetailBodyState extends State<_ShareholderDetailBody> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleAddressEdit(BuildContext context, ShareholderDetailViewModel viewModel) async {
    final newAddress = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const AddressSelectorPage()),
    );

    if (newAddress != null && context.mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Confirm Address Update', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Are you sure you want to update the address to:'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(newAddress, style: const TextStyle(fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Confirm', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmed == true && context.mounted) {
        final success = await viewModel.updateAddress(newAddress);
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address updated successfully')),
          );
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(viewModel.errorMessage ?? 'Failed to update address')),
          );
        }
      }
    }
  }

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
            controller: _scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Column 1: User's Profile Card
                      Expanded(
                        flex: 1,
                        child: _buildInfoCard(
                          title: "User's Profile",
                          isFullHeight: true,
                          content: [
                            Center(
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor: AppTheme.primary.withOpacity(0.1),
                                backgroundImage: sh.avatarUrl != null ? NetworkImage(sh.avatarUrl!) : null,
                                child: sh.avatarUrl == null ? const Icon(Icons.person, size: 40, color: AppTheme.primary) : null,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildDetailItem('Full Name', sh.fullName),
                            _buildDetailItem('Email', sh.email, icon: Icons.email_outlined),
                            _buildDetailItem('Contact', sh.contactNumber, icon: Icons.phone_outlined),
                            _buildDetailItem('Status', 
                              sh.status, 
                              isStatus: true,
                              onStatusTap: () => _showStatusDialog(context, viewModel)
                            ),
                            _buildDetailItem('Credit Score', '${sh.creditScore} - Excellent', showMeter: true),
                            _buildDetailItem(
                              'Address', 
                              sh.address.isEmpty ? 'No address provided' : sh.address,
                              icon: Icons.location_on_outlined,
                              trailing: IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.primary),
                                onPressed: () => _handleAddressEdit(context, viewModel),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),

                      // Column 2: Share Capital Contributions & Identity Verification
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            _buildInfoCard(
                              title: "Capital Contributions",
                              trailing: TextButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddShareCapitalPage(
                                        shareholder: sh,
                                      ),
                                    ),
                                  );
                                  
                                  if (result == true && context.mounted) {
                                    viewModel.fetchDetails();
                                  }
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
                            // Identity Verification Card
                            Expanded(
                              child: _buildInfoCard(
                                title: "Identity Verification",
                                isFullHeight: true,
                                trailing: TextButton.icon(
                                  onPressed: () {
                                    debugPrint('Update ID clicked');
                                  },
                                  icon: const Icon(Icons.edit_outlined, size: 16),
                                  label: const Text('Update', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.primary,
                                    backgroundColor: AppTheme.primary.withOpacity(0.08),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                                content: [
                                  const Text('Valid Identification Document', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                                  const SizedBox(height: 12),
                                  if (sh.idImageUrl != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        sh.idImageUrl!,
                                        height: 150,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            height: 150,
                                            color: Colors.grey[100],
                                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          height: 150,
                                          color: Colors.grey[100],
                                          child: const Icon(Icons.broken_image_outlined, size: 40, color: AppTheme.textMuted),
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      height: 150,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                                      ),
                                      child: const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.badge_outlined, size: 40, color: AppTheme.textMuted),
                                          SizedBox(height: 8),
                                          Text('No ID Image Uploaded', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  const Row(
                                    children: [
                                      Icon(Icons.verified_user_outlined, size: 14, color: Colors.green),
                                      SizedBox(width: 4),
                                      Text('ID Verified by System', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ],
                              ),
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
                          isFullHeight: true,
                          trailing: TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoansPage(
                                    shareholderId: sh.id,
                                    shareholderName: sh.fullName,
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
                ),
                const SizedBox(height: 40),
                // Activity Log Section
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
                              userId: sh.userId,
                            ),
                          ),
                        );
                      },
                      child: const Text('See All', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildActivityLogTable(viewModel.recentActivityLogs),
                const SizedBox(height: 40),
                Center(
                  child: IconButton(
                    onPressed: () {
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: const Icon(Icons.keyboard_arrow_up, size: 32, color: AppTheme.primary),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                      shadowColor: Colors.black.withOpacity(0.1),
                      elevation: 4,
                    ),
                    tooltip: 'Scroll to top',
                  ),
                ),
                const SizedBox(height: 40),
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

  Widget _buildInfoCard({required String title, Widget? trailing, required List<Widget> content, bool isFullHeight = false}) {
    return Container(
      width: double.infinity,
      height: isFullHeight ? double.infinity : null, // Forces the container to fill height if requested
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

  Widget _buildDetailItem(
    String label, 
    String value, {
    IconData? icon, 
    bool isStatus = false, 
    bool showMeter = false, 
    VoidCallback? onStatusTap,
    Widget? trailing,
  }) {
    Color statusColor = AppTheme.textDark;
    if (isStatus) {
      final v = value.toLowerCase();
      if (v == 'active') statusColor = Colors.green;
      else if (v == 'pending') statusColor = const Color(0xFFC06C4D); // Match theme for pending
      else statusColor = Colors.orange;
    }

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(icon, size: 16, color: AppTheme.textMuted),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                      decoration: isStatus ? TextDecoration.underline : null,
                    ),
                  ),
                ),
                if (showMeter) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.speed, size: 20, color: AppTheme.textMuted),
                ],
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing,
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLogTable(List<ActivityLogModel> logs) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

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
              color: Color(0xFFC06C4D),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Date & Time', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('Action', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 6, child: Text('Description', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          if (logs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('No recent logs found', style: TextStyle(color: AppTheme.textMuted)),
            )
          else
            ...logs.take(5).map((log) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(dateFormat.format(log.createdAt), style: const TextStyle(fontSize: 13)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(log.action, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    Expanded(
                      flex: 6,
                      child: Text(
                        log.description,
                        style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
