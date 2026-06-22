import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capstone_application/app_theme.dart';
import 'package:capstone_application/viewmodels/auth_viewmodel.dart';
import 'package:capstone_application/widgets/auth_text_field.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authViewModel = context.read<AuthViewModel>();
    final success = await authViewModel.updatePasswordOnly(_passwordController.text.trim());

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully. Please log in with your new password.'),
            backgroundColor: Colors.green,
          ),
        );
        // Logout to clear the recovery session
        await authViewModel.logout();
        
        // Navigate back to Login (ForgotPasswordPage was pushed replacement, so pop goes back to Login)
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authViewModel.errorMessage ?? 'Failed to update password'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthViewModel>();
    final isLoading = viewModel.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Set New Password',
          style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.vpn_key_rounded, size: 64, color: AppTheme.primary),
                    const SizedBox(height: 24),
                    const Text(
                      'Secure Your Account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Please enter and confirm your new password below.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMuted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    AuthTextField(
                      label: 'New Password',
                      hint: 'Enter new password',
                      controller: _passwordController,
                      obscureText: viewModel.obscurePassword,
                      prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textMuted, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          viewModel.obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppTheme.textMuted,
                          size: 20,
                        ),
                        onPressed: viewModel.togglePasswordVisibility,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Password is required';
                        if (value.length < 8) return 'Min 8 characters required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    AuthTextField(
                      label: 'Confirm New Password',
                      hint: 'Repeat new password',
                      controller: _confirmPasswordController,
                      obscureText: viewModel.obscurePassword,
                      prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppTheme.textMuted, size: 20),
                      validator: (value) {
                        if (value != _passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),
                    
                    ElevatedButton(
                      onPressed: isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text(
                              'Reset Password',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
