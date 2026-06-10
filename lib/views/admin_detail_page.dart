import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:capstone_application/app_theme.dart';
import 'package:capstone_application/models/user_model.dart';
import 'package:capstone_application/repositories/shareholder_repository.dart';
import 'package:capstone_application/repositories/transaction_repository.dart';
import 'package:capstone_application/repositories/lending_repository.dart';
import 'package:capstone_application/repositories/activity_log_repository.dart';
import 'package:capstone_application/repositories/auth_repository.dart';
import 'package:capstone_application/viewmodels/shareholder_detail_viewmodel.dart';
import 'package:capstone_application/viewmodels/auth_viewmodel.dart';
import 'package:capstone_application/views/activity_logs_page.dart';
import 'package:capstone_application/views/mfa_enrollment_page.dart';

class AdminDetailPage extends StatelessWidget {
  final String userId;

  const AdminDetailPage({
    super.key,
    required this.userId,
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
        userId: userId,
      ),
      child: const _AdminDetailBody(),
    );
  }
}

class _AdminDetailBody extends StatelessWidget {
  const _AdminDetailBody();

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final detailViewModel = context.read<ShareholderDetailViewModel>();
    // Check if the profile being viewed belongs to the logged-in user
    final isMe = authViewModel.currentUser?.id == detailViewModel.userId;

