import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:capstone_application/models/lending_models/payment.dart';
import 'package:capstone_application/models/lending_models/transaction.dart';

/// Manages all ledger-related database operations.
/// Handles loan repayments, disbursements, and manual adjustments.
class TransactionsRepository {
  final SupabaseClient _client;
  
  static const String _paymentsTable = 'payments';
  static const String _fundTransactionsTable = 'fund_transactions';

  const TransactionsRepository(this._client);
  /// Fetches all transactions from the database and maps them to TransactionEntry
  Future<List<TransactionEntry>> getAllTransactions() async {
    try {
      final response = await _client
          .from('transactions') // Ensure your table is named 'transactions'
          .select()
          .order('date', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      
      // Use the .fromJson factory from your TransactionEntry model
      return data.map((json) => TransactionEntry.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Fetch all loan repayments with associated loan and customer details
  Future<List<Payment>> getAllRepayments() async {
    try {
      final response = await _client
          .from(_paymentsTable)
          .select('*, loans(*, customers(*))')
          .order('payment_date', ascending: false);

      return (response as List)
          .map((json) => Payment.fromMap(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch repayments: ${e.message}');
    }
  }

  /// Fetch repayments for a specific loan
  Future<List<Payment>> getRepaymentsByLoan(int loanId) async {
    try {
      final response = await _client
          .from(_paymentsTable)
          .select()
          .eq('loan_id', loanId)
          .order('payment_date', ascending: false);

      return (response as List)
          .map((json) => Payment.fromMap(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch payments for loan #$loanId: ${e.message}');
    }
  }

  /// Create a new repayment record
  Future<void> createRepayment(Map<String, dynamic> paymentData) async {
    try {
      await _client.from(_paymentsTable).insert(paymentData);
    } on PostgrestException catch (e) {
      throw Exception('Failed to record repayment: ${e.message}');
    }
  }

  /// Records a fund-level transaction (disbursements, fees, etc.)
  /// These are movements that affect the total pool but aren't repayments
  Future<void> logFundMovement({
    required double amount,
    required String type, // 'disbursement', 'fee', 'adjustment'
    required String referenceId,
    required String description,
  }) async {
    try {
      await _client.from(_fundTransactionsTable).insert({
        'amount': amount,
        'type': type,
        'reference_id': referenceId,
        'description': description,
        'created_at': DateTime.now().toIso8601String(),
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to log transaction: ${e.message}');
    }
  }
}