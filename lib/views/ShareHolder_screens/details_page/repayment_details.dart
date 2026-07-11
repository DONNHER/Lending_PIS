import 'package:flutter/material.dart';
import 'package:capstone_application/models/transaction_model.dart';
import 'package:capstone_application/app_theme.dart';
import 'package:intl/intl.dart';

class RepaymentDetailsScreen extends StatelessWidget {
  final TransactionModel transaction;

  const RepaymentDetailsScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.currency(symbol: '₱');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.check_circle_rounded, size: 80, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              format.format(transaction.amount),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Payment Successful', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            const Divider(height: 40),
            _detailRow('Transaction ID', transaction.id),
            _detailRow('Date', DateFormat('MMM dd, yyyy HH:mm').format(transaction.date)),
            _detailRow('Method', transaction.method),
            _detailRow('Status', transaction.status),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
