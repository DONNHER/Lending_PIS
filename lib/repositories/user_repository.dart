import 'package:capstone_application/services/api_service.dart';
import 'package:capstone_application/models/user_model.dart';

class UserRepository {
  final ApiService _apiService;

  UserRepository(this._apiService);

  Future<Map<String, dynamic>> getPaginatedUsers({
    int page = 1, 
    int perPage = 10, 
    String? search,
    String? role,
    String? status,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (role != null && role != 'All') {
      queryParams['role'] = role.toLowerCase();
    }
    if (status != null && status != 'All') {
      queryParams['status'] = status.toLowerCase();
    }
    
    final response = await _apiService.get('/admin/users', queryParams: queryParams);
    final List dataList = response['data'] ?? [];
    
    return {
      'users': dataList.map((e) => UserModel.fromJson(e)).toList(),
      'total': response['meta']?['total'] ?? dataList.length,
      'last_page': response['meta']?['last_page'] ?? 1,
      'current_page': response['meta']?['current_page'] ?? page,
    };
  }

  Future<UserModel?> getUserById(String id) async {
    final response = await _apiService.get('/admin/users/$id');
    if (response != null && response['data'] != null) {
      return UserModel.fromJson(response['data']);
    }
    return null;
  }

  Future<void> updateStatus(String id, String status) async {
    await _apiService.post('/admin/users/$id/status', body: {'status': status});
  }

  Future<void> deleteUser(String id) async {
    await _apiService.delete('/admin/users/$id');
  }

  Future<Map<String, dynamic>> impersonate(String id) async {
    return await _apiService.post('/admin/users/$id/impersonate');
  }
}
