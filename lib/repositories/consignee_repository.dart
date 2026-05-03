import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/consignee_model.dart';

// Handles all database operations for consignees
// This keeps Supabase-specific code isolated from ViewModels
class ConsigneeRepository {
  final SupabaseClient _client;
  static const String _tableName = 'consignees';

  const ConsigneeRepository(this._client);

  /// Fetch all consignees from the database
  /// Returns empty list if none found
  Future<List<ConsigneeModel>> getAll() async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .order('created_at', ascending: false); // Newest first

      return (response as List)
          .map((json) => ConsigneeModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch consignees: ${e.message}');
    }
  }

  /// Search consignees by name, phone, or address
  Future<List<ConsigneeModel>> search(String query) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .or(
            'full_name.ilike.%$query%,phone.ilike.%$query%,address.ilike.%$query%',
          )
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ConsigneeModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Search failed: ${e.message}');
    }
  }

  /// Add a new consignee, returns the created record with its ID
  Future<ConsigneeModel> add(ConsigneeModel consignee) async {
    try {
      // Insert and return the created row (includes generated id, created_at)
      final response = await _client
          .from(_tableName)
          .insert(consignee.toJson())
          .select()
          .single();

      return ConsigneeModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to add consignee: ${e.message}');
    }
  }

  /// Update an existing consignee
  Future<ConsigneeModel> update(ConsigneeModel consignee) async {
    try {
      final response = await _client
          .from(_tableName)
          .update(consignee.toJson())
          .eq('id', consignee.id)
          .select()
          .single();

      return ConsigneeModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update consignee: ${e.message}');
    }
  }

  /// Delete a consignee by ID
  Future<void> delete(String id) async {
    try {
      await _client.from(_tableName).delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete consignee: ${e.message}');
    }
  }

  /// Get a single consignee by ID
  Future<ConsigneeModel> getById(String id) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('id', id)
          .single();

      return ConsigneeModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch consignee: ${e.message}');
    }
  }
}
