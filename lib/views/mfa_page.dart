import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/auth_text_field.dart';

class MfaPage extends StatefulWidget {
  final String email;

  const MfaPage({super.key, required this.email});

  @override
  State<MfaPage> createState() => _MfaPageState();
}

class _MfaPageState extends State<MfaPage> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = context.read<AuthViewModel>();
    final success = await viewModel.verifyMfa(_codeController.text);

    if (success && mounted) {
      final dashboardRoute = viewModel.dashboardRoute;
      if (dashboardRoute != null) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(dashboardRoute, (route) => false);
      }
    } else if (mounted && viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage!),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthViewModel>().isLoading;

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.security_rounded, size: 64, color: AppTheme.primary),
                const SizedBox(height: 24),
                const Text(
                  'Two-Step Verification',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Enter the 6-digit code sent to ${widget.email} to verify your identity.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                AuthTextField(
                  label: 'Verification Code',
                  hint: 'Enter 6-digit code',
                  controller: _codeController,
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
                  onPressed: isLoading ? null : _handleVerify,
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
                          'Verify Identity',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    // Logic to resend MFA code
                  },
                  child: const Text(
                    'Didn\'t receive a code? Resend',
                    style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
