import '../services/api_service.dart';

class ShareCapitalRepository {
  final ApiService _apiService;

  ShareCapitalRepository(this._apiService);

  Future<Map<String, dynamic>> getSummary(String shareholderId) async {
    return await _apiService.get('/shareholders/$shareholderId/capital-summary') ?? {};
  }
}
