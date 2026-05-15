import 'package:flutter/foundation.dart';
import 'package:capstone_application/models/lending_models/loan.dart';
import 'package:capstone_application/repositories/lending_repository/dashboard_repository.dart';
import 'package:capstone_application/repositories/lending_repository/loans_repository.dart';

enum DashboardState { idle, loading, error }

/// Model for the main KPI cards
class DashboardMetrics {
  final double totalReceivables;
  final double collectionRate;
  final int activeLoansCount;
  final int pendingRequestsCount;
  final List<double> monthlyGrowth;

  DashboardMetrics({
    required this.totalReceivables,
    required this.collectionRate,
    required this.activeLoansCount,
    required this.pendingRequestsCount,
    required this.monthlyGrowth,
  });
}

class DashboardViewModel extends ChangeNotifier {
  final DashboardRepository _dashboardRepo;
  final LoanRepository _loanRepo;

  DashboardMetrics? _metrics;
  List<Loan> _recentLoans = [];
  DashboardState _state = DashboardState.idle;
  String? _errorMessage;

  DashboardViewModel({
    required DashboardRepository dashboardRepository,
    required LoanRepository loanRepository,
  })  : _dashboardRepo = dashboardRepository,
        _loanRepo = loanRepository;

  // Getters
  DashboardMetrics? get metrics => _metrics;
  List<Loan> get recentLoans => _recentLoans;
  DashboardState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == DashboardState.loading;

  /// Aggregates data for the dashboard view using specialized repositories
  Future<void> loadDashboardData() async {
    _state = DashboardState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch aggregated stats and recent loans in parallel
      final results = await Future.wait([
        _dashboardRepo.getOverviewStats(),
        _loanRepo.getAllLoans(), // Fetch all to get the top 5
      ]);

      final stats = results[0] as Map<String, dynamic>;
      final allLoans = results[1] as List<Loan>;

      // 2. Extract metrics from the aggregated result
      // These keys match the DashboardRepository return we fixed earlier
      final double totalDisbursed = (stats['total_disbursed'] as num).toDouble();
      final double totalCollected = (stats['total_collected'] as num).toDouble();
      final int loansCount = stats['total_loans_count'] as int;

      // 3. Logic-based calculations
      // Receivables is typically Disbursed minus Collected Principal
      final double receivables = totalDisbursed - totalCollected;
      
      // Calculate Collection Rate
      final double rate = (totalDisbursed == 0) 
          ? 0 
          : (totalCollected / totalDisbursed) * 100;

      _metrics = DashboardMetrics(
        totalReceivables: receivables,
        collectionRate: rate,
        activeLoansCount: loansCount, // You can refine this by status in the repo if needed
        pendingRequestsCount: allLoans.where((l) => l.status == 'pending').length,
        monthlyGrowth: [12.0, 18.0, 40.0, 35.0, 60.0], // Chart data
      );

      // 4. Get top 5 recent loans
      _recentLoans = allLoans.take(5).toList();

      _state = DashboardState.idle;
    } catch (e) {
      _state = DashboardState.error;
      _errorMessage = 'Dashboard load failed: $e';
    }
    notifyListeners();
  }

  /// Force a refresh of the dashboard
  Future<void> refresh() => loadDashboardData();

  void clearError() {
    _errorMessage = null;
    _state = DashboardState.idle;
    notifyListeners();
  }
}