import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/shareholder_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lending_models.dart';
import '../repositories/lending_repository.dart';
import '../repositories/shareholder_repository.dart';
import '../services/local_cache_service.dart';

class DashboardViewModel extends ChangeNotifier {
  final LendingRepository _lendingRepository;
  final ShareholderRepository _shareholderRepository;
  final LocalCacheService? _cache;

  List<KpiCardData> _kpiCards = [];
  List<LendingChartData> _chartData = [];
  List<UserTrendData> _userTrend = [];
  List<TransactionModel> _recentTransactions = [];
  String _greeting = '';
  String _currentDate = '';
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isInitializing = false;

  ChartFilter _selectedFilter = ChartFilter.month;

  String _searchQuery = '';
  List<ShareholderModel> _availableShareholders = [];
  List<ShareholderModel> _searchResults = [];
  RealtimeChannel? _dashboardRealtimeSubscription;

  Map<String, dynamic>? _rawStats;

  DashboardViewModel(this._lendingRepository, this._shareholderRepository, {LocalCacheService? cacheService}) 
      : _cache = cacheService {
    _updateGreetingAndDate();
  }

  List<KpiCardData> get kpiCards => _kpiCards;
  List<LendingChartData> get chartData => _chartData;
  List<UserTrendData> get userTrend => _userTrend;
  List<TransactionModel> get recentTransactions => _recentTransactions;
  String get greeting => _greeting;
  String get currentDate => _currentDate;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  List<ShareholderModel> get searchResults => _searchResults;
  ChartFilter get selectedFilter => _selectedFilter;

  Future<void> initDashboard({bool forceRefresh = false}) async {
    if ((_isInitialized || _isInitializing) && !forceRefresh) return;
    
    _isInitializing = true;
    
    // 1. Try to load from cache first for instant UI
    if (_cache != null) {
      final cachedKpis = await _cache!.getData('dashboard_kpis');
      final cachedRecent = await _cache!.getData('dashboard_recent');
      
      if (cachedKpis != null) {
        _kpiCards = (cachedKpis as List).map((e) => KpiCardData(
          label: e['label'],
          value: e['value'],
          icon: IconData(e['icon_code'], fontFamily: 'MaterialIcons'),
        )).toList();
      }
      
      if (cachedRecent != null) {
        _recentTransactions = (cachedRecent as List).map((e) => TransactionModel.fromJson(e)).toList();
      }

      if (_kpiCards.isNotEmpty) {
        _isInitialized = true;
        notifyListeners();
      }
    }

    try {
      await _loadData(showLoading: _kpiCards.isEmpty); // Only show loader if no cache
      await _loadShareholders();
      
      if (_dashboardRealtimeSubscription == null) {
        _initRealtimeListeners();
      }
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('Dashboard init error: $e');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  void setChartFilter(ChartFilter filter) {
    _selectedFilter = filter;
    notifyListeners();
    _loadData(showLoading: true);
  }

  void _updateGreetingAndDate() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour < 12) {
      _greeting = 'Good morning! 👋';
    } else if (hour < 17) {
      _greeting = 'Good afternoon! ☀️';
    } else {
      _greeting = 'Good evening! 🌙';
    }

    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    _currentDate = '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  Future<void> _loadData({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final String range = _selectedFilter == ChartFilter.week ? 'week' : (_selectedFilter == ChartFilter.year ? 'year' : 'month');
      
      final responses = await Future.wait([
        _lendingRepository.getCurrentInterestRate().catchError((e) => 0.032),
        _lendingRepository.getRecentLoanTransactions(limit: 5).catchError((e) => <TransactionModel>[]),
        _lendingRepository.getLendingChartMetrics(_selectedFilter).catchError((e) => <LendingChartData>[]),
        _lendingRepository.getDashboardStats(range: range).catchError((e) => null),
      ]);

      final interestRate = responses[0] as double;
      _recentTransactions = responses[1] as List<TransactionModel>;
      _chartData = responses[2] as List<LendingChartData>;
      _rawStats = responses[3] as Map<String, dynamic>?;

      _kpiCards = [];

      if (_rawStats != null && _rawStats!['user_stats'] != null) {
        final userStats = _rawStats!['user_stats'];
        _kpiCards.add(KpiCardData(
          label: 'Total Users',
          value: userStats['total_users']?.toString() ?? '0',
          icon: Icons.people_outline,
        ));
        _kpiCards.add(KpiCardData(
          label: 'Active Now',
          value: userStats['active_now']?.toString() ?? '0',
          icon: Icons.online_prediction_outlined,
        ));
        _kpiCards.add(KpiCardData(
          label: 'New Reg.',
          value: userStats['new_registrations']?.toString() ?? '0',
          icon: Icons.person_add_alt_1_outlined,
        ));
      } else {
         _kpiCards.add(KpiCardData(
          label: 'Interest Rate',
          value: '${(interestRate * 100).toStringAsFixed(1)}%',
          icon: Icons.schedule_rounded,
        ));
      }

      // Save to cache
      if (_cache != null) {
        _cache!.saveData('dashboard_kpis', _kpiCards.map((e) => {
          'label': e.label,
          'value': e.value,
          'icon_code': e.icon.codePoint,
        }).toList());
        _cache!.saveData('dashboard_recent', _recentTransactions.map((e) => e.toJson()).toList());
      }

    } catch (e) {
      debugPrint('Dashboard data processing error: $e');
    } finally {
      if (showLoading) _isLoading = false;
      notifyListeners();
    }
  }

  void _initRealtimeListeners() {
    try {
      _dashboardRealtimeSubscription = Supabase.instance.client
          .channel('public:shareholder_transactions_dashboard')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'transactions',
            callback: (payload) async => await _loadData(showLoading: false),
          )
          .subscribe();
    } catch (e) {
      debugPrint('Supabase Realtime Error: $e');
    }
  }

  Future<void> _loadShareholders() async {
    try {
      _availableShareholders = await _shareholderRepository.getShareholders(limit: 100);
    } catch (e) {
      _availableShareholders = [];
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _searchResults = [];
    } else {
      _searchResults = _availableShareholders.where((s) =>
        s.fullName.toLowerCase().contains(query.toLowerCase()) ||
        s.email.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
    notifyListeners();
  }

  Future<void> refreshData() async {
    await _loadData(showLoading: false);
    await _loadShareholders();
  }

  @override
  void dispose() {
    if (_dashboardRealtimeSubscription != null) Supabase.instance.client.removeChannel(_dashboardRealtimeSubscription!);
    super.dispose();
  }
}
