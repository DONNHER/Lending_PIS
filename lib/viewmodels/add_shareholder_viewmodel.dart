import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/shareholder_repository.dart';
import '../repositories/storage_repository.dart';

class AddShareholderViewModel extends ChangeNotifier {
  final ShareholderRepository _shareholderRepository;
  final StorageRepository _storageRepository;
  final AuthRepository _authRepository;

  bool _isLoading = false;
  String? _errorMessage;

  AddShareholderViewModel({
    required ShareholderRepository shareholderRepository,
    required StorageRepository storageRepository,
    required AuthRepository authRepository,
  })  : _shareholderRepository = shareholderRepository,
        _storageRepository = storageRepository,
        _authRepository = authRepository;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final initialCapitalController = TextEditingController(text: '1000.00');
  final membershipFeeController = TextEditingController(text: '200.00');
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  Uint8List? _idFileBytes;
  String? _idFileName;
  String? _idUrl;

  Uint8List? get idFileBytes => _idFileBytes;
  String? get idFileName => _idFileName;

  Future<void> pickIdImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        _idFileBytes = await image.readAsBytes();
        _idFileName = image.name;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _errorMessage = 'Failed to pick image';
      notifyListeners();
    }
  }

  Future<bool> createAccount() async {
    if (!_validate()) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final firstName = firstNameController.text.trim();
      final lastName = lastNameController.text.trim();
      final email = emailController.text.trim();
      final phone = phoneController.text.trim();

      // 0. Pre-check email existence
      final existingShareholder = await _shareholderRepository.getShareholderByEmail(email);
      if (existingShareholder != null) {
        throw Exception('A shareholder with this email already exists.');
      }

      // 1. Register User in Laravel (No avatar during creation by admin)
      final UserModel userModel = await _authRepository.register(
        email: email,
        password: passwordController.text.trim(),
        username: usernameController.text.trim(),
        firstname: firstName,
        lastname: lastName,
        role: UserRole.shareholder,
      );

      // 2. Upload ID Image if provided
      if (_idFileBytes != null) {
        try {
          _idUrl = await _storageRepository.uploadFile(
            fileBytes: _idFileBytes!,
            fileName: 'ID_${userModel.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
            folder: 'shareholder-ids',
          );
        } catch (e) {
          debugPrint('Storage upload failed: $e');
        }
      }

      // 3. Create Shareholder linked to the NEW User ID
      final Map<String, dynamic> shareholderData = {
        'user_id': userModel.id,
        'full_name': '$firstName $lastName',
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'contact_number': phone,
        'address': addressController.text.trim(),
        'creditscore': 700,
        'total_share_capital': double.tryParse(initialCapitalController.text.trim()) ?? 0.0,
        'membership_fee': double.tryParse(membershipFeeController.text.trim()) ?? 200.0,
        'id_image_url': _idUrl,
      };

      await _shareholderRepository.addShareholder(shareholderData);
      return true;

    } catch (e) {
      debugPrint('CREATE ACCOUNT ERROR: $e');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _validate() {
    if (firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty ||
        usernameController.text.isEmpty ||
        passwordController.text.isEmpty) {
      _errorMessage = 'Please fill in all required fields';
      notifyListeners();
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    initialCapitalController.dispose();
    membershipFeeController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
