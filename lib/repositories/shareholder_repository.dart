import 'package:capstone_application/services/api_service.dart';
import 'package:capstone_application/models/shareholder_model.dart';

class ShareholderRepository {
  final ApiService _apiService;

  ShareholderRepository(this._apiService);

  Future<List<ShareholderModel>> getShareholders({int page = 1, int perPage = 10}) async {
    final response = await _apiService.get('/shareholders', queryParams: {
      'page': page.toString(),
      'per_page': perPage.toString(),
    });
    final List data = response['data'] ?? [];
    return data.map((e) => ShareholderModel.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getPaginatedShareholders({int page = 1, int perPage = 10, String? search}) async {
    final queryParams = {
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    
    final response = await _apiService.get('/shareholders', queryParams: queryParams);
    final List dataList = response['data'] ?? [];
    
    return {
      'shareholders': dataList.map((e) => ShareholderModel.fromJson(e)).toList(),
      'total': response['total'] ?? dataList.length,
      'last_page': response['last_page'] ?? 1,
      'current_page': response['current_page'] ?? page,
    };
  }

  Future<Map<String, dynamic>?> getShareholderFullData(String id) async {
    final response = await _apiService.get('/shareholders/$id');
    return response;
  }

  Future<ShareholderModel?> getShareholderById(String id) async {
    final response = await getShareholderFullData(id);
    if (response != null && response['data'] != null) {
      return ShareholderModel.fromJson(response['data']);
    }
    return null;
  }

  Future<ShareholderModel?> getShareholderByUserId(String userId) async {
    final response = await _apiService.get('/shareholders/user/$userId');
    if (response != null && response['data'] != null) {
      return ShareholderModel.fromJson(response['data']);
    }
    return null;
  }

  Future<void> addShareholder(Map<String, dynamic> data) async {
    await _apiService.post('/shareholders', body: data);
  }

  Future<void> updateCapital(String shareholderId, double newTotal) async {
    await _apiService.post('/shareholders/$shareholderId/capital', body: {
      'total_share_capital': newTotal,
    });
  }
}
