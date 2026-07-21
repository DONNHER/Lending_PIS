import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capstone_application/viewmodels/auth_viewmodel.dart';
import 'package:capstone_application/app_theme.dart';
import 'address_selector_page.dart';

class AdminEditAccountDetailsScreen extends StatefulWidget {
  const AdminEditAccountDetailsScreen({super.key});

  @override
  State<AdminEditAccountDetailsScreen> createState() => _AdminEditAccountDetailsScreenState();
}

class _AdminEditAccountDetailsScreenState extends State<AdminEditAccountDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthViewModel>();
    // 🚀 Use original admin user if impersonating
    final user = auth.isImpersonating ? auth.originalAdminUser : auth.currentUser;
    
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectAddress() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const AddressSelectorPage()),
    );
    if (result != null) {
      setState(() {
        _addressController.text = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    
    // 🚀 Use original admin user if impersonating
    final user = authViewModel.isImpersonating 
        ? authViewModel.originalAdminUser 
        : authViewModel.currentUser;

    final hasAvatar = authViewModel.avatarBytes != null || 
                     (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty && !authViewModel.removeAvatarRequested);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Edit Account Details', style: TextStyle(color: AppTheme.textDark, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar Selection Section
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1), width: 4),
                          ),
                          child: ClipOval(
                            child: authViewModel.avatarBytes != null
                                ? Image.memory(authViewModel.avatarBytes!, fit: BoxFit.cover)
                                : (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty && !authViewModel.removeAvatarRequested)
                                    ? Image.network(
                                        user.avatarUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person_rounded, size: 60, color: AppTheme.textMuted),
                                      )
                                    : const Icon(Icons.person_rounded, size: 60, color: AppTheme.textMuted),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [

                              if (hasAvatar) const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => authViewModel.pickAvatar(),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                                  child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                                ),
                              ),
                              if (hasAvatar)
                                GestureDetector(
                                  onTap: () => authViewModel.removeAvatar(),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                    child: const Icon(Icons.delete_rounded, size: 18, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  _buildTextField('First Name', _firstNameController, isRequired: false),
                  const SizedBox(height: 16),
                  _buildTextField('Last Name', _lastNameController, isRequired: false),
                  const SizedBox(height: 16),
                  _buildTextField('Email Address', _emailController, enabled: false, isRequired: false),
                  
                  const SizedBox(height: 32),
                  const Text('Address', style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  
                  InkWell(
                    onTap: _selectAddress,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(Icons.location_on_outlined, size: 20, color: AppTheme.textMuted),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _addressController.text.trim().isEmpty ? 'No address provided' : _addressController.text,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _addressController.text.trim().isEmpty ? AppTheme.textMuted : AppTheme.textDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.edit_outlined, size: 20, color: AppTheme.primary),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: authViewModel.isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              final success = await authViewModel.updateProfile(
                                firstName: _firstNameController.text.trim(),
                                lastName: _lastNameController.text.trim(),
                                address: _addressController.text.trim(),
                              );
                              
                              if (context.mounted) {
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Profile updated successfully'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  Navigator.pop(context);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(authViewModel.errorMessage ?? 'Update failed'),
                                      backgroundColor: AppTheme.error,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: authViewModel.isLoading
                        ? const SizedBox(height: 24, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => _showResetPasswordDialog(context, authViewModel),
                    child: const Center(
                      child: Text('Change Password', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showResetPasswordDialog(
  BuildContext context,
  AuthViewModel authViewModel,
) {
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final dialogFormKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Change Password'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      content: Form(
        key: dialogFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
              ),
              validator: (value) =>
                  value == null || value.isEmpty
                      ? 'Current password is required'
                      : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'New password is required';
                }
                if (value.length < 8) {
                  return 'Minimum 8 characters required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
              ),
              validator: (value) {
                if (value != newPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (!dialogFormKey.currentState!.validate()) return;

            final success = await authViewModel.changePassword(
              currentPassword: currentPasswordController.text.trim(),
              newPassword: newPasswordController.text.trim(),
            );

            if (!context.mounted) return;

            if (success) {
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Password changed successfully. Please log in again.',
                  ),
                  backgroundColor: Colors.green,
                ),
              );

              await authViewModel.logout();

              if (!context.mounted) return;

              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    authViewModel.errorMessage ??
                        'Failed to change password.',
                  ),
                  backgroundColor: AppTheme.error,
                ),
              );
            }
          },
          child: const Text('Change'),
        ),
      ],
    ),
  );
}

  Widget _buildTextField(String label, TextEditingController controller, {String? hint, bool enabled = true, bool isRequired = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          maxLines: null,
          style: TextStyle(color: enabled ? AppTheme.textDark : Colors.grey),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
          ),
          validator: isRequired ? (value) => value == null || value.isEmpty ? 'Field required' : null : null,
        ),
      ],
    );
  }
}
