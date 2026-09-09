import 'package:flutter/material.dart';
import '../../data/repositories/statistics_repository.dart';

class StatisticsProvider extends ChangeNotifier {
  final StatisticsRepository _statsRepo = StatisticsRepository();

  List<LeaderboardBatter> _topBatters = [];
  List<LeaderboardBowler> _topBowlers = [];
  bool _isLoading = false;

  List<LeaderboardBatter> get topBatters => _topBatters;
  List<LeaderboardBowler> get topBowlers => _topBowlers;
  bool get isLoading => _isLoading;

  StatisticsProvider() {
    loadLeaderboards();
  }

  Future<void> loadLeaderboards() async {
    _isLoading = true;
    notifyListeners();
    try {
      _topBatters = await _statsRepo.getTopRunScorers(limit: 20);
      _topBowlers = await _statsRepo.getTopWicketTakers(limit: 20);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
