import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  Uint8List? _idImageBytes;
  String? _idImageName;

  AddShareholderViewModel({
    required this.shareholderRepository,
    required this.storageRepository,
    required this.authRepository,
    required this.emailService,
  });

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Uint8List? get idImageBytes => _idImageBytes;

  Future<void> pickIdImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image != null) {
      _idImageBytes = await image.readAsBytes();
      _idImageName = image.name;
      notifyListeners();
    }
  }

  void removeIdImage() {
    _idImageBytes = null;
    _idImageName = null;
    notifyListeners();
  }

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
      String? idImageUrl;

      // 1. Upload ID Image if selected
      if (_idImageBytes != null && _idImageName != null) {
        idImageUrl = await storageRepository.uploadBytes(
          bucket: 'ids',
          path: 'shareholders',
          fileName: _idImageName!,
          bytes: _idImageBytes!,
        );
        
        if (idImageUrl == null) {
          throw Exception("Failed to upload ID image. Please try again.");
        }
      }

      // 2. Register via AuthRepository
      final response = await authRepository.register(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: UserRole.shareholder,
        address: address,
        phone: phone,
        idImageUrl: idImageUrl,
      );

      if (response['success'] == true) {
        // Clear local state
        _idImageBytes = null;
        _idImageName = null;

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
