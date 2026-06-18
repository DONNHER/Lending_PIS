import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/shareholder_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/shareholder_repository.dart';
import '../repositories/storage_repository.dart';
import '../services/email_service.dart';

class AddShareholderViewModel extends ChangeNotifier {
  final ShareholderRepository _shareholderRepository;
  final StorageRepository _storageRepository;
  final AuthRepository _authRepository;
  final EmailService _emailService;
  final _supabase = Supabase.instance.client;

  bool _isLoading = false;
  String? _errorMessage;
  ShareholderModel? _createdShareholder;

  AddShareholderViewModel({
    required ShareholderRepository shareholderRepository,
    required StorageRepository storageRepository,
    required AuthRepository authRepository,
    required EmailService emailService,
  })  : _shareholderRepository = shareholderRepository,
        _storageRepository = storageRepository,
        _authRepository = authRepository,
        _emailService = emailService;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ShareholderModel? get createdShareholder => _createdShareholder;

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
    _createdShareholder = null;
    notifyListeners();

    try {
      final firstName = firstNameController.text.trim();
      final lastName = lastNameController.text.trim();
      final email = emailController.text.trim();
      final phone = phoneController.text.trim();
      final username = usernameController.text.trim();
      final password = passwordController.text.trim();

      // Check for existing shareholder in local DB
      final existingShareholder = await _shareholderRepository.getShareholderByEmail(email);
      if (existingShareholder != null) {
        throw Exception('A shareholder with this email already exists.');
      }

      // 🚀 1. REGISTER IN SUPABASE AUTH (New User)
      debugPrint('DEBUG: [AddShareholder] Step 1: Registering in Supabase Auth...');
      final authRes = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      final supabaseUserId = authRes.user?.id;
      if (supabaseUserId == null) {
        throw Exception('Failed to create Supabase account.');
      }

      // 🚀 2. UPLOAD ID IMAGE (Using Admin Authentication)
      if (_idFileBytes != null) {
        try {
          debugPrint('DEBUG: [AddShareholder] Step 2: Uploading ID image...');
          final String fileName = 'ID_${supabaseUserId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          _idUrl = await _storageRepository.uploadFile(
            fileBytes: _idFileBytes!,
            fileName: fileName,
            folder: 'image_id_url',
          );
          debugPrint('✅ DEBUG: [AddShareholder] ID Uploaded. URL: $_idUrl');
        } catch (e) {
          debugPrint('⚠️ DEBUG: [AddShareholder] Upload failed: $e. Proceeding without URL.');
        }
      }

      // 🚀 3. REGISTER IN LARAVEL USERS TABLE
      debugPrint('DEBUG: [AddShareholder] Step 3: Registering in Laravel (Users Table)...');
      final result = await _authRepository.register(
        email: email,
        password: password,
        username: username,
        firstName: firstName,
        lastName: lastName,
        role: UserRole.shareholder,
        idImageUrl: _idUrl, 
      );

      final UserModel? userModel = result['user'];
      if (userModel == null) {
        throw Exception('Failed to create Laravel user account.');
      }

      // 🚀 4. SEND WELCOME EMAIL (Laravel Backend)
      // Since the admin creates the account, we send credentials via our custom email service.
      final welcomeMessage = '''
Greetings $firstName,

Welcome to PIL - Account Created!

Username: $username
Password: $password

You can access the login page here: http://localhost:8000/login 

Registration successful. You can now use your credentials to log in.

Thank you,
Lending PIS Team
''';

      await _emailService.sendNotification(
        email: email,
        subject: 'Welcome to PIL - Account Created',
        message: welcomeMessage,
      );

      // 🚀 5. SAVE TO SHAREHOLDER DETAILS TABLE
      debugPrint('DEBUG: [AddShareholder] Step 5: Saving shareholder details...');
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
      _createdShareholder = await _shareholderRepository.getShareholderByUserId(userModel.id);
      
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
