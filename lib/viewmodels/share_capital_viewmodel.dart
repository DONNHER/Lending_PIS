import 'package:flutter/material.dart';
import 'package:capstone_application/models/lending_models.dart';
import 'package:capstone_application/repositories/shareholder_repository.dart';
import 'package:capstone_application/repositories/transaction_repository.dart';
import 'package:capstone_application/repositories/lending_repository.dart';
import 'package:capstone_application/models/shareholder_model.dart';
import 'package:capstone_application/services/local_cache_service.dart';

class ShareCapitalViewModel extends ChangeNotifier {
  final ShareholderRepository _shareholderRepo;
  final TransactionRepository _transactionRepo;
  final LendingRepository _lendingRepo;
  final LocalCacheService? _cache;

  double totalCapital = 0.0;
  List<TransactionModel> transactions = [];
  bool isLoading = false;
  bool _isInitialized = false; 
  String? errorMessage;
  ShareholderModel? currentShareholder;
  LoanModel? activeLoan;
  String? _userId;

  ShareCapitalViewModel(
    this._shareholderRepo,
    this._transactionRepo,
    this._lendingRepo, {
    LocalCacheService? cacheService,
  }) : _cache = cacheService;

  bool get isInitialized => _isInitialized;

  void setUserId(String? id) {
    if (_userId == id) return;
    _userId = id;

    if (_userId != null) {
      _isInitialized = false;
      fetchData(userId: _userId);
    } else {
      reset();
    }
  }

  String get shareholderFirstName {
    if (currentShareholder == null || currentShareholder!.fullName.isEmpty) {
      return 'User';
    }
    return currentShareholder!.fullName.trim().split(' ').first;
  }

  Future<void> fetchData({String? userId, bool forceRefresh = false}) async {
    final idToUse = userId ?? _userId;
    if (idToUse == null) return;
    
    if (_isInitialized && !forceRefresh) return;

    // 1. Try to load from Cache first (unless forcing refresh)
    if (_cache != null && !forceRefresh) {
      final cachedProfile = await _cache!.getData('shareholder_profile_$idToUse');
      final cachedTxs = await _cache!.getData('shareholder_txs_$idToUse');
      final cachedLoan = await _cache!.getData('shareholder_loan_$idToUse');

      if (cachedProfile != null) {
        currentShareholder = ShareholderModel.fromJson(cachedProfile);
        totalCapital = currentShareholder!.totalShareCapital;
        if (cachedTxs != null && cachedTxs is List) {
          transactions = cachedTxs.map((e) => TransactionModel.fromJson(e)).toList();
        }
        if (cachedLoan != null) {
          activeLoan = LoanModel.fromJson(cachedLoan);
        }
        _isInitialized = true;
        notifyListeners();
      }
    }

    if (!forceRefresh && _isInitialized) {
      // Trigger background update if we have cached data
      _performBackgroundFetch(idToUse);
      return;
    }

    if (isLoading) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    await _performBackgroundFetch(idToUse);
    
    isLoading = false;
    notifyListeners();
  }

  Future<void> _performBackgroundFetch(String userId) async {
    try {
      debugPrint('ShareCapitalVM: Fetching data for user: $userId');

      final shareholder = await _shareholderRepo.getShareholderByUserId(userId);

      if (shareholder == null) {
        errorMessage = "No shareholder profile linked to this account.";
        currentShareholder = null;
        totalCapital = 0.0;
        activeLoan = null;
      } else {
        currentShareholder = shareholder;
        totalCapital = shareholder.totalShareCapital;
        
        final results = await Future.wait([
          _transactionRepo.getTransactionsByShareholderId(shareholder.id),
          _lendingRepo.getLoansByShareholderId(shareholder.id),
        ]);

        final List<TransactionModel>? txs = results[0] as List<TransactionModel>?;
        final List<LoanModel>? loans = results[1] as List<LoanModel>?;

        transactions = txs ?? [];
        
        if (loans != null && loans.isNotEmpty) {
          // Sort by date descending to prioritize latest loans
          loans.sort((a, b) => b.disbursedAt.compareTo(a.disbursedAt));

          // A loan is considered active if it has remaining balance and is not fully paid/terminal
          activeLoan = loans.where((l) {
            final status = l.status.toLowerCase();
            final isTerminal = status == 'fullypaid' || status == 'rejected' || status == 'cancelled';
            return !isTerminal && l.remainingBalance > 0;
          }).firstOrNull;
          
          debugPrint('ShareCapitalVM: Found ${loans.length} loans. Active loan identified: ${activeLoan?.id} (Status: ${activeLoan?.status})');
        } else {
          activeLoan = null;
        }

        // Update Cache
        if (_cache != null) {
          await _cache!.saveData('shareholder_profile_$userId', shareholder.toJson());
          await _cache!.saveData('shareholder_txs_$userId', transactions.map((e) => e.toJson()).toList());
          if (activeLoan != null) {
            await _cache!.saveData('shareholder_loan_$userId', activeLoan!.toJson());
          } else {
            await _cache!.clearCache('shareholder_loan_$userId');
          }
        }
        
        _isInitialized = true;
        debugPrint('ShareCapitalVM: Successfully loaded dashboard for ${shareholder.fullName}');
      }
    } catch (e) {
      debugPrint('ShareCapitalViewModel Error: $e');
      if (!_isInitialized) {
        errorMessage = "Failed to sync records. Check your internet.";
      }
    } finally {
      notifyListeners();
    }
  }

  void reset() {
    _isInitialized = false;
    _userId = null;
    currentShareholder = null;
    transactions = [];
    totalCapital = 0.0;
    activeLoan = null;
    notifyListeners();
  }
}
