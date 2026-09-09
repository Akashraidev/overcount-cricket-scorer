import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/database/database_service.dart';
import '../../data/database/db_tables.dart';
import '../../data/models/innings.dart';
import '../../data/models/match.dart';
import '../../data/repositories/match_repository.dart';

class CreateMatchDraft {
  String title = '';
  String? tournamentId;
  String venue = '';
  DateTime matchDate = DateTime.now();
  String format = 'T20';
  int totalOvers = 20;
  int wicketsPerInnings = 10;
  int ballsPerOver = 6;
  String? teamAId;
  String? teamBId;
  List<String> teamAPlayingXi = [];
  List<String> teamBPlayingXi = [];
  String? teamACaptainId;
  String? teamAWkId;
  String? teamBCaptainId;
  String? teamBWkId;
  String? tossWinnerTeamId;
  String tossDecision = 'Bat';
  String? openingStrikerId;
  String? openingNonStrikerId;
  String? openingBowlerId;
  int? maxOversPerBowler; // null = auto, 0 = Unlimited, > 0 = custom limit

  void reset() {
    title = '';
    tournamentId = null;
    venue = '';
    matchDate = DateTime.now();
    format = 'T20';
    totalOvers = 20;
    wicketsPerInnings = 10;
    ballsPerOver = 6;
    teamAId = null;
    teamBId = null;
    teamAPlayingXi = [];
    teamBPlayingXi = [];
    teamACaptainId = null;
    teamAWkId = null;
    teamBCaptainId = null;
    teamBWkId = null;
    tossWinnerTeamId = null;
    tossDecision = 'Bat';
    openingStrikerId = null;
    openingNonStrikerId = null;
    openingBowlerId = null;
  }
}

class MatchProvider extends ChangeNotifier {
  final MatchRepository _matchRepo = MatchRepository();
  final _uuid = const Uuid();

  List<CricketMatch> _matches = [];
  CricketMatch? _activeMatch;
  Innings? _activeMatchCurrentInnings;
  List<CricketMatch> _recentMatches = [];
  Map<String, int> _matchCounts = {'total': 0, 'live': 0, 'completed': 0, 'upcoming': 0};
  bool _isLoading = false;
  String _statusFilter = 'All';
  String? _tournamentFilter;
  String _searchQuery = '';

  final CreateMatchDraft _draft = CreateMatchDraft();

  List<CricketMatch> get matches {
    return _matches.where((m) {
      final matchesStatus = _statusFilter == 'All' || m.status.toLowerCase() == _statusFilter.toLowerCase();
      final matchesTourney = _tournamentFilter == null || m.tournamentId == _tournamentFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          m.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.venue.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesStatus && matchesTourney && matchesSearch;
    }).toList();
  }

  CricketMatch? get activeMatch => _activeMatch;
  Innings? get activeMatchCurrentInnings => _activeMatchCurrentInnings;
  List<CricketMatch> get recentMatches => _recentMatches;
  Map<String, int> get matchCounts => _matchCounts;
  bool get isLoading => _isLoading;
  String get statusFilter => _statusFilter;
  String? get tournamentFilter => _tournamentFilter;
  String get searchQuery => _searchQuery;
  CreateMatchDraft get draft => _draft;

