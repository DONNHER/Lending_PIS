import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capstone_application/viewmodels/auth_viewmodel.dart';
import 'package:capstone_application/app_theme.dart';

class EditAccountDetailsScreen extends StatefulWidget {
  const EditAccountDetailsScreen({super.key});

  @override
  State<EditAccountDetailsScreen> createState() => _EditAccountDetailsScreenState();
}

class _EditAccountDetailsScreenState extends State<EditAccountDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  
  late TextEditingController _streetController;
  late TextEditingController _barangayController;
  late TextEditingController _cityController;
  late TextEditingController _provinceController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().currentUser;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    
    final address = user?.address ?? '';
    final parts = address.trim().isNotEmpty 
        ? address.split(',').map((e) => e.trim()).toList() 
        : <String>[];

    _streetController = TextEditingController(text: parts.isNotEmpty ? parts[0] : '');
    _barangayController = TextEditingController(text: parts.length > 1 ? parts[1] : '');
    _cityController = TextEditingController(text: parts.length > 2 ? parts[2] : '');
    _provinceController = TextEditingController(text: parts.length > 3 ? parts[3] : '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _streetController.dispose();
    _barangayController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    super.dispose();
  }

  String get _currentAddressSummary {
    final List<String> addressParts = [];
    if (_streetController.text.trim().isNotEmpty) addressParts.add(_streetController.text.trim());
    if (_barangayController.text.trim().isNotEmpty) addressParts.add(_barangayController.text.trim());
    if (_cityController.text.trim().isNotEmpty) addressParts.add(_cityController.text.trim());
    if (_provinceController.text.trim().isNotEmpty) addressParts.add(_provinceController.text.trim());
    return addressParts.isEmpty ? 'No address provided' : addressParts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;

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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture Section - COMMENTED FOR SUBMISSION
              /*
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: ClipOval(
                        child: authViewModel.avatarBytes != null
                            ? Image.memory(authViewModel.avatarBytes!, fit: BoxFit.cover)
                            : (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                                ? Image.network(
                                    user.avatarUrl!,
                                    fit: BoxFit.cover,
                                    key: ValueKey(user.avatarUrl),
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.person_rounded,
                                      size: 55,
                                      color: AppTheme.textMuted,
                                    ),
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                    },
                                  )
                                : const Icon(Icons.person_rounded, size: 55, color: AppTheme.textMuted),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => authViewModel.pickAvatar(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              */
              _buildTextField('First Name', _firstNameController),
              const SizedBox(height: 16),
              _buildTextField('Last Name', _lastNameController),
              const SizedBox(height: 16),
              _buildTextField('Email Address', _emailController, enabled: false),
              
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ADDRESS DETAILS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showEditAddressDialog(context),
                    icon: const Icon(Icons.edit_location_alt_rounded, size: 16, color: AppTheme.primary),
                    label: const Text('Edit', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current Address:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      _currentAddressSummary,
                      style: const TextStyle(fontSize: 14, color: AppTheme.textDark, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              // ID VERIFICATION - COMMENTED FOR SUBMISSION
              /*
              const SizedBox(height: 32),
              const Text(
                'ID VERIFICATION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
              const Divider(),
              const SizedBox(height: 16),
              
              GestureDetector(
                onTap: () => authViewModel.pickIdImage(),
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: authViewModel.idImageBytes != null
                        ? Image.memory(authViewModel.idImageBytes!, fit: BoxFit.cover)
                        : (user?.idImageUrl != null && user!.idImageUrl!.isNotEmpty)
                            ? Image.network(
                                user.idImageUrl!,
                                fit: BoxFit.cover,
                                key: ValueKey(user.idImageUrl),
                                errorBuilder: (context, error, stackTrace) => _buildIdPlaceholder(),
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                },
                              )
                            : _buildIdPlaceholder(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Tap to upload or change ID image',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ),
              */
              
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: authViewModel.isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          final success = await authViewModel.updateProfile(
                            firstName: _firstNameController.text.trim(),
                            lastName: _lastNameController.text.trim(),
                            address: _currentAddressSummary == 'No address provided' ? '' : _currentAddressSummary,
                          );
                          
                          if (context.mounted) {
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Profile updated successfully')),
                              );
                              Navigator.pop(context);
                            } else {
                              _showErrorDialog(context, authViewModel.errorMessage ?? 'Unknown error');
                            }
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: authViewModel.isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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
    );
  }

  Widget _buildIdPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.badge_outlined, size: 48, color: Colors.grey.withOpacity(0.5)),
        const SizedBox(height: 8),
        Text('No ID Uploaded', style: TextStyle(color: Colors.grey.withOpacity(0.8), fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _showEditAddressDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Address', style: TextStyle(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField('Street', _streetController, isRequired: false),
              const SizedBox(height: 12),
              _buildTextField('Barangay', _barangayController, isRequired: false),
              const SizedBox(height: 12),
              _buildTextField('Municipality/City', _cityController, isRequired: false),
              const SizedBox(height: 12),
              _buildTextField('Province', _provinceController, isRequired: false),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {}); 
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Update Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            const Text('Troubleshooting:', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('• Check if bucket IDs "avatars" and "id-images" exist in Supabase.'),
            const Text('• Ensure the buckets are configured correctly.'),
            const Text('• Check internet connection.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, AuthViewModel authViewModel) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Form(
          key: dialogFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current Password'),
                validator: (value) => value == null || value.isEmpty ? 'Field required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
                validator: (value) => value == null || value.length < 6 ? 'Min 6 characters required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm New Password'),
                validator: (value) => value != newPasswordController.text ? 'Passwords do not match' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (dialogFormKey.currentState!.validate()) {
                final success = await authViewModel.changePassword(
                  currentPassword: currentPasswordController.text,
                  newPassword: newPasswordController.text,
                );
                if (context.mounted && success) Navigator.pop(context);
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool enabled = true, bool isRequired = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          style: TextStyle(color: enabled ? AppTheme.textDark : Colors.grey),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
          ),
          validator: isRequired ? (value) => value == null || value.isEmpty ? 'Field required' : null : null,
        ),
      ],
    );
  }
}
