import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capstone_application/viewmodels/auth_viewmodel.dart';
import 'package:capstone_application/app_theme.dart';

class MfaPage extends StatefulWidget {
  final String email;

  const MfaPage({super.key, required this.email});

  @override
  State<MfaPage> createState() => _MfaPageState();
}

class _MfaPageState extends State<MfaPage> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final viewModel = context.read<AuthViewModel>();
    final success = await viewModel.verifyMfa(widget.email, _codeController.text.trim());
    
    if (success && mounted) {
      final route = viewModel.dashboardRoute;
      if (route != null) {
        Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
      }
    } else if (mounted && viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage!), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthViewModel>();
    
    return Scaffold(
      appBar: AppBar(title: const Text('MFA Verification')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Verification code sent to ${widget.email}', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: '6-digit code', hintText: '123456'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: viewModel.isLoading ? null : _handleVerify,
              child: viewModel.isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Verify and Login'),
            ),
          ],
        ),
      ),
    );
  }
}
