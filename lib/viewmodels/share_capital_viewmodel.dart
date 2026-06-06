import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:capstone_application/models/lending_models.dart';
import 'package:capstone_application/repositories/shareholder_repository.dart';
import 'package:capstone_application/repositories/transaction_repository.dart';
import 'package:capstone_application/repositories/lending_repository.dart';
import 'package:capstone_application/models/shareholder_model.dart';

class ShareCapitalViewModel extends ChangeNotifier {
  final ShareholderRepository _shareholderRepo;
  final TransactionRepository _transactionRepo;
  final LendingRepository _lendingRepo;
  final SupabaseClient _supabase = Supabase.instance.client;

  double totalCapital = 0.0;
  List<TransactionModel> transactions = [];
  bool isLoading = false;
  bool _isInitialized = false; // 🚀 Caching flag
  String? errorMessage;
  ShareholderModel? currentShareholder;
  LoanModel? activeLoan;
  String? _userId;

  // Use positional parameters to match the project's design pattern and avoid Null subtype errors
  ShareCapitalViewModel(
    this._shareholderRepo,
    this._transactionRepo,
    this._lendingRepo,
  );

  bool get isInitialized => _isInitialized;

  void setUserId(String? id) {
    if (_userId == id) return;
    _userId = id;

    if (_userId != null || _supabase.auth.currentUser != null) {
      // When user changes, reset initialization
      _isInitialized = false;
      fetchData();
    } else {
      currentShareholder = null;
      transactions = [];
      totalCapital = 0.0;
      activeLoan = null;
      _isInitialized = false;
      notifyListeners();
    }
  }

  String get shareholderFirstName {
    if (currentShareholder == null || currentShareholder!.fullName.isEmpty) {
      return 'User';
    }
    return currentShareholder!.fullName.trim().split(' ').first;
  }

  Future<void> fetchData({bool forceRefresh = false}) async {
    // 🚀 Only fetch if we haven't loaded yet OR if a refresh is explicitly requested
    if (_isInitialized && !forceRefresh) return;
    
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return;
    if (isLoading) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      debugPrint('ShareCapitalVM: Fetching data for user: ${authUser.id}');

      // 1. Fetch Shareholder Profile
      final shareholder = await _shareholderRepo.getShareholderByUserId(authUser.id);

      if (shareholder == null) {
        errorMessage = "No shareholder profile linked to this account.";
        currentShareholder = null;
        totalCapital = 0.0;
        activeLoan = null;
      } else {
        currentShareholder = shareholder;
        totalCapital = shareholder.totalShareCapital;
        
        // 2. Fetch Transactions and Loans concurrently
        final results = await Future.wait([
          _transactionRepo.getTransactionsByShareholderId(shareholder.id),
          _lendingRepo.getLoansByShareholderId(shareholder.id),
        ]);

        final List<TransactionModel>? txs = results[0] as List<TransactionModel>?;
        final List<LoanModel>? loans = results[1] as List<LoanModel>?;

        transactions = txs ?? [];
        
        // Safely identify the active loan
        if (loans != null && loans.isNotEmpty) {
          activeLoan = loans.where((l) => l.status.toLowerCase() == 'active').firstOrNull;
        } else {
          activeLoan = null;
        }
        
        _isInitialized = true; // 🚀 Mark as initialized
        debugPrint('ShareCapitalVM: Successfully loaded dashboard for ${shareholder.fullName}');
      }
    } catch (e) {
      debugPrint('ShareCapitalViewModel Error: $e');
      errorMessage = "Failed to sync records. Check your internet.";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Helper method to clear cache (e.g., on logout)
  void reset() {
    _isInitialized = false;
    currentShareholder = null;
    transactions = [];
    totalCapital = 0.0;
    activeLoan = null;
    notifyListeners();
  }
}
