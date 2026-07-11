import 'package:flutter/material.dart';
import '../repositories/shareholder_repository.dart';
import '../repositories/storage_repository.dart';
import '../repositories/auth_repository.dart';
import '../services/email_service.dart';

class AddShareholderViewModel extends ChangeNotifier {
  final ShareholderRepository shareholderRepository;
  final StorageRepository storageRepository;
  final AuthRepository authRepository;
  final EmailService emailService;

  final bool _isLoading = false;

  AddShareholderViewModel({
    required this.shareholderRepository,
    required this.storageRepository,
    required this.authRepository,
    required this.emailService,
  });

  bool get isLoading => _isLoading;
}
