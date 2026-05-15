import 'package:supabase_flutter/supabase_flutter.dart';
// Ensure these point to your corrected model files
import 'package:capstone_application/models/lending_models/loan_request.dart';

class LoanRequestRepository {
  final SupabaseClient _client;
  
  // Use the specific loan_requests table rather than the final loans table
  static const String _tableName = 'loan_requests';

  const LoanRequestRepository(this._client);

  Future<void> submitLoanApplication(Map<String, dynamic> data) async {
  try {
     await Supabase.instance.client
        .from('loan_request') // Make sure this matches your table name
        .insert(data);
    
    // In newer supabase_flutter versions, insert doesn't return an error object 
    // but throws an exception if it fails.
  } catch (e) {
    throw Exception("Failed to submit loan: $e");
  }
}

  /// Fetch all loan requests with borrower data
  Future<List<LoanRequestModel>> getAllLoanRequests() async {
    try {
      final response = await _client
          .from(_tableName)
          .select('*, shareholders(*)') // Joining shareholders as defined in your model
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => LoanRequestModel.fromMap(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch requests: ${e.message}');
    }
  }

  /// Fetch requests filtered by status
  Future<List<LoanRequestModel>> getRequestsByStatus(String status) async {
    try {
      final response = await _client
          .from(_tableName)
          .select('*, shareholders(*)')
          .eq('status', status)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => LoanRequestModel.fromMap(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch $status requests: ${e.message}');
    }
  }

  /// Update loan request status (Approve/Reject)
  Future<void> updateRequestStatus({
    required int requestId,
    required String status,
    double? approvedAmount,
    String? rejectionReason,
  }) async {
    try {
      await _client.from(_tableName).update({
        'status': status,
        if (approvedAmount != null) 'approved_amount': approvedAmount,
        if (rejectionReason != null) 'rejection_reason': rejectionReason,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', requestId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update request #$requestId: ${e.message}');
    }
  }

  /// Delete a loan request
  Future<void> deleteRequest(int id) async {
    try {
      await _client.from(_tableName).delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete request: ${e.message}');
    }
  }
}