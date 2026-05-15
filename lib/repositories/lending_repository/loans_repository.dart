import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:capstone_application/models/lending_models/loan.dart'; // Ensure this path is correct

class LoanRepository {
  final SupabaseClient _client;

  static const String _table = 'loans';

  const LoanRepository(this._client);

  /// Fetch all loans with borrower details joined
  Future<List<Loan>> getAllLoans() async {
    try {
      final response = await _client
          .from(_table)
          .select('*, customers(*)') // Joining customer data for the borrower name
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;
      return data.map((json) => Loan.fromMap(json)).toList();
    } on PostgrestException catch (e) {
      throw Exception('Error fetching loans: ${e.message}');
    }
  }

  /// Fetch loans filtered by status (e.g., 'pending', 'approved', 'rejected')
  Future<List<Loan>> getLoansByStatus(String status) async {
    try {
      final response = await _client
          .from(_table)
          .select('*, customers(*)')
          .eq('status', status)
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;
      return data.map((json) => Loan.fromMap(json)).toList();
    } on PostgrestException catch (e) {
      throw Exception('Error fetching $status loans: ${e.message}');
    }
  }

  /// Create a new loan application
  Future<void> createLoanRequest(Map<String, dynamic> loanData) async {
    try {
      await _client.from(_table).insert(loanData);
    } on PostgrestException catch (e) {
      throw Exception('Failed to submit loan request: ${e.message}');
    }
  }

  /// Update loan status (Approval/Rejection)
  Future<void> updateLoanStatus(int loanId, String status) async {
    try {
      await _client
          .from(_table)
          .update({'status': status})
          .eq('id', loanId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update loan status: ${e.message}');
    }
  }

  /// Get a single loan by ID
  Future<Loan?> getLoanById(int id) async {
    try {
      final response = await _client
          .from(_table)
          .select('*, customers(*)')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return Loan.fromMap(response);
    } on PostgrestException catch (e) {
      throw Exception('Error fetching loan details: ${e.message}');
    }
  }
}