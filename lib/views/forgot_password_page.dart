import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capstone_application/app_theme.dart';
import 'package:capstone_application/viewmodels/auth_viewmodel.dart';
import '../widgets/auth_text_field.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _codeSent = false;
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackbar('Please enter your email address', isError: true);
      return;
    }

    debugPrint('DEBUG: [ForgotPasswordPage] Sending code to: $email');

    final viewModel = context.read<AuthViewModel>();
    final success = await viewModel.forgotPassword(email);

    debugPrint('DEBUG: [ForgotPasswordPage] Success: $success');

    if (success && mounted) {
      _showSnackbar('Verification code sent to your email', isError: false);
      setState(() {
        _codeSent = true;
      });
      _animCtrl.forward(from: 0);
    } else if (mounted && viewModel.errorMessage != null) {
      debugPrint('DEBUG: [ForgotPasswordPage] Error showing snackbar: ${viewModel.errorMessage}');
      _showSnackbar(viewModel.errorMessage!, isError: true);
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackbar('Passwords do not match', isError: true);
      return;
    }

    final viewModel = context.read<AuthViewModel>();
    final success = await viewModel.resetPassword(
      email: _emailController.text.trim(),
      code: _otpController.text.trim(),
      password: _newPasswordController.text,
    );

    if (success && mounted) {
      _showSnackbar('Password reset successfully! You can now login.', isError: false);
      Navigator.pop(context);
    } else if (mounted && viewModel.errorMessage != null) {
      _showSnackbar(viewModel.errorMessage!, isError: true);
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEEE5DD)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppTheme.textDark),
            ),
          ),
        ),
        title: const Text(
          'Forgot Password',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Consumer<AuthViewModel>(
                  builder: (context, viewModel, _) {
                    return Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildIconHeader(),
                          const SizedBox(height: 32),
                          if (!_codeSent) _buildEmailStep(viewModel) else _buildResetStep(viewModel),
                          const SizedBox(height: 32),
                          _buildSubmitButton(viewModel),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconHeader() {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.lock_reset_rounded,
          size: 44,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  Widget _buildEmailStep(AuthViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reset Password',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textDark),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your email address and we\'ll send you a code to reset your password.',
          style: TextStyle(fontSize: 14, color: AppTheme.textMuted, height: 1.5),
        ),
        const SizedBox(height: 32),
        AuthTextField(
          label: 'Email Address',
          hint: 'Enter your registered email',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.textMuted, size: 20),
        ),
      ],
    );
  }

  Widget _buildResetStep(AuthViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verify Account',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textDark),
        ),
        const SizedBox(height: 8),
        Text(
          'We\'ve sent a 6-digit code to ${_emailController.text}. Please enter it below along with your new password.',
          style: const TextStyle(fontSize: 14, color: AppTheme.textMuted, height: 1.5),
        ),
        const SizedBox(height: 32),
        AuthTextField(
          label: 'Verification Code',
          hint: '6-digit OTP',
          controller: _otpController,
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(Icons.pin_rounded, color: AppTheme.textMuted, size: 20),
          validator: (val) => val == null || val.length != 6 ? 'Enter the 6-digit code' : null,
        ),
        const SizedBox(height: 20),
        AuthTextField(
          label: 'New Password',
          hint: 'Enter your new password',
          controller: _newPasswordController,
          obscureText: viewModel.obscurePassword,
          prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textMuted, size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              viewModel.obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppTheme.textMuted,
              size: 20,
            ),
            onPressed: viewModel.togglePasswordVisibility,
          ),
          validator: (val) => val == null || val.length < 8 ? 'Password must be at least 8 characters' : null,
        ),
        const SizedBox(height: 20),
        AuthTextField(
          label: 'Confirm New Password',
          hint: 'Confirm your new password',
          controller: _confirmPasswordController,
          obscureText: viewModel.obscurePassword,
          prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textMuted, size: 20),
          validator: (val) => val == null || val.isEmpty ? 'Please confirm your password' : null,
        ),
      ],
    );
  }

  Widget _buildSubmitButton(AuthViewModel viewModel) {
    return ElevatedButton(
      onPressed: viewModel.isLoading ? null : (_codeSent ? _handleResetPassword : _handleSendOtp),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: viewModel.isLoading
          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(
              _codeSent ? 'Reset Password' : 'Send Code',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }
}
