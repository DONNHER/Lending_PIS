import 'package:flutter/material.dart';

class MfaPage extends StatelessWidget {
  final String email;

  const MfaPage({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MFA Verification')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Verification code sent to $email'),
            // Add MFA logic here
          ],
        ),
      ),
    );
  }
}