  MatchProvider() {
    loadMatches();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setTournamentFilter(String? tourneyId) {
    _tournamentFilter = tourneyId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadMatches() async {
    _isLoading = true;
    notifyListeners();
    try {
      _matches = await _matchRepo.getAllMatches();
      _activeMatch = await _matchRepo.getLatestActiveMatch();
      if (_activeMatch != null) {
        final db = await DatabaseService.instance.database;
        final innMaps = await db.query(
          DbTables.innings,
          where: 'matchId = ? AND inningsNumber = ?',
          whereArgs: [_activeMatch!.id, _activeMatch!.currentInningsNumber],
          limit: 1,
        );
        if (innMaps.isNotEmpty) {
          _activeMatchCurrentInnings = Innings.fromMap(innMaps.first);
        }
      } else {
        _activeMatchCurrentInnings = null;
      }
      _recentMatches = await _matchRepo.getRecentMatches(limit: 6);
      _matchCounts = await _matchRepo.getMatchCounts();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<CricketMatch> createMatchFromDraft() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final matchId = _uuid.v4();

    // Determine 1st Innings batting and bowling teams based on toss
    String batTeamId;
    String bowlTeamId;

    if (_draft.tossWinnerTeamId == _draft.teamAId) {
      if (_draft.tossDecision.toLowerCase() == 'bat') {
        batTeamId = _draft.teamAId!;
        bowlTeamId = _draft.teamBId!;
      } else {
        batTeamId = _draft.teamBId!;
        bowlTeamId = _draft.teamAId!;
      }
    } else {
      if (_draft.tossDecision.toLowerCase() == 'bat') {
        batTeamId = _draft.teamBId!;
        bowlTeamId = _draft.teamAId!;
      } else {
        batTeamId = _draft.teamAId!;
        bowlTeamId = _draft.teamBId!;
      }
    }

    final match = CricketMatch(
      id: matchId,
      tournamentId: _draft.tournamentId,
      title: _draft.title.trim().isNotEmpty
          ? _draft.title.trim()
          : 'Match ${DateTime.now().day}/${DateTime.now().month}',
      venue: _draft.venue.trim().isNotEmpty ? _draft.venue.trim() : 'Stadium',
      matchDate: _draft.matchDate.millisecondsSinceEpoch,
      format: _draft.format,
      totalOvers: _draft.totalOvers,
      wicketsPerInnings: _draft.wicketsPerInnings,
      ballsPerOver: _draft.ballsPerOver,
      teamAId: _draft.teamAId!,
      teamBId: _draft.teamBId!,
      tossWinnerTeamId: _draft.tossWinnerTeamId,
      tossDecision: _draft.tossDecision,
      status: 'live',
      currentInningsNumber: 1,
      createdAt: now,
    );

    final db = await DatabaseService.instance.database;

    await db.transaction((txn) async {
      // 1. Insert Match
      await txn.insert(DbTables.matches, match.toMap());

      // Auto populate playing XI if not explicitly configured in Step 3
      if (_draft.teamAPlayingXi.isEmpty) {
        final allA = await txn.query(DbTables.players, where: 'teamId = ?', whereArgs: [_draft.teamAId]);
        _draft.teamAPlayingXi = allA.map((m) => m['id'] as String).toList();
      }
      if (_draft.teamBPlayingXi.isEmpty) {
        final allB = await txn.query(DbTables.players, where: 'teamId = ?', whereArgs: [_draft.teamBId]);
        _draft.teamBPlayingXi = allB.map((m) => m['id'] as String).toList();
      }

      // Ensure opener IDs are in the squad if added
      if (_draft.openingStrikerId != null && !_draft.teamAPlayingXi.contains(_draft.openingStrikerId) && !_draft.teamBPlayingXi.contains(_draft.openingStrikerId)) {
        if (batTeamId == _draft.teamAId) {
          _draft.teamAPlayingXi.add(_draft.openingStrikerId!);
        } else {
          _draft.teamBPlayingXi.add(_draft.openingStrikerId!);
        }
      }
      if (_draft.openingNonStrikerId != null && !_draft.teamAPlayingXi.contains(_draft.openingNonStrikerId) && !_draft.teamBPlayingXi.contains(_draft.openingNonStrikerId)) {
        if (batTeamId == _draft.teamAId) {
          _draft.teamAPlayingXi.add(_draft.openingNonStrikerId!);
        } else {
          _draft.teamBPlayingXi.add(_draft.openingNonStrikerId!);
        }
      }
      if (_draft.openingBowlerId != null && !_draft.teamAPlayingXi.contains(_draft.openingBowlerId) && !_draft.teamBPlayingXi.contains(_draft.openingBowlerId)) {
        if (bowlTeamId == _draft.teamAId) {
          _draft.teamAPlayingXi.add(_draft.openingBowlerId!);
        } else {
          _draft.teamBPlayingXi.add(_draft.openingBowlerId!);
        }
      }

      // 2. Insert Match Squads
      for (final pId in _draft.teamAPlayingXi) {
        await txn.insert(DbTables.matchSquads, {
          'id': _uuid.v4(),
          'matchId': matchId,
          'teamId': _draft.teamAId,
          'playerId': pId,
          'isPlayingXi': 1,
          'isCaptain': pId == _draft.teamACaptainId ? 1 : 0,
          'isWicketKeeper': pId == _draft.teamAWkId ? 1 : 0,
          'battingOrder': 0,
        });
      }

      for (final pId in _draft.teamBPlayingXi) {
        await txn.insert(DbTables.matchSquads, {
          'id': _uuid.v4(),
          'matchId': matchId,
          'teamId': _draft.teamBId,
          'playerId': pId,
          'isPlayingXi': 1,
          'isCaptain': pId == _draft.teamBCaptainId ? 1 : 0,
          'isWicketKeeper': pId == _draft.teamBWkId ? 1 : 0,
          'battingOrder': 0,
        });
      }

      // 3. Insert Initial 1st Innings
      final inn1 = Innings(
        id: _uuid.v4(),
        matchId: matchId,
        inningsNumber: 1,
        battingTeamId: batTeamId,
        bowlingTeamId: bowlTeamId,
        createdAt: now,
      );
      await txn.insert(DbTables.innings, inn1.toMap());

      // 4. If openers were selected in Step 5, initialize their stats immediately!
      if (_draft.openingStrikerId != null && _draft.openingNonStrikerId != null) {
        final strikerMaps = await txn.query(DbTables.players, where: 'id = ?', whereArgs: [_draft.openingStrikerId]);
        final nonStrikerMaps = await txn.query(DbTables.players, where: 'id = ?', whereArgs: [_draft.openingNonStrikerId]);
        final strikerName = strikerMaps.isNotEmpty ? strikerMaps.first['name'] as String : 'Striker';
        final nonStrikerName = nonStrikerMaps.isNotEmpty ? nonStrikerMaps.first['name'] as String : 'Non-Striker';

        await txn.insert(DbTables.battingStats, {
          'id': _uuid.v4(),
          'inningsId': inn1.id,
          'playerId': _draft.openingStrikerId,
          'playerName': strikerName,
          'runs': 0,
          'balls': 0,
          'fours': 0,
          'sixes': 0,
          'dots': 0,
          'isOut': 0,
          'battingOrder': 1,
        });

        await txn.insert(DbTables.battingStats, {
          'id': _uuid.v4(),
          'inningsId': inn1.id,
          'playerId': _draft.openingNonStrikerId,
          'playerName': nonStrikerName,
          'runs': 0,
          'balls': 0,
          'fours': 0,
          'sixes': 0,
          'dots': 0,
          'isOut': 0,
          'battingOrder': 2,
        });

        await txn.insert(DbTables.partnerships, {
          'id': _uuid.v4(),
          'inningsId': inn1.id,
          'wicketNumber': 1,
          'batter1Id': _draft.openingStrikerId,
          'batter1Name': strikerName,
          'batter1Runs': 0,
          'batter1Balls': 0,
          'batter2Id': _draft.openingNonStrikerId,
          'batter2Name': nonStrikerName,
          'batter2Runs': 0,
          'batter2Balls': 0,
          'totalRuns': 0,
          'totalBalls': 0,
          'isUnbroken': 1,
        });
      }

      if (_draft.openingBowlerId != null) {
        final bowlerMaps = await txn.query(DbTables.players, where: 'id = ?', whereArgs: [_draft.openingBowlerId]);
        final bowlerName = bowlerMaps.isNotEmpty ? bowlerMaps.first['name'] as String : 'Bowler';

        await txn.insert(DbTables.bowlingStats, {
          'id': _uuid.v4(),
          'inningsId': inn1.id,
          'playerId': _draft.openingBowlerId,
          'playerName': bowlerName,
          'totalLegalBalls': 0,
          'maidens': 0,
          'runsConceded': 0,
          'wickets': 0,
          'wides': 0,
          'noBalls': 0,
          'dots': 0,
          'bowlingOrder': 1,
        });
      }
    });

    _draft.reset();
    await loadMatches();
    return match;
  }

  Future<void> deleteMatch(String id) async {
    await _matchRepo.deleteMatch(id);
    await loadMatches();
  }
}
