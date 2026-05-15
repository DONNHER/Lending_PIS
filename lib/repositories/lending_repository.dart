import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lending_models/customer.dart';
import '../models/lending_models/loan.dart';

class LendingRepository {
  final SupabaseClient _client;
  
  static const String _customersTable = 'customers';
  static const String _loansTable = 'loans';

  const LendingRepository(this._client);

  /// Fetches all customers with their associated user profiles
  Future<List<Customer>> getAllCustomers() async {
    try {
      final response = await _client
          .from(_customersTable)
          .select('*, users(*)')
          .order('full_name', ascending: true);

      return (response as List)
          .map((json) => Customer.fromMap(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch customers: ${e.message}');
    }
  }

  /// Fetches all loan requests with customer details
  Future<List<Loan>> getAllLoanRequests() async {
    try {
      final response = await _client
          .from(_loansTable)
          .select('*, customers(*)')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Loan.fromMap(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch loan requests: ${e.message}');
    }
  }

  /// Create a new loan request
  Future<void> createLoan(Map<String, dynamic> loanData) async {
    try {
      await _client.from(_loansTable).insert(loanData);
    } on PostgrestException catch (e) {
      throw Exception('Failed to create loan: ${e.message}');
    }
  }

  /// Update loan status (Approve/Reject)
  Future<void> updateLoanStatus(int loanId, String status) async {
    try {
      await _client
          .from(_loansTable)
          .update({'status': status})
          .eq('id', loanId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update loan status: ${e.message}');
    }
  }
}
