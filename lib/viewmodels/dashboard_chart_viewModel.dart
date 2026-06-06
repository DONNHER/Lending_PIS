import 'dart:async';
import 'package:flutter/material.dart';
import '../models/lending_models.dart';
import '../repositories/lending_repository.dart';

class DashboardChartViewModel extends ChangeNotifier {
  final LendingRepository _repository;
  List<LendingChartData> _chartData = [];
  Timer? _pollingTimer;

  DashboardChartViewModel(this._repository) {
    startLiveUpdates();
  }

  List<LendingChartData> get chartData => _chartData;

  // Fetch data from database and notify UI listeners
  Future<void> fetchLiveChartData() async {
    try {
      // Fetch latest aggregates from database/repository
      // Pass a default filter to fix the positional argument error
      final freshData = await _repository.getLendingChartMetrics(ChartFilter.month);
      _chartData = freshData;
      notifyListeners(); 
    } catch (e) {
      debugPrint("Error loading live chart data: $e");
    }
  }

  // Starts background synchronization every 5 seconds
  void startLiveUpdates() {
    fetchLiveChartData(); // Initial load
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      fetchLiveChartData();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel(); 
    super.dispose();
  }
}
