import 'package:flutter/material.dart';
import '../repositories/shareholder_repository.dart';
import '../repositories/storage_repository.dart';
import '../repositories/auth_repository.dart';
import '../services/email_service.dart';
import '../models/user_model.dart';

class AddShareholderViewModel extends ChangeNotifier {
  final ShareholderRepository shareholderRepository;
  final StorageRepository storageRepository;
  final AuthRepository authRepository;
  final EmailService emailService;

  bool _isLoading = false;
  String? _errorMessage;

  AddShareholderViewModel({
    required this.shareholderRepository,
    required this.storageRepository,
    required this.authRepository,
    required this.emailService,
  });

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<String?> registerShareholder({
    required String firstName,
    required String lastName,
    required String email,
    required String username,
    required String password,
    required String address,
    required String phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await authRepository.register(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: UserRole.shareholder,
        address: address,
        phone: phone,
      );

      if (response['success'] == true) {
        // Return the user ID so we can navigate to details
        return response['user']['id'].toString();
      } else {
        _errorMessage = response['message'] ?? 'Failed to register shareholder';
        return null;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
