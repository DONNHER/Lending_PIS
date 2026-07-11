import 'api_service.dart';

class EmailService {
  final ApiService _apiService;

  EmailService(this._apiService);

  Future<bool> sendWelcomeEmail(String email, String name) async {
    try {
      await _apiService.post('/email/welcome', body: {
        'email': email,
        'name': name,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendMfaCode(String email, String code) async {
    try {
      await _apiService.post('/email/mfa', body: {
        'email': email,
        'code': code,
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
