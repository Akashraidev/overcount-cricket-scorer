import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/utils/pdf_scorecard_generator.dart';
import '../../data/models/ball.dart';
import '../../data/models/batting_stat.dart';
import '../../data/models/bowling_stat.dart';
import '../../data/models/fall_of_wicket.dart';
import '../../data/models/innings.dart';
import '../../data/models/match.dart';
import '../../data/models/partnership.dart';
import '../../data/models/team.dart';
import '../../data/repositories/match_repository.dart';
import '../../data/repositories/scoring_repository.dart';
import '../../data/repositories/team_repository.dart';

class OverSummary {
  final int overNumber;
  final String bowlerName;
  final int runs;
  final int wickets;
  final List<Ball> balls;

  const OverSummary({
    required this.overNumber,
    required this.bowlerName,
    required this.runs,
    required this.wickets,
    required this.balls,
  });
}

class ScorecardProvider extends ChangeNotifier {
  final MatchRepository _matchRepo = MatchRepository();
  final TeamRepository _teamRepo = TeamRepository();
  final ScoringRepository _scoringRepo = ScoringRepository();

  CricketMatch? _match;
  Team? _teamA;
  Team? _teamB;
  List<Innings> _allInnings = [];
  int _selectedInningsIndex = 0;

  final Map<String, List<BattingStat>> _battingStatsMap = {};
  final Map<String, List<BowlingStat>> _bowlingStatsMap = {};
  final Map<String, List<FallOfWicket>> _fallOfWicketsMap = {};
  final Map<String, List<Partnership>> _partnershipsMap = {};
  final Map<String, List<Ball>> _ballsMap = {};
  final Map<String, List<OverSummary>> _overSummariesMap = {};

  bool _isLoading = false;

  CricketMatch? get match => _match;
  Team? get teamA => _teamA;
  Team? get teamB => _teamB;
  List<Innings> get allInnings => _allInnings;
  int get selectedInningsIndex => _selectedInningsIndex;
  bool get isLoading => _isLoading;

  Innings? get currentSelectedInnings {
    if (_allInnings.isEmpty || _selectedInningsIndex >= _allInnings.length) return null;
    return _allInnings[_selectedInningsIndex];
  }

  List<BattingStat> get currentBattingStats =>
      currentSelectedInnings != null ? (_battingStatsMap[currentSelectedInnings!.id] ?? []) : [];

  List<BowlingStat> get currentBowlingStats =>
      currentSelectedInnings != null ? (_bowlingStatsMap[currentSelectedInnings!.id] ?? []) : [];

  List<FallOfWicket> get currentFallOfWickets =>
      currentSelectedInnings != null ? (_fallOfWicketsMap[currentSelectedInnings!.id] ?? []) : [];

  List<Partnership> get currentPartnerships =>
      currentSelectedInnings != null ? (_partnershipsMap[currentSelectedInnings!.id] ?? []) : [];

  List<Ball> get currentBalls =>
      currentSelectedInnings != null ? (_ballsMap[currentSelectedInnings!.id] ?? []) : [];

  List<OverSummary> get currentOverSummaries =>
      currentSelectedInnings != null ? (_overSummariesMap[currentSelectedInnings!.id] ?? []) : [];

  void setSelectedInningsIndex(int index) {
    _selectedInningsIndex = index;
    notifyListeners();
  }

