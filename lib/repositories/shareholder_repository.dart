import 'package:capstone_application/services/api_service.dart';
import 'package:capstone_application/models/shareholder_model.dart';

class ShareholderRepository {
  final ApiService _apiService;

  ShareholderRepository(this._apiService);

  Future<List<ShareholderModel>> getShareholders() async {
    final response = await _apiService.get('/shareholders');
    final List data = response['data'] ?? [];
    return data.map((e) => ShareholderModel.fromJson(e)).toList();
  }

  Future<ShareholderModel?> getShareholderById(String id) async {
    final response = await _apiService.get('/shareholders/$id');
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
}
