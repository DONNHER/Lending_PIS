import 'package:flutter/material.dart';
import '../models/lending_models.dart';
import '../models/activity_log_model.dart';
import '../repositories/shareholder_repository.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/lending_repository.dart';
import '../repositories/activity_log_repository.dart';
import '../repositories/auth_repository.dart';
import '../models/shareholder_model.dart';
import '../models/user_model.dart';

class ShareholderDetailViewModel extends ChangeNotifier {
  final ShareholderRepository _shareholderRepo;
  final TransactionRepository _transactionRepo;
  final LendingRepository _lendingRepo;
  final ActivityLogRepository _activityRepo;
  final AuthRepository _authRepo;
  final String? shareholderId;
  final String? userId;

  ShareholderModel? _shareholder;
  List<TransactionModel> _activities = [];
  List<ActivityLogModel> _recentActivityLogs = [];
  List<LoanModel> _loans = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Real data calculated from DB
  double outstandingBalance = 0.0;
  int activeLoans = 0;
  DateTime repaymentDue = DateTime.now();
  double totalPaid = 0.0;
  double totalLoanAmount = 0.0; 

  // Investment (Mocked for now as we don't have investments table yet)
  double estimatedPortfolio = 0.0;
  int investedFunds = 0;
  double roi = 0.0;

  ShareholderDetailViewModel({
    required ShareholderRepository shareholderRepo,
    required TransactionRepository transactionRepo,
    required LendingRepository lendingRepo,
    required ActivityLogRepository activityRepo,
    required AuthRepository authRepo,
    this.shareholderId,
    this.userId,
  })  : _shareholderRepo = shareholderRepo,
        _transactionRepo = transactionRepo,
        _lendingRepo = lendingRepo,
        _activityRepo = activityRepo,
        _authRepo = authRepo {
    fetchDetails();
  }

  ShareholderModel? get shareholder => _shareholder;
  List<TransactionModel> get activities => _activities;
  List<ActivityLogModel> get recentActivityLogs => _recentActivityLogs;
  List<LoanModel> get loans => _loans;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get paymentProgress => totalLoanAmount > 0 ? totalPaid / totalLoanAmount : 0;

  Future<void> fetchDetails() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    debugPrint('DEBUG: [ShareholderDetailVM] fetchDetails started. Params - shareholderId: "$shareholderId", userId: "$userId"');

    try {
      // 1. Try to find the shareholder record
      if (shareholderId != null && shareholderId!.isNotEmpty) {
        debugPrint('DEBUG: [ShareholderDetailVM] Attempting fetch by Shareholder ID: $shareholderId');
        _shareholder = await _shareholderRepo.getShareholderById(shareholderId!);
        if (_shareholder != null) debugPrint('DEBUG: [ShareholderDetailVM] Found via Shareholder ID');
      }
      
      // 2. If not found by SH ID, try by User ID (Checking for existing shareholder link)
      if (_shareholder == null && userId != null && userId!.isNotEmpty) {
        debugPrint('DEBUG: [ShareholderDetailVM] Attempting fetch by User ID (Shareholder lookup): $userId');
        _shareholder = await _shareholderRepo.getShareholderByUserId(userId!);
        if (_shareholder != null) debugPrint('DEBUG: [ShareholderDetailVM] Found via User ID lookup');
      }

      // 3. Fallback: If still null, try to get basic user info (for non-shareholders or newly registered)
      if (_shareholder == null && userId != null && userId!.isNotEmpty) {
        debugPrint('DEBUG: [ShareholderDetailVM] Attempting fallback fetch from general Users table with userId: $userId');
        _shareholder = await _shareholderRepo.getUserById(userId!);
        if (_shareholder != null) debugPrint('DEBUG: [ShareholderDetailVM] Found via general User fallback');
      }
      
      if (_shareholder == null) {
        debugPrint('DEBUG: [ShareholderDetailVM] FAILED: No record found for SH_ID: $shareholderId or U_ID: $userId');
        throw Exception('User not found');
      }

      final String actualShId = _shareholder!.id;
      final String actualUId = _shareholder!.userId;
      debugPrint('DEBUG: [ShareholderDetailVM] Resolved Profile - actualShId: "$actualShId", actualUId: "$actualUId"');

      // 4. Fetch Transactions (only if it's a shareholder)
      if (actualShId.isNotEmpty) {
        _activities = await _transactionRepo.getUserTransactions(shareholderId: actualShId, limit: 5);
      }

      // 5. Fetch Activity Logs
      if (actualUId.isNotEmpty) {
        _recentActivityLogs = await _activityRepo.getActivityLogs(
          userId: actualUId,
          limit: 5,
        );
      }

      // 6. Fetch Loans and calculate stats (only if it's a shareholder)
      if (actualShId.isNotEmpty) {
        _loans = await _lendingRepo.getLoansByShareholderId(actualShId);
        
        outstandingBalance = 0;
        activeLoans = 0;
        totalLoanAmount = 0;
        DateTime? earliestDue;

        for (var loan in _loans) {
          totalLoanAmount += loan.principalAmount;
          if (loan.status.toLowerCase() == 'active' || loan.status.toLowerCase() == 'released') {
            activeLoans++;
            outstandingBalance += loan.remainingBalance;
            
            if (loan.nextRepaymentDate != null) {
              if (earliestDue == null || loan.nextRepaymentDate!.isBefore(earliestDue)) {
                earliestDue = loan.nextRepaymentDate;
              }
            }
          }
        }
        
        repaymentDue = earliestDue ?? DateTime.now();

        // 7. Calculate Total Paid from Transactions
        final allPayments = await _transactionRepo.getUserTransactions(
          shareholderId: actualShId, 
          limit: 1000,
          typesIn: ['Loan Payment']
        );
        totalPaid = allPayments.fold(0.0, (sum, tx) => sum + tx.amount);

        // 8. Portfolio stats (Mocked until investment tables exist)
        estimatedPortfolio = _shareholder!.totalShareCapital * 1.05;
        investedFunds = 2;
        roi = 5.0;
      }

    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('DEBUG: [ShareholderDetailVM] EXCEPTION: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateAccountStatus(UserStatus status) async {
    if (_shareholder == null || _shareholder!.userId.isEmpty) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await _authRepo.updateStatus(_shareholder!.userId, status);
      await fetchDetails(); // Refresh to get updated status
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
