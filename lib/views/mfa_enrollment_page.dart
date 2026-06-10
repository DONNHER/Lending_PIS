import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/auth_text_field.dart';

class MfaEnrollmentPage extends StatefulWidget {
  const MfaEnrollmentPage({super.key});

  @override
  State<MfaEnrollmentPage> createState() => _MfaEnrollmentPageState();
}

class _MfaEnrollmentPageState extends State<MfaEnrollmentPage> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _startEnrollment();
      _initialized = true;
    }
  }

  Future<void> _startEnrollment() async {
    final viewModel = context.read<AuthViewModel>();
    await viewModel.startMfaEnrollment();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = context.read<AuthViewModel>();
    final success = await viewModel.finalizeMfaEnrollment(_codeController.text);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('MFA successfully enabled!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
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
    final viewModel = context.watch<AuthViewModel>();
    final enrollment = viewModel.mfaEnrollResponse;
    final isLoading = viewModel.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F3),
      appBar: AppBar(
        title: const Text('Setup 2FA', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 18)),
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
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_2_rounded, size: 64, color: AppTheme.primary),
                  const SizedBox(height: 24),
                  const Text(
                    'Protect your account',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Scan the QR code below with an authenticator app (like Google Authenticator or 1Password).',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppTheme.textMuted, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  
                  // QR Code Display
                  if (enrollment != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: _buildQrImage(enrollment.totp?.qrCode ?? ''),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Secret Key: ${enrollment.totp?.secret ?? ''}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontFamily: 'monospace'),
                    ),
                  ] else if (isLoading) ...[
                    const CircularProgressIndicator(color: AppTheme.primary),
                  ] else ...[
                    const Text('Failed to load QR code.'),
                    TextButton(onPressed: _startEnrollment, child: const Text('Retry')),
                  ],

                  const SizedBox(height: 40),
                  
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        AuthTextField(
                          label: 'Verification Code',
                          hint: 'Enter 6-digit code',
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textMuted, size: 20),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Code is required';
                            if (value.length != 6) return 'Code must be 6 digits';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: (isLoading || enrollment == null) ? null : _handleVerify,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Enable MFA', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                      ],
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

  Widget _buildQrImage(String qrCodeDataUrl) {
    if (qrCodeDataUrl.isEmpty) return const Icon(Icons.qr_code, size: 100);
    try {
      // Data URLs look like: data:image/svg+xml;base64,PHN2Zy...
      final base64String = qrCodeDataUrl.split(',').last;
      return Image.memory(
        base64Decode(base64String),
        width: 200,
        height: 200,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.error_outline, size: 100, color: AppTheme.error);
        },
      );
    } catch (e) {
      return const Icon(Icons.broken_image_outlined, size: 100);
    }
  }
}
