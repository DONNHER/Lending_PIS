import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart'; // Make sure supabase_flutter is imported
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

  bool _linkSent = false; // Track if the reset email has been successfully triggered

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  // Stream subscription to listen to Supabase auth events
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    // Listen for the password reset link click event from Supabase
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;

      // This triggers the exact moment the recovery link is clicked and processed by the app
      if (event == AuthChangeEvent.passwordRecovery) {
        if (!mounted) return;

        // TODO: Replace '/update-password' with your actual route or navigate to your Change Password screen
        Navigator.pushReplacementNamed(context, '/update-password');
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animCtrl.dispose();
    _authSubscription.cancel(); // Clean up the listener when leaving the page
    super.dispose();
  }

  Future<void> _handleSendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = context.read<AuthViewModel>();

    final success = await viewModel.forgotPassword(
      _emailController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      // Instead of popping, change local state to show the "Waiting/Check Email" view
      setState(() {
        _linkSent = true;
      });
    } else {
      _showSnackbar(
        viewModel.errorMessage ?? 'Unable to send reset email.',
        isError: true,
      );
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
                    // Toggle view based on whether the email was sent or not
                    return _linkSent ? _buildCheckEmailView() : _buildFormView(viewModel);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// View shown BEFORE sending the reset link
  Widget _buildFormView(AuthViewModel viewModel) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildIconHeader(Icons.lock_reset_rounded),
          const SizedBox(height: 32),
          const Text(
            'Reset Password',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your email address and we\'ll send you a password reset link.',
            style: TextStyle(fontSize: 14, color: AppTheme.textMuted, height: 1.5),
          ),
          const SizedBox(height: 32),
          AuthTextField(
            label: 'Email Address',
            hint: 'Enter your registered email',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(
              Icons.email_outlined,
              color: AppTheme.textMuted,
              size: 20,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }
              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
              if (!emailRegex.hasMatch(value.trim())) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          _buildSubmitButton(viewModel),
        ],
      ),
    );
  }

  /// View shown AFTER the link is sent, keeping the screen open so they can wait/check email
  Widget _buildCheckEmailView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildIconHeader(Icons.mark_email_unread_rounded),
        const SizedBox(height: 32),
        const Text(
          'Check Your Email',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textDark),
        ),
        const SizedBox(height: 12),
        Text(
          'We have sent a password reset verification link to:\n${_emailController.text.trim()}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppTheme.textMuted, height: 1.5),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Click the link inside the email. Your browser/app will automatically redirect you here to change your password.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textDark, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        OutlinedButton(
          onPressed: () {
            setState(() {
              _linkSent = false; // Allow user to re-enter email if they made a typo
            });
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            side: const BorderSide(color: AppTheme.primary),
          ),
          child: const Text(
            'Try another email',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildIconHeader(IconData icon) {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 44,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  Widget _buildSubmitButton(AuthViewModel viewModel) {
    return ElevatedButton(
      onPressed: viewModel.isLoading ? null : _handleSendResetLink,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 0,
      ),
      child: viewModel.isLoading
          ? const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      )
          : const Text(
        'Send Reset Link',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}