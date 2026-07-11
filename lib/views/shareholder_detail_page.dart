import 'package:flutter/material.dart';

class ShareholderDetailPage extends StatelessWidget {
  final String shareholderId;
  const ShareholderDetailPage({super.key, required this.shareholderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shareholder Details')),
      body: Center(child: Text('Shareholder ID: $shareholderId')),
    );
  }
}
