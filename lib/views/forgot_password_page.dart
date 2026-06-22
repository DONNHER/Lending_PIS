import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capstone_application/app_theme.dart';
import 'package:capstone_application/viewmodels/auth_viewmodel.dart';
import 'package:capstone_application/widgets/auth_text_field.dart';
import 'package:capstone_application/views/change_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordPage({super.key, this.initialEmail});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _codeSent = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleRequestReset() async {
    if (!_formKey.currentState!.validate()) return;

    final authViewModel = context.read<AuthViewModel>();
    final success = await authViewModel.requestPasswordReset(_emailController.text.trim());

    if (mounted) {
      if (success) {
        setState(() => _codeSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent to your email.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authViewModel.errorMessage ?? 'Failed to send reset code'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleVerifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = context.read<AuthViewModel>();
    final success = await viewModel.verifyRecoveryCode(
      _emailController.text.trim(),
      _codeController.text.trim(),
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? 'Invalid verification code'),
          backgroundColor: AppTheme.error,
        ),
      );
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
                    const Icon(Icons.lock_reset_rounded, size: 64, color: AppTheme.primary),
                    const SizedBox(height: 24),
                    Text(
                      _codeSent ? 'Verify Your Identity' : 'Reset Your Password',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _codeSent
                          ? "We've sent a 6-digit verification code to ${_emailController.text}. Please enter it below to reset your password."
                          : 'Enter your email address and we will send you a code to reset your password.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMuted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    if (!_codeSent) ...[
                      AuthTextField(
                        label: 'Email Address',
                        hint: 'Enter your email',
                        controller: _emailController,
                        enabled: !isLoading,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.textMuted, size: 20),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Email is required';
                          if (!value.contains('@')) return 'Invalid email format';
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: isLoading ? null : _handleRequestReset,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Send Reset Code', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ] else ...[
                      AuthTextField(
                        label: 'Verification Code',
                        hint: '000000',
                        controller: _codeController,
                        enabled: !isLoading,
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(Icons.numbers_rounded, color: AppTheme.textMuted, size: 20),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Code is required';
                          if (value.length != 6) return 'Code must be 6 digits';
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: isLoading ? null : _handleVerifyCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Verify Code', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: isLoading ? null : () => setState(() => _codeSent = false),
                        child: const Text("Didn't receive the code? Try again"),
                      ),
                    ],
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
