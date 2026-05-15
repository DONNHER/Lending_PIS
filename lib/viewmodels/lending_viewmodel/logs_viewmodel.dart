import 'package:flutter/foundation.dart';
import 'package:capstone_application/models/lending_models/transaction.dart';
// Import your separated repositories
import 'package:capstone_application/repositories/lending_repository/loans_repository.dart';
import 'package:capstone_application/repositories/lending_repository/transactions_repository.dart';
import 'package:capstone_application/repositories/lending_repository/shareholders_repository.dart';

enum ActivityState { idle, loading, error }
enum ActivityType { loan, payment, shareholder, adjustment }

/// Simple model to represent a unified UI activity item
class LendingActivity {
  final int id;
  final String title;
  final String description;
  final DateTime timestamp;
  final ActivityType type;

  LendingActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
  });
}

class ActivityLogsViewModel extends ChangeNotifier {
  final LoanRepository _loanRepo;
  final TransactionsRepository _transactionRepo;
  final ShareholderRepository _shareholderRepo;

  List<LendingActivity> _activities = [];
  ActivityState _state = ActivityState.idle;
  String? _errorMessage;

  ActivityLogsViewModel({
    required LoanRepository loanRepository,
    required TransactionsRepository transactionRepository,
    required ShareholderRepository shareholderRepository,
  })  : _loanRepo = loanRepository,
        _transactionRepo = transactionRepository,
        _shareholderRepo = shareholderRepository;

  // Getters
  List<LendingActivity> get activities => _activities;
  ActivityState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == ActivityState.loading;

  /// Loads all activities from multiple repositories and merges them
  Future<void> loadActivities() async {
    _state = ActivityState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch data in parallel for efficiency
      final results = await Future.wait([
        _loanRepo.getAllLoans(),
        _transactionRepo.getAllTransactions(),
        _shareholderRepo.getAllShareholders(),
      ]);

      final List<LendingActivity> combined = [];

      // 2. Map Loans to Activities
      final loans = results[0] as List; // Assumes List<LoanModel>
      for (var loan in loans) {
        combined.add(LendingActivity(
          id: loan.id,
          title: 'Loan ${loan.status.toUpperCase()}',
          description: '${loan.fullName} - PHP ${loan.amount}',
          timestamp: loan.createdAt ?? DateTime.now(),
          type: ActivityType.loan,
        ));
      }

      // 3. Map Transactions to Activities (Payments, Contributions, etc.)
      final transactions = results[1] as List<TransactionEntry>;
      for (var tx in transactions) {
        combined.add(LendingActivity(
          id: tx.id,
          title: tx.type.name.replaceFirst(tx.type.name[0], tx.type.name[0].toUpperCase()),
          description: '${tx.partyName}: ${tx.formattedAmount}',
          timestamp: tx.date,
          type: tx.type == TransactionType.repayment ? ActivityType.payment : ActivityType.adjustment,
        ));
      }

      // 4. Map Shareholders to Activities
      final shareholders = results[2] as List; // Assumes List<ShareholderModel>
      for (var sh in shareholders) {
        combined.add(LendingActivity(
          id: sh.id,
          title: 'New Shareholder',
          description: '${sh.fullName} joined the fund',
          timestamp: sh.joinedAt ?? DateTime.now(),
          type: ActivityType.shareholder,
        ));
      }

      // 5. Sort: Newest First
      combined.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      _activities = combined;
      _state = ActivityState.idle;
    } catch (e) {
      _state = ActivityState.error;
      _errorMessage = 'Failed to load activity logs: $e';
    }
    
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _state = ActivityState.idle;
    notifyListeners();
  }
}