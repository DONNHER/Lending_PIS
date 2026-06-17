import 'package:flutter/foundation.dart';
import 'api_service.dart';

class EmailService {
  final ApiService _api;

  EmailService(this._api);

  Future<void> sendNotification({
    required String email,
    required String subject,
    required String message,
  }) async {
    try {
      debugPrint('🚀 [EmailService] Sending email via Laravel Backend to $email');
      
      final response = await _api.post('/send-email', body: {
        'to': email,
        'subject': subject,
        'message': message,
      });

      if (response != null && response['success'] == true) {
        debugPrint('✅ Email sent successfully!');
      } else {
        debugPrint('❌ Failed to send email: ${response?['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      debugPrint('❌ Error sending email: $e');
    }
  }
}