    return Consumer<ShareholderDetailViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFFFDF8F5),
            body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          );
        }

        final admin = viewModel.shareholder;
        if (admin == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFFDF8F5),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF32211A)),
                onPressed: () => Navigator.maybePop(context),
              ),
              title: const Text('Admin Profile', style: TextStyle(color: Color(0xFF32211A), fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            body: Center(child: Text(viewModel.errorMessage ?? 'Administrator not found')),
          );
        }

        // admin.status is a String in ShareholderModel, so we convert it to UserStatus enum
        final adminStatus = UserStatus.fromString(admin.status);

        return Scaffold(
          backgroundColor: const Color(0xFFFDF8F5),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF32211A)),
              onPressed: () => Navigator.maybePop(context),
            ),
            title: const Text('Administrator Management', style: TextStyle(color: Color(0xFF32211A), fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildInfoCard(
                        title: "Account Identity",
                        content: [
                          Center(
                            child: CircleAvatar(
                              radius: 45,
                              backgroundColor: AppTheme.primary.withOpacity(0.1),
                              backgroundImage: admin.idImageUrl != null && admin.idImageUrl!.isNotEmpty 
                                  ? NetworkImage(admin.idImageUrl!) : null,
                              child: (admin.idImageUrl == null || admin.idImageUrl!.isEmpty) 
                                  ? const Icon(Icons.admin_panel_settings_rounded, size: 45, color: AppTheme.primary) : null,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildDetailItem('Full Name', admin.fullName),
                          _buildDetailItem('Username', admin.email.split('@')[0], icon: Icons.alternate_email),
                          _buildDetailItem('Email Address', admin.email, icon: Icons.email_outlined),
                          _buildDetailItem('Contact', admin.contactNumber, icon: Icons.phone_outlined),
                          _buildDetailItem('Operational Status', 
                            adminStatus.name.toUpperCase(), 
                            isStatus: true,
                            statusValue: adminStatus,
                            onStatusTap: () => _showStatusDialog(context, viewModel)
                          ),
                          _buildDetailItem('Administrative Role', admin.role.toUpperCase(), icon: Icons.security_rounded),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          _buildInfoCard(
                            title: "Access Control",
                            content: [
                              _buildPermissionItem('User Management', true),
                              _buildPermissionItem('Financial Overviews', true),
                              _buildPermissionItem('Loan Approvals', true),
                              _buildPermissionItem('System Configuration', admin.role.toLowerCase() == 'admin'),
                              _buildPermissionItem('Audit Log Inspection', true),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: const Text('Update Permissions', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildInfoCard(
                            title: "Security & Context",
                            content: [
                              _buildSecurityInfo(Icons.history, 'Last Active', 'Today, 10:45 AM'),
                              _buildSecurityInfo(Icons.location_on_outlined, 'Last Known IP', '112.204.xxx.xxx'),
                              _buildSecurityInfo(
                                Icons.shield_outlined, 
                                'Two-Factor Auth', 
                                isMe ? (authViewModel.mfaFactors.isNotEmpty ? 'Enabled (TOTP)' : 'Disabled') : 'Restricted View'
                              ),
                              if (isMe && authViewModel.mfaFactors.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: TextButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const MfaEnrollmentPage()),
                                      );
                                    },
                                    icon: const Icon(Icons.add_moderator_rounded, size: 16),
                                    label: const Text('Setup 2FA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    style: TextButton.styleFrom(foregroundColor: AppTheme.primary, padding: EdgeInsets.zero),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 1,
                      child: _buildInfoCard(
                        title: "Activity Summary",
                        content: [
                          Row(
                            children: [
                              _buildStatMini(Icons.assignment_ind_outlined, 'Total Actions', '${viewModel.recentActivityLogs.length}'),
                              const SizedBox(width: 12),
                              _buildStatMini(Icons.login_rounded, 'Total Sessions', '28'),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text('Administrative Notes', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                          const SizedBox(height: 8),
                          const Text(
                            'This account has authorization to manage user profiles, approve loan requests, and access financial audit logs.',
                            style: TextStyle(fontSize: 13, color: AppTheme.textDark, height: 1.4),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final authRepo = context.read<AuthRepository>();
                              final success = await authRepo.requestPasswordReset(admin.email);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success 
                                      ? 'Password reset instructions sent to ${admin.email}' 
                                      : 'Failed to send reset code'),
                                    backgroundColor: success ? Colors.green : AppTheme.error,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.lock_reset_rounded),
                            label: const Text('Reset Admin Password'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF32211A),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
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
                      'Audit Trail & Recent Actions',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ActivityLogsPage(userId: admin.userId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.list_alt_rounded, size: 18),
                      label: const Text('View Detailed Logs', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildActivityLogTable(viewModel.recentActivityLogs),
                const SizedBox(height: 40),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () => Navigator.maybePop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Close Management View', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPermissionItem(String label, bool isEnabled) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            isEnabled ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
            color: isEnabled ? Colors.green : Colors.grey,
            size: 18,
          ),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(
            fontSize: 14, 
            color: isEnabled ? AppTheme.textDark : AppTheme.textMuted,
            fontWeight: isEnabled ? FontWeight.w500 : FontWeight.normal,
          )),
        ],
      ),
    );
  }

  Widget _buildSecurityInfo(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textMuted),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatMini(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF3F4F6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: AppTheme.textMuted),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _showStatusDialog(BuildContext context, ShareholderDetailViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Operational Status'),
        content: const Text('Change the account status for this administrator. This affects their system access.'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await viewModel.updateAccountStatus(UserStatus.active);
            },
            child: const Text('Set Active', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await viewModel.updateAccountStatus(UserStatus.inactive);
            },
            child: const Text('Set Inactive', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await viewModel.updateAccountStatus(UserStatus.suspended);
            },
            child: const Text('Suspend Access', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark, letterSpacing: -0.5),
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

  Widget _buildDetailItem(String label, String value, {IconData? icon, bool isStatus = false, UserStatus? statusValue, VoidCallback? onStatusTap}) {
    Color getStatusColor(UserStatus? status) {
      if (status == null) return AppTheme.textDark;
      switch (status) {
        case UserStatus.active: return Colors.green;
        case UserStatus.inactive: return Colors.orange;
        case UserStatus.suspended: 
        case UserStatus.rejected:
        case UserStatus.blocked:
          return Colors.red;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          InkWell(
            onTap: isStatus ? onStatusTap : null,
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: AppTheme.textMuted),
                  const SizedBox(width: 8),
                ],
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isStatus ? getStatusColor(statusValue) : AppTheme.textDark,
                    decoration: isStatus ? TextDecoration.underline : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLogTable(List<dynamic> logs) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
        horizontalMargin: 20,
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('Timestamp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('IP Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ],
        rows: logs.map((log) => DataRow(
          cells: [
            DataCell(Text(log.action, style: const TextStyle(fontSize: 13))),
            DataCell(Text(dateFormat.format(log.createdAt), style: const TextStyle(fontSize: 13, color: AppTheme.textMuted))),
            DataCell(Text(log.ipAddress, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted))),
          ],
        )).toList(),
      ),
    );
  }
}
