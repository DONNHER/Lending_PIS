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

      // Check for existing shareholder
      final existingShareholder = await _shareholderRepository.getShareholderByEmail(email);
      if (existingShareholder != null) {
        throw Exception('A shareholder with this email already exists.');
      }

      // 🔍 DEBUG: Verify Admin Session BEFORE starting
      final currentSupabaseUser = _supabase.auth.currentUser;
      debugPrint('DEBUG: [AddShareholder] Admin session before starting: ${currentSupabaseUser?.email ?? "NONE"}');

      // 🚀 1. UPLOAD ID IMAGE (MUST BE FIRST while Admin is still authenticated)
      // IMPORTANT: We do this BEFORE registering the new user, because registration signs the Admin out of Supabase.
      if (_idFileBytes != null) {
        try {
          debugPrint('DEBUG: [AddShareholder] Step 1: Uploading ID image...');
          // Since we don't have the user ID yet, we use a clean version of the email + timestamp for unique filename
          final String safeEmail = email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
          final String fileExt = _idFileName?.split('.').last ?? 'jpg';
          final String fileName = 'ID_${safeEmail}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
          
          _idUrl = await _storageRepository.uploadFile(
            fileBytes: _idFileBytes!,
            fileName: fileName,
            folder: 'image_id_url',
          );
          debugPrint('✅ DEBUG: [AddShareholder] ID Uploaded. URL: $_idUrl');
        } catch (e) {
          debugPrint('⚠️ DEBUG: [AddShareholder] Upload failed: $e');
          // If RLS fails here, the Admin isn't logged into Supabase or RLS is too restrictive
          throw Exception('ID Upload failed. Please ensure you are logged in as Admin and the "image_id_url" bucket allows authenticated uploads.');
        }
      }

      // 🚀 2. REGISTER USER (In Supabase & Laravel)
      // Note: AuthRepository.register handles the Supabase signUp. 
      // This WILL clear the Admin's Supabase session and replace it with the new user's (unconfirmed) session.
      debugPrint('DEBUG: [AddShareholder] Step 2: Registering user...');
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

      // 🚀 3. Initialize Confirmation Flow (Fake Login)
      try {
        await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } catch (_) {
        debugPrint('ℹ️ [AddShareholder] Supabase Activation Link process initialized for $email.');
      }

      // 🚀 4. Save Shareholder Details
      debugPrint('DEBUG: [AddShareholder] Step 4: Saving shareholder details...');
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
