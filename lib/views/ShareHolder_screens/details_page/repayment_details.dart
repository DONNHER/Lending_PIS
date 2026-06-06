import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/lending_models.dart';

class RepaymentDetailsScreen extends StatelessWidget {
  final TransactionModel transaction;

  const RepaymentDetailsScreen({super.key, required this.transaction});

  // UI Constants
  static const Color primaryGreen = Color(0xFF80FF80);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color borderGrey = Color(0xFFF3F4F6);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱ ');
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
    
    final isCapital = transaction.type.toLowerCase().contains('capital');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const CircleAvatar(
            backgroundColor: borderGrey,
            child: Icon(Icons.close, color: Colors.black87, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Header Section
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: isCapital ? const Color(0xFFC06C4D).withValues(alpha: 0.1) : primaryGreen.withValues(alpha: 0.2),
                          child: Icon(
                            isCapital ? Icons.account_balance_rounded : Icons.payments_rounded, 
                            color: isCapital ? const Color(0xFFC06C4D) : Colors.green[700], 
                            size: 30
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(transaction.status, 
                          style: const TextStyle(color: textGrey, fontSize: 14)),
                        const SizedBox(height: 8),
                        Text(currencyFormat.format(transaction.amount), 
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(transaction.clientName, 
                          style: const TextStyle(color: textGrey, fontSize: 14)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black26),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(transaction.type, 
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Details List
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Transaction Details", 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        _buildDetailRow("Type", transaction.type),
                        _buildDetailRow("Method", transaction.method),
                        _buildDetailRow("Date & Time", dateFormat.format(transaction.date)),
                        _buildDetailRow("Reference ID", transaction.referenceId.isEmpty ? "N/A" : transaction.referenceId, isLink: true),
                        const SizedBox(height: 20),
                        const Divider(color: borderGrey, thickness: 1.5),
                        const SizedBox(height: 30),
                        
                        // Help Link
                        Center(
                          child: Column(
                            children: [
                              const Text("Need help?", 
                                style: TextStyle(color: textGrey, fontSize: 12)),
                              TextButton(
                                onPressed: () {},
                                child: const Text("Go to Help Center", 
                                  style: TextStyle(
                                    color: Colors.green, 
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  )),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Sticky Bottom Button
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCapital ? const Color(0xFFC06C4D) : primaryGreen,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text("Done", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: textGrey, fontSize: 14)),
          Flexible(
            child: Text(
              value, 
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.w500,
                color: isLink ? Colors.green : Colors.black87,
                decoration: isLink ? TextDecoration.underline : null,
              )
            ),
          ),
        ],
      ),
    );
  }
}
