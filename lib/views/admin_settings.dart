import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capstone_application/viewmodels/auth_viewmodel.dart';
import 'package:capstone_application/models/user_model.dart';
import 'package:capstone_application/app_theme.dart';
import 'admin_edit_account_details.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;
    
    if (authViewModel.isLoading && user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F8FA),
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off_rounded, size: 64, color: AppTheme.textMuted),
              const SizedBox(height: 16),
              const Text('Profile information unavailable', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => authViewModel.restoreSession(),
                child: const Text('Reload Profile'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => authViewModel.restoreSession(),
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
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
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                )
                              ],
                              border: Border.all(color: AppTheme.primary.withOpacity(0.1), width: 3),
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
              _buildSection(
                context,
                title: 'Profile Settings',
                items: [
                  _SettingsTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Edit Account Details',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminEditAccountDetailsScreen())),
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
    );
  }

  Widget _buildStatusBadge(UserStatus status) {
    Color color = status == UserStatus.active ? Colors.green : (status == UserStatus.inactive ? Colors.orange : Colors.red);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.5))),
      child: Text(status.name.toUpperCase(), style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
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
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
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
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;
  const _SettingsTile({required this.icon, required this.title, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: AppTheme.primary, size: 20)),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 22),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
