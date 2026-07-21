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
    _animCtrl.dispose();
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
    _showSnackbar(
      'Password reset link sent. Please check your email.',
      isError: false,
    );

    Navigator.pop(context);
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
                    return Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                                _buildIconHeader(),
                                const SizedBox(height: 32),
                                _buildEmailStep(viewModel),
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
      ],
    );
  }

 
 Widget _buildSubmitButton(AuthViewModel viewModel) {
  return ElevatedButton(
    onPressed: viewModel.isLoading
        ? null
        : _handleSendResetLink,
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
