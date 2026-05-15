import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:capstone_application/models/lending_models/shareholder.dart';

class ShareholderRepository {
  final SupabaseClient _client;
  static const String _contributionsTable = 'contributions';

  const ShareholderRepository(this._client);

  Future<List<ShareholderModel>> getAllShareholders() async {
    try {
      final response = await _client
          .from('shareholders')
          .select('*, customers(*)'); // Adjust based on your table names

      // Perform the mapping here
      return (response as List)
          .map((json) => ShareholderModel.fromMap(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch shareholders: $e');
    }
  }

  /// Fetch all contribution records for a specific shareholder
  Future<List<Map<String, dynamic>>> getContributions(int shareholderId) async {
    try {
      final response = await _client
          .from(_contributionsTable)
          .select()
          .eq('shareholder_id', shareholderId)
          .order('date', ascending: false);
          
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch contributions: ${e.message}');
    }
  }

  Future<void> createShareholder(Map<String, dynamic> data) async {
  final response = await _client.from('shareholders').insert(data);
  if (response.error != null) throw response.error!.message;
}

  /// Add a new capital contribution record
  Future<void> addContribution({
    required int shareholderId,
    required double amount,
    required DateTime date,
  }) async {
    try {
      await _client.from(_contributionsTable).insert({
        'shareholder_id': shareholderId,
        'amount': amount,
        'date': date.toIso8601String(),
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to record contribution: ${e.message}');
    }
  }
}