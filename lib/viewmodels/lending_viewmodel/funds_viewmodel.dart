import 'package:flutter/foundation.dart';
import 'package:capstone_application/repositories/lending_repository/dashboard_repository.dart';
import 'package:capstone_application/repositories/lending_repository/transactions_repository.dart';

enum FundState { idle, loading, error }

/// Model for the summary data
class FundSummary {
  final double totalCapital;
  final double totalDisbursed;
  final double totalCollected;
  final double availableBalance;

  FundSummary({
    required this.totalCapital,
    required this.totalDisbursed,
    required this.totalCollected,
    required this.availableBalance,
  });
}

class FundManagementViewModel extends ChangeNotifier {
  final DashboardRepository _dashboardRepo;
  final TransactionsRepository _transactionRepo;

  FundSummary? _summary;
  FundState _state = FundState.idle;
  String? _errorMessage;

  FundManagementViewModel({
    required DashboardRepository dashboardRepository,
    required TransactionsRepository transactionRepository,
  })  : _dashboardRepo = dashboardRepository,
        _transactionRepo = transactionRepository;

  // Getters
  FundSummary? get summary => _summary;
  FundState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == FundState.loading;

  /// Fetches aggregated metrics from the Dashboard Repository
  Future<void> loadFundStatus() async {
    _state = FundState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Use our high-speed aggregated overview stats
      final stats = await _dashboardRepo.getOverviewStats();

      // For 'totalCapital', we usually sum all shareholder contributions. 
      // For now, we'll derive it or use a default if your DB doesn't have a total_capital view yet.
      final double disbursed = (stats['total_disbursed'] as num).toDouble();
      final double collected = (stats['total_collected'] as num).toDouble();
      
      // Assume initial capital logic or fetch from a specific setting
      const double baseCapital = 500000.0; 

      _summary = FundSummary(
        totalCapital: baseCapital,
        totalDisbursed: disbursed,
        totalCollected: collected,
        availableBalance: baseCapital - disbursed + collected,
      );

      _state = FundState.idle;
    } catch (e) {
      _state = FundState.error;
      _errorMessage = 'Failed to load fund metrics: $e';
    }
    notifyListeners();
  }

  /// Inject new capital into the fund
  Future<bool> addCapital({
    required double amount,
    required String shareholderName,
    required String description,
  }) async {
    try {
      _state = FundState.loading;
      notifyListeners();

      // Record this as a 'contribution' type transaction
      await _transactionRepo.logFundMovement(
        amount: amount,
        type: 'contribution',
        referenceId: 'CAP-${DateTime.now().millisecondsSinceEpoch}',
        description: '$shareholderName: $description',
      );

      await loadFundStatus(); // Refresh summary metrics
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _state = FundState.error;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    _state = FundState.idle;
    notifyListeners();
  }
}