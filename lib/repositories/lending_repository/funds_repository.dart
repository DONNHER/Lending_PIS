import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles database operations for the central fund and treasury.
/// Focuses on capital injections, withdrawals, and balance tracking.
class FundManagementRepository {
  final SupabaseClient _client;

  // Table names
  static const String _transactionsTable = 'fund_transactions';
  static const String _capitalTable = 'fund_capital';

  const FundManagementRepository(this._client);

  /// Fetches the current total capital available in the fund.
  /// This aggregates all shareholder investments.
  Future<double> getTotalCapital() async {
    try {
      final response = await _client
          .from(_capitalTable)
          .select('amount.sum()')
          .single();

      return (response['sum'] as num?)?.toDouble() ?? 0.0;
    } on PostgrestException catch (e) {
      throw Exception('Failed to calculate total capital: ${e.message}');
    }
  }

  /// Records a new capital injection into the fund.
  /// Used when a shareholder adds money to the lending pool.
  Future<void> addCapital({
    required int shareholderId,
    required double amount,
    required String notes,
  }) async {
    try {
      await _client.from(_capitalTable).insert({
        'shareholder_id': shareholderId,
        'amount': amount,
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to record capital injection: ${e.message}');
    }
  }

  /// Fetches a history of fund-level transactions.
  /// Includes manual adjustments, fees, and non-loan movements.
  Future<List<Map<String, dynamic>>> getFundHistory() async {
    try {
      final response = await _client
          .from(_transactionsTable)
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch fund history: ${e.message}');
    }
  }

  /// Records a fund-level expense or manual adjustment.
  Future<void> recordAdjustment({
    required double amount,
    required String type, // e.g., 'fee', 'tax', 'adjustment'
    required String description,
  }) async {
    try {
      await _client.from(_transactionsTable).insert({
        'amount': amount,
        'type': type,
        'description': description,
        'created_at': DateTime.now().toIso8601String(),
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to record adjustment: ${e.message}');
    }
  }
}