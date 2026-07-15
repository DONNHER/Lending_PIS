import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capstone_application/viewmodels/auth_viewmodel.dart';
import 'package:capstone_application/viewmodels/navigation_viewmodel.dart';
import 'package:capstone_application/models/user_model.dart';
import 'package:capstone_application/app_theme.dart';
import 'admin_edit_account_details.dart';
import '../viewmodels/backup_settings_viewmodel.dart';
import '../services/api_service.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => BackupSettingsViewModel(context.read<ApiService>())..loadSettings(),
      child: const _AdminSettingsBody(),
    );
  }
}

class _AdminSettingsBody extends StatefulWidget {
  const _AdminSettingsBody();

  @override
  State<_AdminSettingsBody> createState() => _AdminSettingsBodyState();
}

class _AdminSettingsBodyState extends State<_AdminSettingsBody> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final backupViewModel = context.watch<BackupSettingsViewModel>();
    
    // 🚀 Use original admin user if impersonating, otherwise use current user
    final user = authViewModel.isImpersonating 
        ? authViewModel.originalAdminUser 
        : authViewModel.currentUser;
    
    if (authViewModel.isLoading && user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F8FA),
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    // 🚀 STRICT ROLE CHECK: Only Admins can access this screen
    if (user == null || user.role != UserRole.admin) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_person_rounded, size: 64, color: AppTheme.error),
              const SizedBox(height: 16),
              const Text(
                'Access Denied', 
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark)
              ),
              const SizedBox(height: 8),
              const Text(
                'Only administrators can access these settings.', 
                style: TextStyle(color: AppTheme.textMuted)
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.read<NavigationViewModel>().navigateTo(0),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('Return to Dashboard'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: _buildCustomHeader(context),
      body: RefreshIndicator(
        onRefresh: () => authViewModel.restoreSession(),
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: authViewModel.isImpersonating 
                              ? null 
                              : () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AdminEditAccountDetailsScreen()),
                              ),
                            child: Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      )
                                    ],
                                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1), width: 3),
                                  ),
                                  child: ClipOval(
                                    child: authViewModel.avatarBytes != null
                                        ? Image.memory(
                                            authViewModel.avatarBytes!,
                                            fit: BoxFit.cover,
                                          )
                                        : (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                                            ? Image.network(
                                                user.avatarUrl!,
                                                fit: BoxFit.cover,
                                                key: ValueKey(user.avatarUrl),
                                                errorBuilder: (context, error, stackTrace) => const Icon(
                                                  Icons.person_rounded,
                                                  size: 50,
                                                  color: AppTheme.textMuted,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.person_rounded,
                                                size: 50,
                                                color: AppTheme.textMuted,
                                              ),
                                  ),
                                ),
                                if (!authViewModel.isImpersonating)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                                      child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(user.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(user.email, style: const TextStyle(fontSize: 14, color: AppTheme.textMuted)),
                              const SizedBox(width: 8),
                              _buildStatusBadge(user.status),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(20)),
                            child: Text(user.role.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    if (authViewModel.isImpersonating)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: Colors.orange, size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Profile editing is disabled during impersonation. Please exit the session to update your account.',
                                style: TextStyle(fontSize: 12, color: AppTheme.textDark, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                    _buildSection(
                      context,
                      title: 'Profile Settings',
                      items: [
                        _SettingsTile(
                          icon: Icons.person_outline_rounded,
                          title: 'Edit Account Details',
                          onTap: authViewModel.isImpersonating 
                            ? () {} // Disable tap
                            : () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminEditAccountDetailsScreen())),
                          trailing: authViewModel.isImpersonating ? const SizedBox.shrink() : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      context,
                      title: 'Preferences',
                      items: [
                        _SettingsTile(
                          icon: Icons.notifications_none_rounded,
                          title: 'Notifications',
                          trailing: Switch(
                            value: _notificationsEnabled,
                            onChanged: (value) => setState(() => _notificationsEnabled = value),
                            thumbColor: const WidgetStatePropertyAll(AppTheme.primary),
                          ),
                          onTap: () => setState(() => _notificationsEnabled = !_notificationsEnabled),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      context,
                      title: 'Lending Configuration',
                      items: [
                        _SettingsTile(
                          icon: Icons.percent_rounded,
                          title: 'Interest Rate Management',
                          onTap: () {
                            final nav = context.read<NavigationViewModel>();
                            nav.clearAdminSettings();
                            final index = nav.getFilteredNavItems().indexWhere((item) => item.route == '/update-interest');
                            if (index != -1) nav.navigateTo(index);
                          },
                        ),
                        _SettingsTile(
                          icon: Icons.timer_outlined,
                          title: 'Grace Period Settings',
                          onTap: () {},
                        ),
                        _SettingsTile(
                          icon: Icons.payments_outlined,
                          title: 'Late Payment Penalties',
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      context,
                      title: 'Backup & Maintenance',
                      items: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 20),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Backups are stored locally on the server with a 30-day retention policy.',
                                  style: TextStyle(fontSize: 12, color: AppTheme.textDark, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _SettingsTile(
                          icon: Icons.calendar_month_rounded,
                          title: 'Backup Schedule',
                          subtitle: 'Every ${backupViewModel.backupDay} at ${backupViewModel.backupTime}',
                          onTap: () => _showScheduleDialog(context, backupViewModel),
                        ),
                        _SettingsTile(
                          icon: Icons.mark_email_unread_outlined,
                          title: 'Email Notifications (Success)',
                          trailing: Switch(
                            value: backupViewModel.notifySuccess,
                            onChanged: (val) => backupViewModel.updateSetting('backup_notify_success', val, 'boolean'),
                            activeColor: AppTheme.primary,
                          ),
                          onTap: () async {
                            final success = await backupViewModel.updateSetting('backup_notify_success', !backupViewModel.notifySuccess, 'boolean');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success ? 'Preference updated' : 'Update failed'),
                                  backgroundColor: success ? Colors.green : Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                        _SettingsTile(
                          icon: Icons.report_problem_outlined,
                          title: 'Email Notifications (Failure)',
                          trailing: Switch(
                            value: backupViewModel.notifyFailure,
                            onChanged: (val) => backupViewModel.updateSetting('backup_notify_failure', val, 'boolean'),
                            activeColor: AppTheme.primary,
                          ),
                          onTap: () async {
                            final success = await backupViewModel.updateSetting('backup_notify_failure', !backupViewModel.notifyFailure, 'boolean');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success ? 'Preference updated' : 'Update failed'),
                                  backgroundColor: success ? Colors.green : Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                        _SettingsTile(
                          icon: Icons.backup_outlined,
                          title: 'Run Manual Backup',
                          onTap: () => _showManualBackupDialog(context, backupViewModel),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      context,
                      title: 'Legal',
                      items: [
                        _SettingsTile(icon: Icons.description_outlined, title: 'Terms and Condition', onTap: () => _showTermsDialog(context)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: OutlinedButton(
                        onPressed: () => _showLogoutDialog(context, authViewModel),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Icon(Icons.logout_rounded, size: 20), SizedBox(width: 8), Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold))],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(UserStatus status) {
    Color color = status == UserStatus.active ? Colors.green : (status == UserStatus.inactive ? Colors.orange : Colors.red);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withValues(alpha: 0.5))),
      child: Text(status.name.toUpperCase(), style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }

  PreferredSizeWidget _buildCustomHeader(BuildContext context) {
    const primaryBrown = Color(0xFFC06C4D);
    const textDark = Color(0xFF1F2937);

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 80,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => context.read<NavigationViewModel>().clearAdminSettings(),
      ),
      title: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFFC06C4D),
              child: Icon(Icons.settings_rounded, color: Colors.white),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Account Settings',
                    style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('System Settings',
                    style: TextStyle(color: primaryBrown, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 1.2)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]),
          child: Column(children: items),
        ),
      ],
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms and Conditions'),
        content: const SingleChildScrollView(child: Text('Welcome to Lending System. By using this application, you agree to comply with and be bound by the following terms and conditions of use...')),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await viewModel.logout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showScheduleDialog(BuildContext context, BackupSettingsViewModel viewModel) {
    final List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    String selectedDay = viewModel.backupDay;
    TimeOfDay selectedTime = TimeOfDay(
      hour: int.parse(viewModel.backupTime.split(':')[0]),
      minute: int.parse(viewModel.backupTime.split(':')[1]),
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Backup Schedule'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedDay,
                decoration: const InputDecoration(labelText: 'Weekly Day'),
                items: days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (val) => setDialogState(() => selectedDay = val!),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Preferred Time'),
                subtitle: Text(selectedTime.format(context)),
                trailing: const Icon(Icons.access_time_rounded),
                onTap: () async {
                  final time = await showTimePicker(context: context, initialTime: selectedTime);
                  if (time != null) setDialogState(() => selectedTime = time);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final timeStr = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                final s1 = await viewModel.updateSetting('backup_day', selectedDay, 'string');
                final s2 = await viewModel.updateSetting('backup_time', timeStr, 'string');
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(s1 && s2 ? 'Schedule updated successfully' : 'Failed to update schedule'),
                      backgroundColor: (s1 && s2) ? Colors.green : Colors.red,
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Save Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualBackupDialog(BuildContext context, BackupSettingsViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Backup'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose the type of backup you want to trigger immediately.'),
            SizedBox(height: 8),
            Text(
              'Note: The file will be saved locally on the server.',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Starting database backup...'), duration: Duration(seconds: 2))
              );
              final success = await viewModel.runManualBackup('db');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Database backup successful (Saved Locally)' : 'Backup failed'), 
                    backgroundColor: success ? Colors.green : Colors.red
                  )
                );
              }
            },
            child: const Text('Database Only'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Starting full system backup...'), duration: Duration(seconds: 2))
              );
              final success = await viewModel.runManualBackup('full');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Full system backup successful (Saved Locally)' : 'Backup failed'), 
                    backgroundColor: success ? Colors.green : Colors.red
                  )
                );
              }
            },
            child: const Text('Full System'),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  const _SettingsTile({required this.icon, required this.title, this.subtitle, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        hoverColor: AppTheme.primary.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textDark),
        ),
        subtitle: subtitle != null
            ? Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted))
            : null,
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 22),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
