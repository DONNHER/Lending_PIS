import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles complex data aggregation for the administrative dashboard.
class DashboardRepository {
  final SupabaseClient _client;

  static const String _loansTable = 'loans';
  static const String _paymentsTable = 'payments';
  static const String _customersTable = 'customers'; // Note: In your setup, these are Shareholders

  const DashboardRepository(this._client);

  /// Fetches summary counts for the dashboard KPI cards
  Future<Map<String, dynamic>> getOverviewStats() async {
    try {
      // By adding <dynamic> to Future.wait, we stop the type inference error.
      // We also ensure each query is treated as a Future.
      final results = await Future.wait<dynamic>([
        _client.from(_loansTable).select('id').count(CountOption.exact),
        _client.from(_loansTable).select('amount.sum()').eq('status', 'approved').maybeSingle(),
        _client.from(_customersTable).select('id').count(CountOption.exact),
        _client.from(_paymentsTable).select('amount.sum()').maybeSingle(),
      ]);

      // Safely extract the sum values using 'num' to avoid double/int cast errors
      final disbursedData = results[1] as Map<String, dynamic>?;
      final collectedData = results[3] as Map<String, dynamic>?;

      return {
        // Remove '?? 0' because count is non-nullable in this context
        'total_loans_count': (results[0] as PostgrestResponse).count,
        
        'total_disbursed': (disbursedData?['sum'] as num?)?.toDouble() ?? 0.0,
        
        // Remove '?? 0' here as well
        'total_customers': (results[2] as PostgrestResponse).count,
        
        'total_collected': (collectedData?['sum'] as num?)?.toDouble() ?? 0.0,
      };
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch dashboard stats: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Fetches monthly collection data for chart visualization
  Future<List<Map<String, dynamic>>> getMonthlyCollections() async {
    try {
      final response = await _client
          .from(_paymentsTable)
          .select('amount, payment_date')
          .order('payment_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch chart data: ${e.message}');
    }
  }

  /// Fetches the most recent pending loan requests for the "To-Do" section
  Future<List<Map<String, dynamic>>> getQuickActions() async {
    try {
      final response = await _client
          .from(_loansTable)
          .select('*, customers(full_name)')
          .eq('status', 'pending')
          .limit(5)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch quick actions: ${e.message}');
    }
  }
}