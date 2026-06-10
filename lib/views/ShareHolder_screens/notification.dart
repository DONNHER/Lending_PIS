import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../models/notification_model.dart';
import '../../app_theme.dart';
import 'details_page/loan_details.dart';
import 'details_page/loan_request_approval.dart';

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
      if (auth.currentUser != null) {
        viewModel.fetchData(userId: auth.currentUser!.id);
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
          TextButton(
            onPressed: () => context.read<NotificationViewModel>().markAllAsRead(),
            child: const Text("Mark all as read", 
                style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13)),
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
          // Reactive fetch if user is logged in but profile isn't resolved yet
          if (auth.currentUser != null && viewModel.shareholderId == null && !viewModel.isLoading) {
            Future.microtask(() => viewModel.fetchData(userId: auth.currentUser!.id));
          }

          debugPrint('DEBUG: [NotificationScreen] UI Rebuild - isLoading: ${viewModel.isLoading}, notifications: ${viewModel.notifications.length}, shareholderId: ${viewModel.shareholderId}');
          
          if (viewModel.isLoading && viewModel.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          if (viewModel.shareholderId == null && !viewModel.isLoading) {
            debugPrint('DEBUG: [NotificationScreen] shareholderId is NULL');
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
                        if (auth.currentUser != null) {
                          viewModel.fetchData(userId: auth.currentUser!.id, forceRefresh: true);
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

          if (viewModel.notifications.isEmpty) {
            debugPrint('DEBUG: [NotificationScreen] notifications list is EMPTY');
            return RefreshIndicator(
              onRefresh: () => viewModel.fetchData(forceRefresh: true),
              child: Stack(
                children: [
                  ListView(), // Required for RefreshIndicator to work on empty list
                  _buildEmptyState(),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => viewModel.fetchData(forceRefresh: true),
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

    switch (n.type) {
      case 'comaker_request':
        iconData = Icons.person_add_rounded;
        iconColor = AppTheme.primary;
        break;
      case 'loan_status':
        iconData = Icons.account_balance_wallet_rounded;
        iconColor = Colors.green;
        break;
      case 'loan_request_submitted':
      case 'loan_request_created':
        iconData = Icons.notifications_active_rounded;
        iconColor = Colors.blueGrey;
        break;
      default:
        iconData = Icons.notifications_none_rounded;
        iconColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: n.isUnread ? Colors.white : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: n.isUnread ? AppTheme.primary.withOpacity(0.1) : const Color(0xFFF3F4F6)),
        boxShadow: n.isUnread
            ? [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.05),
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
            context.read<NotificationViewModel>().markAsRead(n.id);
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
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: iconColor, size: 22),
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
                                fontWeight: FontWeight.w800,
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
                          color: n.isUnread ? AppTheme.textDark.withOpacity(0.8) : AppTheme.textMuted,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        DateFormat('MMM dd • h:mm a').format(n.createdAt),
                        style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
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
    final loanId = n.metadata?['loan_request_id']?.toString();
    if (n.type == 'comaker_request') {
      if (loanId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoanRequestDetailsScreen(loanRequestId: loanId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Loan request ID not found."))
        );
      }
    } else if (n.type == 'loan_status' || n.type == 'loan_request_created' || n.type == 'loan_request_submitted') {
      if (loanId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActiveLoanDetailsScreen(loanId: loanId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Loan ID not found."))
        );
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFF3F4F6))),
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