  Future<void> loadMatchScorecard(String matchId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _match = await _matchRepo.getMatchById(matchId);
      if (_match == null) return;

      _teamA = await _teamRepo.getTeamById(_match!.teamAId);
      _teamB = await _teamRepo.getTeamById(_match!.teamBId);

      final rawInnings = await _scoringRepo.getInningsForMatch(matchId);
      // Filter out empty phantom innings (e.g. 0 balls and 0 runs if inningsNumber > 2)
      _allInnings = rawInnings.where((inn) {
        if (inn.inningsNumber > 2 && inn.totalLegalBalls == 0 && inn.totalRuns == 0) {
          return false;
        }
        return true;
      }).toList();

      _battingStatsMap.clear();
      _bowlingStatsMap.clear();
      _fallOfWicketsMap.clear();
      _partnershipsMap.clear();
      _ballsMap.clear();
      _overSummariesMap.clear();

      for (final inn in _allInnings) {
        final batStats = await _scoringRepo.getBattingStats(inn.id);
        final bowlStats = await _scoringRepo.getBowlingStats(inn.id);
        final fows = await _scoringRepo.getFallOfWickets(inn.id);
        final partnerships = await _scoringRepo.getPartnerships(inn.id);
        final balls = await _scoringRepo.getBallsForInnings(inn.id);

        _battingStatsMap[inn.id] = batStats;
        _bowlingStatsMap[inn.id] = bowlStats;
        _fallOfWicketsMap[inn.id] = fows;
        _partnershipsMap[inn.id] = partnerships;
        _ballsMap[inn.id] = balls;

        // Group balls by over
        final overMap = <int, List<Ball>>{};
        for (final b in balls) {
          overMap.putIfAbsent(b.overNumber, () => []).add(b);
        }

        final summaries = <OverSummary>[];
        final sortedOvers = overMap.keys.toList()..sort();
        for (final ov in sortedOvers) {
          final oBalls = overMap[ov]!;
          final runs = oBalls.fold<int>(0, (sum, b) => sum + b.totalRuns);
          final wkts = oBalls.where((b) => b.isWicket).length;
          final bowlerName = oBalls.isNotEmpty ? oBalls.first.bowlerId : 'Bowler';
          summaries.add(OverSummary(
            overNumber: ov + 1,
            bowlerName: bowlerName,
            runs: runs,
            wickets: wkts,
            balls: oBalls,
          ));
        }
        _overSummariesMap[inn.id] = summaries;
      }

      if (_allInnings.isNotEmpty && _selectedInningsIndex >= _allInnings.length) {
        _selectedInningsIndex = 0;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Worm Chart Data (Cumulative Runs Per Over for Innings 1 and Innings 2)
  List<FlSpot> getWormSpotsForInnings(int inningsIndex) {
    if (inningsIndex >= _allInnings.length) return [];
    final inn = _allInnings[inningsIndex];
    final balls = _ballsMap[inn.id] ?? [];
    if (balls.isEmpty) return [const FlSpot(0, 0)];

    final spots = <FlSpot>[const FlSpot(0, 0)];
    int cumulativeRuns = 0;
    int legalBallCount = 0;

    for (final b in balls) {
      cumulativeRuns += b.totalRuns;
      if (b.isLegalBall) {
        legalBallCount++;
        final overDecimal = legalBallCount / 6.0;
        spots.add(FlSpot(overDecimal, cumulativeRuns.toDouble()));
      }
    }
    return spots;
  }

  // Run Rate Bar Chart Data (Runs in each over)
  List<BarChartGroupData> getRunRateBars(String inningsId) {
    final summaries = _overSummariesMap[inningsId] ?? [];
    return summaries.map((s) {
      return BarChartGroupData(
        x: s.overNumber,
        barRods: [
          BarChartRodData(
            toY: s.runs.toDouble(),
            color: s.wickets > 0 ? const Color(0xFFEF4444) : const Color(0xFF0F9D58),
            width: 12,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }

  Future<void> exportPdfScorecard() async {
    if (_match == null || _teamA == null || _teamB == null) return;
    await PdfScorecardGenerator.generateAndPrint(
      match: _match!,
      teamA: _teamA!,
      teamB: _teamB!,
      allInnings: _allInnings,
      battingStatsMap: _battingStatsMap,
      bowlingStatsMap: _bowlingStatsMap,
    );
  }

  Future<void> shareScorecardText() async {
    if (_match == null || _teamA == null || _teamB == null) return;

    final buffer = StringBuffer();
    buffer.writeln('🏏 ${_match!.title}');
    buffer.writeln('📍 ${_match!.venue}');
    if (_match!.resultSummary != null) {
      buffer.writeln('🏆 Result: ${_match!.resultSummary}');
    }
    buffer.writeln('────────────────────');

    for (final inn in _allInnings) {
      final teamName = inn.battingTeamId == _teamA!.id ? _teamA!.name : _teamB!.name;
      buffer.writeln('\n${inn.inningsNumber}st Innings: $teamName');
      buffer.writeln('${inn.totalRuns}/${inn.totalWickets} (${inn.oversDisplay} Overs)');

      final topBatters = _battingStatsMap[inn.id] ?? [];
      for (final b in topBatters.take(3)) {
        buffer.writeln('• ${b.playerName}: ${b.runs} (${b.balls})');
      }

      final topBowlers = _bowlingStatsMap[inn.id] ?? [];
      for (final bw in topBowlers.take(2)) {
        buffer.writeln('• ${bw.playerName}: ${bw.wickets}/${bw.runsConceded} (${bw.oversDisplay})');
      }
    }

    buffer.writeln('\nScored with Cricket Scorer App');
    await Share.share(buffer.toString(), subject: '${_match!.title} Scorecard');
  }
}
