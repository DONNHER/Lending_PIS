import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:capstone_application/viewmodels/auth_viewmodel.dart';
import 'package:capstone_application/viewmodels/notification_viewmodel.dart';
import 'package:capstone_application/models/notification_model.dart';
import 'package:capstone_application/app_theme.dart';
import 'package:capstone_application/models/transaction_model.dart';
import 'details_page/loan_details.dart';
import 'details_page/loan_request_approval.dart';
import 'details_page/loan_request_details.dart';
import '../../../widgets/transaction_detail_dialog.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    _triggerFetch();
  }

  void _triggerFetch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthViewModel>();
      final viewModel = context.read<NotificationViewModel>();
      final shareholderId = auth.currentUser?.shareholder?.id;
      if (shareholderId != null) {
        viewModel.loadNotifications(shareholderId: shareholderId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Notifications",
            style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w800)),
        actions: [
          Consumer<NotificationViewModel>(
            builder: (context, viewModel, _) {
              final hasUnread = viewModel.notifications.any((n) => n.isUnread);
              return TextButton(
                onPressed: hasUnread ? () => viewModel.markAllAsRead() : null,
                child: Text(
                    "Mark all as read",
                    style: TextStyle(
                        color: hasUnread ? AppTheme.primary : AppTheme.textMuted.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w700,
                        fontSize: 13
                    )
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 22),
            onPressed: () => _showClearAllDialog(context),
            tooltip: 'Clear all notifications',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Consumer2<NotificationViewModel, AuthViewModel>(
        builder: (context, viewModel, auth, _) {
          final shareholderId = auth.currentUser?.shareholder?.id;
          if (shareholderId != null && viewModel.shareholderId == null && !viewModel.isLoading) {
            Future.microtask(() => viewModel.loadNotifications(shareholderId: shareholderId));
          }

          if (viewModel.isLoading && viewModel.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          if (viewModel.shareholderId == null && !viewModel.isLoading) {
            return _buildErrorState(context, auth, viewModel);
          }

          if (viewModel.notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => viewModel.loadNotifications(shareholderId: shareholderId!, forceRefresh: true),
              child: Stack(
                children: [
                  ListView(),
                  _buildEmptyState(),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => viewModel.loadNotifications(shareholderId: shareholderId!, forceRefresh: true),
            color: AppTheme.primary,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: viewModel.notifications.length,
              itemBuilder: (context, index) {
                return _buildThemedNotificationCard(context, viewModel.notifications[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, AuthViewModel auth, NotificationViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_search_rounded, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            const Text(
              "Resolving your profile...",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              "We're setting up your notification feed. This should only take a moment.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final shareholderId = auth.currentUser?.shareholder?.id;
                if (shareholderId != null) {
                  viewModel.loadNotifications(shareholderId: shareholderId, forceRefresh: true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Retry Connection"),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear Notifications", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to delete all notifications? This action cannot be undone."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              context.read<NotificationViewModel>().deleteAllNotifications();
              Navigator.pop(context);
            },
            child: const Text("Clear All", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildThemedNotificationCard(BuildContext context, NotificationModel n) {
    IconData iconData;
    Color iconColor;

    switch (n.type?.toLowerCase()) {
      case 'comaker_request':
        iconData = Icons.person_add_rounded;
        iconColor = AppTheme.primary;
        break;
      case 'loan_status':
      case 'loan_released':
      case 'loan_disbursed':
      case 'loan_approved':
        iconData = Icons.account_balance_wallet_rounded;
        iconColor = Colors.green;
        break;
      case 'loan_request_submitted':
      case 'loan_request_created':
        iconData = Icons.notifications_active_rounded;
        iconColor = Colors.blueGrey;
        break;
      case 'payment_received':
      case 'repayment':
        iconData = Icons.payments_rounded;
        iconColor = Colors.orange;
        break;
      default:
        iconData = n.category == NotificationCategory.transaction
            ? Icons.receipt_long_rounded
            : Icons.notifications_none_rounded;
        iconColor = n.category == NotificationCategory.transaction
            ? Colors.teal
            : Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: n.isUnread ? Colors.white : const Color(0xFFF3F4F6).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: n.isUnread
                ? AppTheme.primary.withValues(alpha: 0.2)
                : Colors.transparent
        ),
        boxShadow: n.isUnread
            ? [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (n.isUnread) {
              context.read<NotificationViewModel>().markAsRead(n.id);
            }
            _handleTap(context, n);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: n.isUnread ? iconColor.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                      iconData,
                      color: n.isUnread ? iconColor : Colors.grey.shade400,
                      size: 22
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              style: TextStyle(
                                fontWeight: n.isUnread ? FontWeight.w800 : FontWeight.w600,
                                fontSize: 14,
                                color: n.isUnread ? AppTheme.textDark : AppTheme.textMuted,
                              ),
                            ),
                          ),
                          if (n.isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        n.content,
                        style: TextStyle(
                          color: n.isUnread ? AppTheme.textDark.withValues(alpha: 0.8) : AppTheme.textMuted.withValues(alpha: 0.7),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        DateFormat('MMM dd • h:mm a').format(n.createdAt),
                        style: TextStyle(
                            fontSize: 11,
                            color: n.isUnread ? Colors.grey.shade600 : Colors.grey.shade400,
                            fontWeight: n.isUnread ? FontWeight.w600 : FontWeight.w500
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, NotificationModel n) {
    final metadata = n.metadata ?? {};

    // Robust Extraction of IDs from Metadata
    final String? loanRequestId = metadata['loan_request_id']?.toString() ?? metadata['request_id']?.toString();
    final String? loanId = metadata['loan_id']?.toString();

    // Prefer specific transaction keys over generic 'id'
    final String? transactionId = metadata['transaction_id']?.toString() ??
        metadata['tx_id']?.toString() ??
        metadata['payment_id']?.toString();

    // Helper to validate that an ID is a genuine database identifier and NOT the notification's own UUID
    bool isValidDbId(String? id) {
      if (id == null) return false;
      if (id == n.id) return false;
      return true;
    }

    final String? potentialId = isValidDbId(metadata['id']?.toString()) ? metadata['id']?.toString() : null;
    final String? refId = metadata['reference_id']?.toString();
    final String type = n.type?.toLowerCase() ?? '';
    final bool isTransactionCategory = n.category == NotificationCategory.transaction;

    debugPrint('DEBUG: [NotificationScreen] _handleTap - type: $type, category: ${n.category}, loanId: $loanId, transactionId: $transactionId, refId: $refId');

    // 0. Check for embedded transaction object directly in metadata
    if (metadata['transaction'] is Map) {
      try {
        final tx = TransactionModel.fromJson(Map<String, dynamic>.from(metadata['transaction']));
        showDialog(
          context: context,
          builder: (context) => TransactionDetailDialog(transaction: tx),
        );
        return;
      } catch (e) {
        debugPrint('DEBUG: [NotificationScreen] Error parsing embedded transaction: $e');
      }
    }

    // 1. Loan Request / Pending Submission notifications -> Route to LoanRequestStatusScreen
    if (type.contains('loan_request') || type.contains('request_submitted') || type.contains('request_created')) {
      final targetRequestId = loanRequestId ?? loanId ?? potentialId ?? refId;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoanRequestStatusScreen(
            loanId: targetRequestId,
            isPending: true,
            borrowerName: metadata['borrower_name']?.toString(),
          ),
        ),
      );
      return;
    }

    // 2. Transaction-specific notifications (Payments, Capital, or Transaction Category)
    if (type.contains('payment') ||
        type.contains('repayment') ||
        type.contains('capital') ||
        type.contains('transaction') ||
        isTransactionCategory) {

      final targetTxId = transactionId ?? potentialId ?? refId;
      if (isValidDbId(targetTxId)) {
        _handleTransactionTap(context, targetTxId!);
        return;
      }
    }

    // 3. Co-maker requests
    if (type.contains('comaker')) {
      final targetRequestId = loanRequestId ?? potentialId ?? refId;
      if (isValidDbId(targetRequestId)) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => LoanRequestDetailsScreen(loanRequestId: targetRequestId!)));
      } else {
        _showError(context, "Loan request ID not found or invalid.");
      }
      return;
    }

    // 4. Loan Status / Updates (Active Loans)
    if (type.contains('loan') || type.contains('disbursed') || type.contains('released') || type.contains('status')) {
      final targetLoanId = loanId ?? loanRequestId ?? refId;

      if (isValidDbId(targetLoanId)) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ActiveLoanDetailsScreen(loanId: targetLoanId!)
          ),
        );
      } else {
        _showError(context, "Loan ID reference is missing or invalid.");
      }
      return;
    }

    // 5. Fallback: If we have a transaction-like ID, try viewing it as a transaction
    if (isValidDbId(transactionId) || (isTransactionCategory && isValidDbId(potentialId))) {
      _handleTransactionTap(context, transactionId ?? potentialId!);
      return;
    }

    // 6. General Fallback
    if (isValidDbId(potentialId)) {
      _handleTransactionTap(context, potentialId!);
      return;
    }

    _showError(context, "No valid details found for this notification.");
  }

  void _handleTransactionTap(BuildContext context, String referenceId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveLoanDetailsScreen(loanId: referenceId),
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF3F4F6))
            ),
            child: Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 24),
          const Text("No notifications yet",
              style: TextStyle(color: AppTheme.textDark, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text("We'll notify you when something important happens.",
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}