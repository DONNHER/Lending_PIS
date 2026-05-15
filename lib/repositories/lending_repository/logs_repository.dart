import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:capstone_application/models/lending_models/shareholder.dart';
import 'package:capstone_application/models/lending_models/loan.dart';
import 'package:capstone_application/models/lending_models/payment.dart';

/// Handles database operations related to the system's audit trail and activity feed.
class ActivityRepository {
  final SupabaseClient _client;

  // Table names
  static const String _customersTable = 'customers';
  static const String _loansTable = 'loans';
  static const String _paymentsTable = 'payments';

  const ActivityRepository(this._client);

  /// Fetches recent loan activities (e.g., status changes or new requests)
  Future<List<Loan>> getRecentLoanActivities({int limit = 10}) async {
    try {
      final response = await _client
          .from(_loansTable)
          .select('*, customers(*)')
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => Loan.fromMap(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch loan activities: ${e.message}');
    }
  }

  /// Fetches recent payment activities
  Future<List<Payment>> getRecentPaymentActivities({int limit = 10}) async {
    try {
      final response = await _client
          .from(_paymentsTable)
          .select('*, loans(*, customers(*))')
          .order('payment_date', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => Payment.fromMap(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch payment activities: ${e.message}');
    }
  }

  /// Fetches recent customer sign-ups
  Future<List<ShareholderModel>> getRecentCustomerActivities({int limit = 10}) async {
    try {
      final response = await _client
          .from(_customersTable)
          .select('*, users(*)')
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => ShareholderModel.fromMap(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch customer activities: ${e.message}');
    }
  }

  /// Optional: If you have a dedicated 'activity_logs' table in Supabase
  /// you would implement a generic fetch here.
  Future<List<Map<String, dynamic>>> getSystemLogs() async {
    try {
      final response = await _client
          .from('activity_logs')
          .select()
          .order('created_at', ascending: false);
          
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch system logs: ${e.message}');
    }
  }
}