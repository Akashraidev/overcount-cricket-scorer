import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/commentary_generator.dart';
import '../../data/database/database_service.dart';
import '../../data/database/db_tables.dart';
import '../../data/models/ball.dart';
import '../../data/models/batting_stat.dart';
import '../../data/models/bowling_stat.dart';
import '../../data/models/fall_of_wicket.dart';
import '../../data/models/innings.dart';
import '../../data/models/local_scoring_models.dart';
import '../../data/models/match.dart';
import '../../data/models/partnership.dart';
import '../../data/models/player.dart';
import '../../data/models/team.dart';
import '../../data/repositories/match_repository.dart';
import '../../data/repositories/player_repository.dart';
import '../../data/repositories/scoring_repository.dart';
import '../../data/repositories/team_repository.dart';

class ScoringProvider extends ChangeNotifier {
  final ScoringRepository _scoringRepo = ScoringRepository();
  final MatchRepository _matchRepo = MatchRepository();
  final TeamRepository _teamRepo = TeamRepository();
  final PlayerRepository _playerRepo = PlayerRepository();
  final _uuid = const Uuid();

  void Function(LiveMatchSnapshot snapshot)? onSnapshotUpdated;

  CricketMatch? _match;
  Innings? _currentInnings;
  Innings? _firstInnings; // For 2nd innings target reference
  Team? _battingTeam;
  Team? _bowlingTeam;

  Player? _striker;
  Player? _nonStriker;
  Player? _currentBowler;

  List<Player> _battingSquad = [];
  List<Player> _bowlingSquad = [];
  List<Ball> _allBalls = [];
  List<BattingStat> _battingStats = [];
  List<BowlingStat> _bowlingStats = [];
  Partnership? _currentPartnership;
  List<FallOfWicket> _fallOfWickets = [];

  bool _isLoading = false;
  bool _isOverComplete = false;
  bool _isInningsComplete = false;
  bool _isMatchComplete = false;
  String? _matchResultSummary;

  // Getters
  CricketMatch? get match => _match;
  Innings? get currentInnings => _currentInnings;
  Innings? get firstInnings => _firstInnings;
  Team? get battingTeam => _battingTeam;
  Team? get bowlingTeam => _bowlingTeam;

  Player? get striker => _striker;
  Player? get nonStriker => _nonStriker;
  Player? get currentBowler => _currentBowler;

  List<Player> get battingSquad => _battingSquad;
  List<Player> get bowlingSquad => _bowlingSquad;
  List<Ball> get allBalls => _allBalls;
  List<BattingStat> get battingStats => _battingStats;
  List<BowlingStat> get bowlingStats => _bowlingStats;
  Partnership? get currentPartnership => _currentPartnership;
  List<FallOfWicket> get fallOfWickets => _fallOfWickets;

  bool get isLoading => _isLoading;
  bool get isOverComplete => _isOverComplete;
  bool get isInningsComplete => _isInningsComplete;
  bool get isMatchComplete => _isMatchComplete;
  String? get matchResultSummary => _matchResultSummary;
  Player? _previousBowler;
  Player? get previousBowler => _previousBowler;

  int? _customMaxOversPerBowler; // null = auto calculate, 0 = Unlimited (no limit), > 0 = custom limit
  int? get customMaxOversPerBowler => _customMaxOversPerBowler;

  bool get isUnlimitedBowlerOvers => _customMaxOversPerBowler == 0 || (_customMaxOversPerBowler == null && _match?.format == 'Test');

  int get maxOversPerBowler {
    if (_customMaxOversPerBowler != null) {
      return _customMaxOversPerBowler!;
    }
    if (_match == null) return 4;
    if (_match!.totalOvers <= 5) return 2;
    return (_match!.totalOvers / 5).ceil();
  }

  void setMaxOversPerBowler(int? limit) {
    _customMaxOversPerBowler = limit;
    notifyListeners();
  }

  LiveMatchSnapshot? createLiveSnapshot() {
    if (_match == null || _currentInnings == null || _battingTeam == null || _bowlingTeam == null) {
      return null;
    }
    return LiveMatchSnapshot(
      match: _match!,
      currentInnings: _currentInnings!,
      firstInnings: _firstInnings,
      battingTeam: _battingTeam!,
      bowlingTeam: _bowlingTeam!,
      striker: _striker,
      nonStriker: _nonStriker,
      currentBowler: _currentBowler,
      battingSquad: List.unmodifiable(_battingSquad),
      bowlingSquad: List.unmodifiable(_bowlingSquad),
      battingStats: List.unmodifiable(_battingStats),
      bowlingStats: List.unmodifiable(_bowlingStats),
      recentBalls: List.unmodifiable(_allBalls),
      currentPartnership: _currentPartnership,
      fallOfWickets: List.unmodifiable(_fallOfWickets),
      isOverComplete: _isOverComplete,
      isInningsComplete: _isInningsComplete,
      isMatchComplete: _isMatchComplete,
      matchResultSummary: _matchResultSummary,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    final snap = createLiveSnapshot();
    if (snap != null) {
      onSnapshotUpdated?.call(snap);
    }
  }

  int getBowlerLegalBalls(String bowlerId) {
    final stat = _bowlingStats.cast<BowlingStat?>().firstWhere(
      (s) => s?.playerId == bowlerId,
      orElse: () => null,
    );
    return stat?.totalLegalBalls ?? 0;
  }

  int getBowlerCompletedOvers(String bowlerId) {
    final balls = getBowlerLegalBalls(bowlerId);
    return balls ~/ (_match?.ballsPerOver ?? 6);
  }

  bool canBowlerBowl(String bowlerId) {
    if (_bowlingSquad.length > 1 && _previousBowler?.id == bowlerId) {
      return false;
    }
    if (!isUnlimitedBowlerOvers && maxOversPerBowler > 0) {
      final completedOvers = getBowlerCompletedOvers(bowlerId);
      if (completedOvers >= maxOversPerBowler) {
        return false;
      }
    }
    return true;
  }

  bool get isCurrentInningsOversCompleted {
    if (_match == null || _currentInnings == null) return false;
    if (_match!.format == 'Test') return false;
    final maxBalls = _match!.totalOvers * (_match!.ballsPerOver);
    return maxBalls > 0 && _currentInnings!.totalLegalBalls >= maxBalls;
  }

  bool get isUndoAvailable => _allBalls.isNotEmpty;

  List<Ball> get currentOverBalls {
    if (_allBalls.isEmpty || _currentInnings == null) return [];
    final currentOverNum = _currentInnings!.totalLegalBalls ~/ (_match?.ballsPerOver ?? 6);
    return _allBalls.where((b) => b.overNumber == currentOverNum).toList();
  }

  BattingStat? get strikerStat {
    if (_striker == null) return null;
    try {
      return _battingStats.firstWhere((s) => s.playerId == _striker!.id);
    } catch (_) {
      return null;
    }
  }

  BattingStat? get nonStrikerStat {
    if (_nonStriker == null) return null;
    try {
      return _battingStats.firstWhere((s) => s.playerId == _nonStriker!.id);
    } catch (_) {
      return null;
    }
  }

  BowlingStat? get currentBowlerStat {
    if (_currentBowler == null) return null;
    try {
      return _bowlingStats.firstWhere((s) => s.playerId == _currentBowler!.id);
    } catch (_) {
      return null;
    }
  }

  List<Player> get availableBatters {
    final battedPlayerIds = _battingStats.map((s) => s.playerId).toSet();
    return _battingSquad.where((p) => !battedPlayerIds.contains(p.id)).toList();
  }

  List<Player> get availableBowlers {
    if (_currentBowler == null) return _bowlingSquad;
    return _bowlingSquad.toList();
  }

  /// Clear previous match state immediately so old match completion data doesn't persist
  void clearMatchState() {
    _isLoading = true;
    _match = null;
    _currentInnings = null;
    _firstInnings = null;
    _battingTeam = null;
    _bowlingTeam = null;
    _striker = null;
    _nonStriker = null;
    _currentBowler = null;
    _previousBowler = null;
    _battingSquad = [];
    _bowlingSquad = [];
    _allBalls = [];
    _battingStats = [];
    _bowlingStats = [];
    _currentPartnership = null;
    _fallOfWickets = [];
    _isOverComplete = false;
    _isInningsComplete = false;
    _isMatchComplete = false;
    _matchResultSummary = null;
    _customMaxOversPerBowler = null;
  }

  // --- INITIALIZATION ---
  Future<void> loadLiveMatch(String matchId) async {
    clearMatchState();
    notifyListeners();

    try {
      _match = await _matchRepo.getMatchById(matchId);
      if (_match == null) return;

      final allInnings = await _scoringRepo.getInningsForMatch(matchId);
      if (allInnings.isEmpty) return;

      _currentInnings = allInnings.firstWhere(
        (inn) => inn.inningsNumber == _match!.currentInningsNumber,
        orElse: () => allInnings.last,
      );

      if (allInnings.length > 1) {
        _firstInnings = allInnings.first;
      }

      _battingTeam = await _teamRepo.getTeamById(_currentInnings!.battingTeamId);
      _bowlingTeam = await _teamRepo.getTeamById(_currentInnings!.bowlingTeamId);

      // Load squads
      final db = await DatabaseService.instance.database;
      final batSquadMaps = await db.rawQuery('''
        SELECT p.* FROM ${DbTables.players} p
        INNER JOIN ${DbTables.matchSquads} ms ON p.id = ms.playerId
        WHERE ms.matchId = ? AND ms.teamId = ?
      ''', [matchId, _currentInnings!.battingTeamId]);

      if (batSquadMaps.isNotEmpty) {
        _battingSquad = batSquadMaps.map((m) => Player.fromMap(m)).toList();
      } else {
        _battingSquad = await _playerRepo.getPlayersByTeam(_currentInnings!.battingTeamId);
      }

      final bowlSquadMaps = await db.rawQuery('''
        SELECT p.* FROM ${DbTables.players} p
        INNER JOIN ${DbTables.matchSquads} ms ON p.id = ms.playerId
        WHERE ms.matchId = ? AND ms.teamId = ?
      ''', [matchId, _currentInnings!.bowlingTeamId]);

      if (bowlSquadMaps.isNotEmpty) {
        _bowlingSquad = bowlSquadMaps.map((m) => Player.fromMap(m)).toList();
      } else {
        _bowlingSquad = await _playerRepo.getPlayersByTeam(_currentInnings!.bowlingTeamId);
      }

      // Load live innings data
      await _loadInningsData(_currentInnings!.id);

      _checkInningsStatus();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadInningsData(String inningsId) async {
    _allBalls = await _scoringRepo.getBallsForInnings(inningsId);
    _battingStats = await _scoringRepo.getBattingStats(inningsId);
    _bowlingStats = await _scoringRepo.getBowlingStats(inningsId);
    _fallOfWickets = await _scoringRepo.getFallOfWickets(inningsId);

    final partnerships = await _scoringRepo.getPartnerships(inningsId);
    _currentPartnership = partnerships.isNotEmpty ? partnerships.last : null;

    // Detect active striker, non-striker, and bowler from last ball or stats
    if (_allBalls.isNotEmpty) {
      final lastBall = _allBalls.last;
      _striker = _battingSquad.firstWhere(
        (p) => p.id == (lastBall.strikeChanged ? lastBall.nonStrikerId : lastBall.batsmanId),
        orElse: () => _battingSquad.first,
      );
      _nonStriker = _battingSquad.firstWhere(
        (p) => p.id == (lastBall.strikeChanged ? lastBall.batsmanId : lastBall.nonStrikerId),
        orElse: () => _battingSquad.length > 1 ? _battingSquad[1] : _battingSquad.first,
      );
      _currentBowler = _bowlingSquad.firstWhere(
        (p) => p.id == lastBall.bowlerId,
        orElse: () => _bowlingSquad.first,
      );
    } else {
      // Default initial players if available
      final notOutBatters = _battingStats.where((s) => !s.isOut).toList();
      if (notOutBatters.length >= 2) {
        _striker = _battingSquad.firstWhere((p) => p.id == notOutBatters[0].playerId);
        _nonStriker = _battingSquad.firstWhere((p) => p.id == notOutBatters[1].playerId);
      } else if (_battingSquad.length >= 2) {
        _striker = _battingSquad[0];
        _nonStriker = _battingSquad[1];
      }

      if (_bowlingStats.isNotEmpty) {
        _currentBowler = _bowlingSquad.firstWhere((p) => p.id == _bowlingStats.last.playerId);
      } else if (_bowlingSquad.isNotEmpty) {
        _currentBowler = _bowlingSquad.first;
      }
    }
  }

  void setOpeningPlayers({
    required String strikerId,
    required String nonStrikerId,
    required String bowlerId,
  }) {
    _striker = _battingSquad.cast<Player?>().firstWhere(
      (p) => p?.id == strikerId,
      orElse: () => _battingSquad.isNotEmpty ? _battingSquad.first : null,
    );
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_striker == null && strikerId.isNotEmpty) {
      _striker = Player(
        id: strikerId,
        teamId: _battingTeam?.id ?? '',
        name: 'Striker',
        role: 'Batter',
        createdAt: now,
      );
      _battingSquad.add(_striker!);
    }

    _nonStriker = _battingSquad.cast<Player?>().firstWhere(
      (p) => p?.id == nonStrikerId,
      orElse: () => _battingSquad.length > 1 ? _battingSquad[1] : _striker,
    );
    if (_nonStriker == null && nonStrikerId.isNotEmpty) {
      _nonStriker = Player(
        id: nonStrikerId,
        teamId: _battingTeam?.id ?? '',
        name: 'Non-Striker',
        role: 'Batter',
        createdAt: now,
      );
      _battingSquad.add(_nonStriker!);
    }

    _currentBowler = _bowlingSquad.cast<Player?>().firstWhere(
      (p) => p?.id == bowlerId,
      orElse: () => _bowlingSquad.isNotEmpty ? _bowlingSquad.first : null,
    );
    if (_currentBowler == null && bowlerId.isNotEmpty) {
      _currentBowler = Player(
        id: bowlerId,
        teamId: _bowlingTeam?.id ?? '',
        name: 'Bowler',
        role: 'Bowler',
        createdAt: now,
      );
      _bowlingSquad.add(_currentBowler!);
    }

    if (_striker == null || _nonStriker == null || _currentBowler == null) {
      notifyListeners();
      return;
    }

    // Initialize batting stats for openers if not already present
    if (!_battingStats.any((s) => s.playerId == strikerId)) {
      final stat = BattingStat(
        id: _uuid.v4(),
        inningsId: _currentInnings!.id,
        playerId: _striker!.id,
        playerName: _striker!.name,
        battingOrder: 1,
      );
      _battingStats.add(stat);
      _scoringRepo.upsertBattingStat(stat);
    }

    if (!_battingStats.any((s) => s.playerId == nonStrikerId)) {
      final stat = BattingStat(
        id: _uuid.v4(),
        inningsId: _currentInnings!.id,
        playerId: _nonStriker!.id,
        playerName: _nonStriker!.name,
        battingOrder: 2,
      );
      _battingStats.add(stat);
      _scoringRepo.upsertBattingStat(stat);
    }

    // Initialize bowler stat if not present
    if (!_bowlingStats.any((s) => s.playerId == bowlerId)) {
      final bStat = BowlingStat(
        id: _uuid.v4(),
        inningsId: _currentInnings!.id,
        playerId: _currentBowler!.id,
        playerName: _currentBowler!.name,
        bowlingOrder: 1,
      );
      _bowlingStats.add(bStat);
      _scoringRepo.upsertBowlingStat(bStat);
    }

    // Initialize initial 1st wicket partnership
    if (_currentPartnership == null) {
      _currentPartnership = Partnership(
        id: _uuid.v4(),
        inningsId: _currentInnings!.id,
        wicketNumber: 1,
        batter1Id: _striker!.id,
        batter1Name: _striker!.name,
        batter2Id: _nonStriker!.id,
        batter2Name: _nonStriker!.name,
      );
      _scoringRepo.upsertPartnership(_currentPartnership!);
    }

    notifyListeners();
  }

  // --- SCORING ACTIONS ---
  Future<void> recordRuns(int runs) async {
    await recordBall(runsBat: runs);
  }

  Future<void> recordWide({int extraRuns = 1}) async {
    await recordBall(
      runsBat: 0,
      extraRuns: extraRuns,
      extraType: 'wide',
      isLegal: false,
    );
  }

  Future<void> recordNoBall({int batsmanRuns = 0, int extraRuns = 1}) async {
    await recordBall(
      runsBat: batsmanRuns,
      extraRuns: extraRuns,
      extraType: 'noball',
      isLegal: false,
    );
  }

  Future<void> recordBye(int runs) async {
    await recordBall(
      runsBat: 0,
      extraRuns: runs,
      extraType: 'bye',
      isLegal: true,
    );
  }

  Future<void> recordLegBye(int runs) async {
    await recordBall(
      runsBat: 0,
      extraRuns: runs,
      extraType: 'legbye',
      isLegal: true,
    );
  }

  Future<void> recordPenalty(int runs) async {
    await recordBall(
      runsBat: 0,
      extraRuns: runs,
      extraType: 'penalty',
      isLegal: false,
    );
  }

  Future<void> recordWicket({
    required String wicketType,
    required String dismissedPlayerId,
    String? fielderId,
    String? fielderName,
    required String newBatsmanId,
    int runsCompleted = 0,
  }) async {
    final newBatter = _battingSquad.firstWhere((p) => p.id == newBatsmanId);

    await recordBall(
      runsBat: runsCompleted,
      isLegal: wicketType.toLowerCase() != 'retired hurt' && wicketType.toLowerCase() != 'retired out',
      isWicket: true,
      wicketType: wicketType,
      dismissedPlayerId: dismissedPlayerId,
      fielderId: fielderId,
      fielderName: fielderName,
      newBatsman: newBatter,
    );
  }

  Future<void> recordBall({
    required int runsBat,
    int extraRuns = 0,
    String extraType = 'none',
    bool isLegal = true,
    bool isWicket = false,
    String? wicketType,
    String? dismissedPlayerId,
    String? fielderId,
    String? fielderName,
    Player? newBatsman,
  }) async {
    if (_currentInnings == null || _striker == null || _nonStriker == null || _currentBowler == null) {
      return;
    }

    // STRICT CHECK: Cannot bowl more than the match total overs, or if match/innings complete
    if (_isInningsComplete || _isMatchComplete || isCurrentInningsOversCompleted) {
      return;
    }
    if (_currentInnings!.totalWickets >= (_match?.wicketsPerInnings ?? 10)) {
      return;
    }

    final ballsPerOver = _match?.ballsPerOver ?? 6;
    final currentLegalBalls = _currentInnings!.totalLegalBalls;
    final overNum = currentLegalBalls ~/ ballsPerOver;
    final ballInOver = isLegal ? (currentLegalBalls % ballsPerOver) + 1 : 0;

    // Determine strike rotation
    // Runs that rotate strike: odd runs off bat, or odd byes/leg-byes
    bool rotatesStrike = false;
    if (runsBat % 2 != 0) rotatesStrike = true;
    if ((extraType == 'bye' || extraType == 'legbye') && extraRuns % 2 != 0) {
      rotatesStrike = true;
    }

    final totalBallRuns = runsBat + extraRuns;

    // Commentary
    final commentary = CommentaryGenerator.generateCommentary(
      bowlerName: _currentBowler!.name,
      batsmanName: _striker!.name,
      runs: runsBat,
      extraType: extraType,
      extraRuns: extraRuns,
      isWicket: isWicket,
      wicketType: wicketType,
      fielderName: fielderName,
    );

    // 1. New Ball Model
    final ball = Ball(
      id: _uuid.v4(),
      matchId: _match!.id,
      inningsId: _currentInnings!.id,
      overNumber: overNum,
      ballNumber: currentOverBalls.length + 1,
      legalBallNumber: ballInOver,
      bowlerId: _currentBowler!.id,
      batsmanId: _striker!.id,
      nonStrikerId: _nonStriker!.id,
      runsBat: runsBat,
      extras: extraRuns,
      extraType: extraType,
      isLegalBall: isLegal,
      isWicket: isWicket,
      wicketType: wicketType,
      dismissedPlayerId: dismissedPlayerId,
      fielderId: fielderId,
      commentary: commentary,
      strikeChanged: rotatesStrike,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    // 2. Updated Innings Model
    final newWides = _currentInnings!.wides + (extraType == 'wide' ? extraRuns : 0);
    final newNoBalls = _currentInnings!.noBalls + (extraType == 'noball' ? extraRuns : 0);
    final newByes = _currentInnings!.byes + (extraType == 'bye' ? extraRuns : 0);
    final newLegByes = _currentInnings!.legByes + (extraType == 'legbye' ? extraRuns : 0);
    final newPenalty = _currentInnings!.penaltyRuns + (extraType == 'penalty' ? extraRuns : 0);
    final newTotalRuns = _currentInnings!.totalRuns + totalBallRuns;
    final newWickets = _currentInnings!.totalWickets + (isWicket ? 1 : 0);
    final newLegalBalls = _currentInnings!.totalLegalBalls + (isLegal ? 1 : 0);

    final updatedInnings = _currentInnings!.copyWith(
      totalRuns: newTotalRuns,
      totalWickets: newWickets,
      totalLegalBalls: newLegalBalls,
      wides: newWides,
      noBalls: newNoBalls,
      byes: newByes,
      legByes: newLegByes,
      penaltyRuns: newPenalty,
    );

    // 3. Updated Striker Batting Stat
    BattingStat strikerS = strikerStat ??
        BattingStat(
          id: _uuid.v4(),
          inningsId: _currentInnings!.id,
          playerId: _striker!.id,
          playerName: _striker!.name,
          battingOrder: _battingStats.length + 1,
        );

    final isStrikerDismissed = isWicket && (dismissedPlayerId == _striker!.id || dismissedPlayerId == null);

    strikerS = strikerS.copyWith(
      runs: strikerS.runs + runsBat,
      balls: strikerS.balls + (isLegal || extraType == 'noball' ? 1 : 0),
      fours: strikerS.fours + (runsBat == 4 ? 1 : 0),
      sixes: strikerS.sixes + (runsBat == 6 ? 1 : 0),
      dots: strikerS.dots + (runsBat == 0 && isLegal ? 1 : 0),
      isOut: isStrikerDismissed ? true : strikerS.isOut,
      dismissalType: isStrikerDismissed ? wicketType : strikerS.dismissalType,
      bowlerName: isStrikerDismissed ? _currentBowler!.name : strikerS.bowlerName,
      fielderName: isStrikerDismissed ? fielderName : strikerS.fielderName,
    );

    // Update Non-Striker if run out
    BattingStat? nonStrikerS;
    if (isWicket && dismissedPlayerId == _nonStriker!.id) {
      nonStrikerS = nonStrikerStat?.copyWith(
        isOut: true,
        dismissalType: wicketType,
        fielderName: fielderName,
      );
    }

    // 4. Updated Bowler Bowling Stat
    BowlingStat bowlerS = currentBowlerStat ??
        BowlingStat(
          id: _uuid.v4(),
          inningsId: _currentInnings!.id,
          playerId: _currentBowler!.id,
          playerName: _currentBowler!.name,
          bowlingOrder: _bowlingStats.length + 1,
        );

    // Runs charged to bowler (runs off bat + wides + noballs)
    final bowlerRunsCharged = runsBat + (extraType == 'wide' || extraType == 'noball' ? extraRuns : 0);
    // Wickets credited to bowler (all except run out, retired hurt/out)
    final isBowlerWicket = isWicket &&
        wicketType != 'run out' &&
        wicketType != 'runout' &&
        wicketType != 'retired hurt' &&
        wicketType != 'retired out';

    bowlerS = bowlerS.copyWith(
      totalLegalBalls: bowlerS.totalLegalBalls + (isLegal ? 1 : 0),
      runsConceded: bowlerS.runsConceded + bowlerRunsCharged,
      wickets: bowlerS.wickets + (isBowlerWicket ? 1 : 0),
      wides: bowlerS.wides + (extraType == 'wide' ? extraRuns : 0),
      noBalls: bowlerS.noBalls + (extraType == 'noball' ? extraRuns : 0),
      dots: bowlerS.dots + (runsBat == 0 && extraRuns == 0 ? 1 : 0),
    );

    // 5. Updated Partnership
    Partnership? updatedPartnership;
    if (_currentPartnership != null) {
      final isStriker1 = _currentPartnership!.batter1Id == _striker!.id;
      updatedPartnership = _currentPartnership!.copyWith(
        batter1Runs: isStriker1
            ? _currentPartnership!.batter1Runs + runsBat
            : _currentPartnership!.batter1Runs,
        batter1Balls: isStriker1 && isLegal
            ? _currentPartnership!.batter1Balls + 1
            : _currentPartnership!.batter1Balls,
        batter2Runs: !isStriker1
            ? _currentPartnership!.batter2Runs + runsBat
            : _currentPartnership!.batter2Runs,
        batter2Balls: !isStriker1 && isLegal
            ? _currentPartnership!.batter2Balls + 1
            : _currentPartnership!.batter2Balls,
        totalRuns: _currentPartnership!.totalRuns + totalBallRuns,
        totalBalls: _currentPartnership!.totalBalls + (isLegal ? 1 : 0),
        isUnbroken: !isWicket,
      );
    }

    // 6. Fall of Wicket if wicket
    FallOfWicket? newFow;
    if (isWicket) {
      final dismissedName = (dismissedPlayerId == _nonStriker?.id) ? _nonStriker!.name : _striker!.name;
      final dismissedId = dismissedPlayerId ?? _striker!.id;

      newFow = FallOfWicket(
        id: _uuid.v4(),
        inningsId: _currentInnings!.id,
        wicketNumber: newWickets,
        score: newTotalRuns,
        totalLegalBalls: newLegalBalls,
        playerId: dismissedId,
        playerName: dismissedName,
      );
    }

    // ATOMIC DATABASE PERSISTENCE
    await _scoringRepo.saveBallTransaction(
      ball: ball,
      updatedInnings: updatedInnings,
      strikerStat: strikerS,
      nonStrikerStat: nonStrikerS,
      bowlerStat: bowlerS,
      currentPartnership: updatedPartnership,
      newFow: newFow,
    );

    // Local State Updates
    _allBalls.add(ball);
    _currentInnings = updatedInnings;

    // Update in-memory stats
    _updateInMemoryBattingStat(strikerS);
    if (nonStrikerS != null) _updateInMemoryBattingStat(nonStrikerS);
    _updateInMemoryBowlingStat(bowlerS);

    if (newFow != null) _fallOfWickets.add(newFow);
    _currentPartnership = updatedPartnership;

    // Rotate Strike if needed
    if (rotatesStrike) {
      final temp = _striker;
      _striker = _nonStriker;
      _nonStriker = temp;
    }

    // Handle Wicket: Bring in New Batsman
    if (isWicket && newBatsman != null) {
      if (dismissedPlayerId == _nonStriker?.id) {
        _nonStriker = newBatsman;
      } else {
        _striker = newBatsman;
      }

      // Add batting stat for new batsman
      final newBatStat = BattingStat(
        id: _uuid.v4(),
        inningsId: _currentInnings!.id,
        playerId: newBatsman.id,
        playerName: newBatsman.name,
        battingOrder: _battingStats.length + 1,
      );
      _battingStats.add(newBatStat);
      await _scoringRepo.upsertBattingStat(newBatStat);

      // Start new unbroken partnership
      _currentPartnership = Partnership(
        id: _uuid.v4(),
        inningsId: _currentInnings!.id,
        wicketNumber: newWickets + 1,
        batter1Id: _striker!.id,
        batter1Name: _striker!.name,
        batter2Id: _nonStriker!.id,
        batter2Name: _nonStriker!.name,
      );
      await _scoringRepo.upsertPartnership(_currentPartnership!);
    }

    // Check if over completed (6 legal balls in over)
    if (isLegal && (newLegalBalls % ballsPerOver == 0)) {
      _isOverComplete = true;
      _previousBowler = _currentBowler;
      // Strike rotates automatically at end of over
      final temp = _striker;
      _striker = _nonStriker;
      _nonStriker = temp;
    } else {
      _isOverComplete = false;
    }

    _checkInningsStatus();
    notifyListeners();
  }

  void _updateInMemoryBattingStat(BattingStat stat) {
    final idx = _battingStats.indexWhere((s) => s.playerId == stat.playerId);
    if (idx >= 0) {
      _battingStats[idx] = stat;
    } else {
      _battingStats.add(stat);
    }
  }

  void _updateInMemoryBowlingStat(BowlingStat stat) {
    final idx = _bowlingStats.indexWhere((s) => s.playerId == stat.playerId);
    if (idx >= 0) {
      _bowlingStats[idx] = stat;
    } else {
      _bowlingStats.add(stat);
    }
  }

  void swapStrike() {
    final temp = _striker;
    _striker = _nonStriker;
    _nonStriker = temp;
    notifyListeners();
  }

  Future<void> changeBowler(String newBowlerId) async {
    Player? bowler = _bowlingSquad.cast<Player?>().firstWhere(
      (p) => p?.id == newBowlerId,
      orElse: () => null,
    );
    if (bowler == null) {
      bowler = await _playerRepo.getPlayerById(newBowlerId);
      if (bowler != null && !_bowlingSquad.any((p) => p.id == bowler!.id)) {
        _bowlingSquad.add(bowler);
      }
    }
    if (bowler == null) return;

    _currentBowler = bowler;
    _isOverComplete = false;

    // Ensure bowling stat exists
    if (_currentInnings != null && !_bowlingStats.any((s) => s.playerId == newBowlerId)) {
      final bStat = BowlingStat(
        id: _uuid.v4(),
        inningsId: _currentInnings!.id,
        playerId: _currentBowler!.id,
        playerName: _currentBowler!.name,
        bowlingOrder: _bowlingStats.length + 1,
      );
      _bowlingStats.add(bStat);
      await _scoringRepo.upsertBowlingStat(bStat);
    }

    notifyListeners();
  }

  Future<void> changeStriker(String newStrikerId) async {
    Player? striker = _battingSquad.cast<Player?>().firstWhere(
      (p) => p?.id == newStrikerId,
      orElse: () => null,
    );
    if (striker == null) {
      striker = await _playerRepo.getPlayerById(newStrikerId);
      if (striker != null && !_battingSquad.any((p) => p.id == striker!.id)) {
        _battingSquad.add(striker);
      }
    }
    if (striker == null) return;
    _striker = striker;

    if (_currentInnings != null && !_battingStats.any((s) => s.playerId == newStrikerId)) {
      final stat = BattingStat(
        id: _uuid.v4(),
        inningsId: _currentInnings!.id,
        playerId: _striker!.id,
        playerName: _striker!.name,
        battingOrder: _battingStats.length + 1,
      );
      _battingStats.add(stat);
      await _scoringRepo.upsertBattingStat(stat);
    }

    await _ensurePartnership();

    notifyListeners();
  }

  Future<void> changeNonStriker(String newNonStrikerId) async {
    Player? nonStriker = _battingSquad.cast<Player?>().firstWhere(
      (p) => p?.id == newNonStrikerId,
      orElse: () => null,
    );
    if (nonStriker == null) {
      nonStriker = await _playerRepo.getPlayerById(newNonStrikerId);
      if (nonStriker != null && !_battingSquad.any((p) => p.id == nonStriker!.id)) {
        _battingSquad.add(nonStriker);
      }
    }
    if (nonStriker == null) return;
    _nonStriker = nonStriker;

    if (_currentInnings != null && !_battingStats.any((s) => s.playerId == newNonStrikerId)) {
      final stat = BattingStat(
        id: _uuid.v4(),
        inningsId: _currentInnings!.id,
        playerId: _nonStriker!.id,
        playerName: _nonStriker!.name,
        battingOrder: _battingStats.length + 1,
      );
      _battingStats.add(stat);
      await _scoringRepo.upsertBattingStat(stat);
    }

    await _ensurePartnership();

    notifyListeners();
  }

  Future<void> _ensurePartnership() async {
    if (_currentInnings == null || _striker == null || _nonStriker == null) return;

    if (_currentPartnership == null) {
      _currentPartnership = Partnership(
        id: _uuid.v4(),
        inningsId: _currentInnings!.id,
        wicketNumber: (_currentInnings?.totalWickets ?? 0) + 1,
        batter1Id: _striker!.id,
        batter1Name: _striker!.name,
        batter2Id: _nonStriker!.id,
        batter2Name: _nonStriker!.name,
      );
      await _scoringRepo.upsertPartnership(_currentPartnership!);
    } else if (_currentPartnership!.totalBalls == 0 && _currentPartnership!.totalRuns == 0) {
      _currentPartnership = _currentPartnership!.copyWith(
        batter1Id: _striker!.id,
        batter1Name: _striker!.name,
        batter2Id: _nonStriker!.id,
        batter2Name: _nonStriker!.name,
      );
      await _scoringRepo.upsertPartnership(_currentPartnership!);
    }
  }

  Future<Player> addNewPlayerToSquad({
    required String teamId,
    required String name,
    required String role,
    String bowlingStyle = 'Right-arm medium',
    int jerseyNumber = 0,
  }) async {
    final newPlayer = Player(
      id: _uuid.v4(),
      teamId: teamId,
      name: name.trim(),
      role: role,
      jerseyNumber: jerseyNumber,
      battingStyle: 'Right-hand bat',
      bowlingStyle: role == 'Bowler' || role == 'All Rounder' ? bowlingStyle : 'None',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _playerRepo.insertPlayer(newPlayer);

    if (_match != null) {
      final db = await DatabaseService.instance.database;
      await db.insert(DbTables.matchSquads, {
        'id': _uuid.v4(),
        'matchId': _match!.id,
        'teamId': teamId,
        'playerId': newPlayer.id,
        'isPlayingXi': 1,
        'isCaptain': 0,
        'isWicketKeeper': 0,
        'battingOrder': 0,
      });
    }

    if (teamId == _currentInnings?.battingTeamId || teamId == _battingTeam?.id) {
      if (!_battingSquad.any((p) => p.id == newPlayer.id)) {
        _battingSquad.add(newPlayer);
      }
    }
    if (teamId == _currentInnings?.bowlingTeamId || teamId == _bowlingTeam?.id) {
      if (!_bowlingSquad.any((p) => p.id == newPlayer.id)) {
        _bowlingSquad.add(newPlayer);
      }
    }
    notifyListeners();
    return newPlayer;
  }

  Future<void> recordRetiredHurt({
    required String dismissedPlayerId,
    required String newBatsmanId,
    bool isOut = false,
  }) async {
    final dismissalType = isOut ? 'retired out' : 'retired hurt';
    await recordWicket(
      wicketType: dismissalType,
      dismissedPlayerId: dismissedPlayerId,
      newBatsmanId: newBatsmanId,
    );
  }

  // --- UNDO SYSTEM ---
  Future<void> undoLastBall() async {
    if (_allBalls.isEmpty || _currentInnings == null) return;

    final lastBall = _allBalls.last;
    final ballsPerOver = _match?.ballsPerOver ?? 6;

    // 1. Revert Innings
    final revertedRuns = _currentInnings!.totalRuns - lastBall.totalRuns;
    final revertedWickets = _currentInnings!.totalWickets - (lastBall.isWicket ? 1 : 0);
    final revertedLegalBalls = _currentInnings!.totalLegalBalls - (lastBall.isLegalBall ? 1 : 0);

    final revertedWides = _currentInnings!.wides - (lastBall.extraType == 'wide' ? lastBall.extras : 0);
    final revertedNoBalls = _currentInnings!.noBalls - (lastBall.extraType == 'noball' ? lastBall.extras : 0);
    final revertedByes = _currentInnings!.byes - (lastBall.extraType == 'bye' ? lastBall.extras : 0);
    final revertedLegByes = _currentInnings!.legByes - (lastBall.extraType == 'legbye' ? lastBall.extras : 0);
    final revertedPenalty = _currentInnings!.penaltyRuns - (lastBall.extraType == 'penalty' ? lastBall.extras : 0);

    final revertedInnings = _currentInnings!.copyWith(
      totalRuns: revertedRuns >= 0 ? revertedRuns : 0,
      totalWickets: revertedWickets >= 0 ? revertedWickets : 0,
      totalLegalBalls: revertedLegalBalls >= 0 ? revertedLegalBalls : 0,
      wides: revertedWides >= 0 ? revertedWides : 0,
      noBalls: revertedNoBalls >= 0 ? revertedNoBalls : 0,
      byes: revertedByes >= 0 ? revertedByes : 0,
      legByes: revertedLegByes >= 0 ? revertedLegByes : 0,
      penaltyRuns: revertedPenalty >= 0 ? revertedPenalty : 0,
    );

    // 2. Revert Striker Stat
    final strikerBeforeBall = _battingSquad.firstWhere((p) => p.id == lastBall.batsmanId);
    final strikerS = _battingStats.firstWhere((s) => s.playerId == lastBall.batsmanId);

    final revertedStrikerS = strikerS.copyWith(
      runs: strikerS.runs - lastBall.runsBat >= 0 ? strikerS.runs - lastBall.runsBat : 0,
      balls: strikerS.balls - (lastBall.isLegalBall || lastBall.extraType == 'noball' ? 1 : 0) >= 0
          ? strikerS.balls - (lastBall.isLegalBall || lastBall.extraType == 'noball' ? 1 : 0)
          : 0,
      fours: lastBall.runsBat == 4 ? strikerS.fours - 1 : strikerS.fours,
      sixes: lastBall.runsBat == 6 ? strikerS.sixes - 1 : strikerS.sixes,
      dots: (lastBall.runsBat == 0 && lastBall.isLegalBall) ? strikerS.dots - 1 : strikerS.dots,
      isOut: lastBall.isWicket && (lastBall.dismissedPlayerId == lastBall.batsmanId || lastBall.dismissedPlayerId == null)
          ? false
          : strikerS.isOut,
      dismissalType: null,
      bowlerName: null,
      fielderName: null,
    );

    // 3. Revert Bowler Stat
    final bowlerS = _bowlingStats.firstWhere((s) => s.playerId == lastBall.bowlerId);
    final bowlerRuns = lastBall.runsBat + (lastBall.extraType == 'wide' || lastBall.extraType == 'noball' ? lastBall.extras : 0);
    final isBowlerWicket = lastBall.isWicket &&
        lastBall.wicketType != 'run out' &&
        lastBall.wicketType != 'runout' &&
        lastBall.wicketType != 'retired hurt' &&
        lastBall.wicketType != 'retired out';

    final revertedBowlerS = bowlerS.copyWith(
      totalLegalBalls: lastBall.isLegalBall ? bowlerS.totalLegalBalls - 1 : bowlerS.totalLegalBalls,
      runsConceded: bowlerS.runsConceded - bowlerRuns >= 0 ? bowlerS.runsConceded - bowlerRuns : 0,
      wickets: isBowlerWicket ? bowlerS.wickets - 1 : bowlerS.wickets,
      wides: lastBall.extraType == 'wide' ? bowlerS.wides - lastBall.extras : bowlerS.wides,
      noBalls: lastBall.extraType == 'noball' ? bowlerS.noBalls - lastBall.extras : bowlerS.noBalls,
      dots: (lastBall.runsBat == 0 && lastBall.extras == 0) ? bowlerS.dots - 1 : bowlerS.dots,
    );

    // 4. Fall of Wicket delete
    String? fowIdToDelete;
    if (lastBall.isWicket && _fallOfWickets.isNotEmpty) {
      fowIdToDelete = _fallOfWickets.last.id;
      _fallOfWickets.removeLast();
    }

    // Execute Undo Transaction
    await _scoringRepo.undoBallTransaction(
      ballId: lastBall.id,
      revertedInnings: revertedInnings,
      strikerStat: revertedStrikerS,
      bowlerStat: revertedBowlerS,
      fowIdToDelete: fowIdToDelete,
    );

    // Update in-memory state
    _allBalls.removeLast();
    _currentInnings = revertedInnings;
    _updateInMemoryBattingStat(revertedStrikerS);
    _updateInMemoryBowlingStat(revertedBowlerS);

    // Revert active striker, non-striker, bowler
    _striker = strikerBeforeBall;
    _nonStriker = _battingSquad.firstWhere((p) => p.id == lastBall.nonStrikerId);
    _currentBowler = _bowlingSquad.firstWhere((p) => p.id == lastBall.bowlerId);

    _isOverComplete = revertedLegalBalls > 0 && (revertedLegalBalls % ballsPerOver == 0);
    _isInningsComplete = false;
    _isMatchComplete = false;
    _checkInningsStatus();

    notifyListeners();
  }

  // --- INNINGS & MATCH TRANSITIONS ---
  void _checkInningsStatus() {
    if (_currentInnings == null || _match == null) return;

    final maxBalls = _match!.totalOvers * _match!.ballsPerOver;
    final maxWickets = _match!.wicketsPerInnings;

    // 1. Check if 2nd Innings Target reached
    if (_currentInnings!.inningsNumber == 2 && _currentInnings!.targetRuns != null) {
      if (_currentInnings!.totalRuns >= _currentInnings!.targetRuns!) {
        _isInningsComplete = true;
        _isMatchComplete = true;
        final wicketsRemaining = maxWickets - _currentInnings!.totalWickets;
        _matchResultSummary = '${_battingTeam?.name ?? 'Batting team'} won by $wicketsRemaining wicket${wicketsRemaining > 1 ? 's' : ''}';
        _completeMatch(winnerTeamId: _battingTeam?.id, summary: _matchResultSummary!);
        return;
      }
    }

    // 2. Check if all out or overs complete
    if (_currentInnings!.totalWickets >= maxWickets || _currentInnings!.totalLegalBalls >= maxBalls) {
      _isInningsComplete = true;
      _isOverComplete = false;

      if (_currentInnings!.inningsNumber == 1) {
        // 1st innings complete -> Ready for 2nd innings
        _isMatchComplete = false;
      } else {
        // 2nd innings complete -> Evaluate Match Result
        _isMatchComplete = true;
        final target = _currentInnings!.targetRuns ?? 0;
        if (_currentInnings!.totalRuns >= target) {
          final wicketsRemaining = maxWickets - _currentInnings!.totalWickets;
          _matchResultSummary = '${_battingTeam?.name ?? 'Batting team'} won by $wicketsRemaining wickets';
          _completeMatch(winnerTeamId: _battingTeam?.id, summary: _matchResultSummary!);
        } else if (_currentInnings!.totalRuns == target - 1) {
          _matchResultSummary = 'Match Tied!';
          _completeMatch(winnerTeamId: null, summary: _matchResultSummary!);
        } else {
          final runMargin = (target - 1) - _currentInnings!.totalRuns;
          _matchResultSummary = '${_bowlingTeam?.name ?? 'Bowling team'} won by $runMargin run${runMargin > 1 ? 's' : ''}';
          _completeMatch(winnerTeamId: _bowlingTeam?.id, summary: _matchResultSummary!);
        }
      }
    } else {
      if (!_isInningsComplete) {
        _isInningsComplete = false;
        _isMatchComplete = false;
      }
    }
  }

  Future<void> startSecondInnings({
    required String strikerId,
    required String nonStrikerId,
    required String bowlerId,
  }) async {
    if (_match == null || _currentInnings == null) return;
    // Guard against creating duplicate/extra innings beyond innings 2 in limited-overs matches
    if (_currentInnings!.inningsNumber >= 2) return;

    final target = _currentInnings!.totalRuns + 1;

    // Mark 1st innings complete
    final completed1stInnings = _currentInnings!.copyWith(isCompleted: true);
    await _scoringRepo.updateInnings(completed1stInnings);
    _firstInnings = completed1stInnings;

    // Create 2nd Innings
    final inn2 = Innings(
      id: _uuid.v4(),
      matchId: _match!.id,
      inningsNumber: 2,
      battingTeamId: completed1stInnings.bowlingTeamId,
      bowlingTeamId: completed1stInnings.battingTeamId,
      targetRuns: target,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _scoringRepo.insertInnings(inn2);
    _currentInnings = inn2;

    // Update match current innings
    final updatedMatch = _match!.copyWith(currentInningsNumber: 2);
    await _matchRepo.updateMatch(updatedMatch);
    _match = updatedMatch;

    // Swap teams & squads
    final tempTeam = _battingTeam;
    _battingTeam = _bowlingTeam;
    _bowlingTeam = tempTeam;

    final tempSquad = _battingSquad;
    _battingSquad = _bowlingSquad;
    _bowlingSquad = tempSquad;

    // If opening players are newly added to either team, ensure they exist in squads
    Player? s = _battingSquad.cast<Player?>().firstWhere((p) => p?.id == strikerId, orElse: () => null);
    if (s == null && strikerId.isNotEmpty) {
      s = await _playerRepo.getPlayerById(strikerId);
      if (s != null && !_battingSquad.any((p) => p.id == s!.id)) _battingSquad.add(s);
    }
    Player? ns = _battingSquad.cast<Player?>().firstWhere((p) => p?.id == nonStrikerId, orElse: () => null);
    if (ns == null && nonStrikerId.isNotEmpty) {
      ns = await _playerRepo.getPlayerById(nonStrikerId);
      if (ns != null && !_battingSquad.any((p) => p.id == ns!.id)) _battingSquad.add(ns);
    }
    Player? b = _bowlingSquad.cast<Player?>().firstWhere((p) => p?.id == bowlerId, orElse: () => null);
    if (b == null && bowlerId.isNotEmpty) {
      b = await _playerRepo.getPlayerById(bowlerId);
      if (b != null && !_bowlingSquad.any((p) => p.id == b!.id)) _bowlingSquad.add(b);
    }

    _allBalls.clear();
    _battingStats.clear();
    _bowlingStats.clear();
    _fallOfWickets.clear();
    _currentPartnership = null;
    _previousBowler = null;
    _isOverComplete = false;
    _isInningsComplete = false;
    _isMatchComplete = false;

    // Set initial players for 2nd innings
    setOpeningPlayers(
      strikerId: strikerId,
      nonStrikerId: nonStrikerId,
      bowlerId: bowlerId,
    );
  }

  Future<void> declareInnings() async {
    if (_currentInnings == null) return;
    _isInningsComplete = true;
    _isOverComplete = false;
    if (_currentInnings!.inningsNumber == 1) {
      _isMatchComplete = false;
    } else {
      _isMatchComplete = true;
      final target = _currentInnings!.targetRuns ?? (_firstInnings != null ? _firstInnings!.totalRuns + 1 : 0);
      final maxWickets = _match?.wicketsPerInnings ?? 10;
      if (_currentInnings!.totalRuns >= target) {
        final wicketsRemaining = maxWickets - _currentInnings!.totalWickets;
        _matchResultSummary = '${_battingTeam?.name ?? 'Batting team'} won by $wicketsRemaining wicket${wicketsRemaining > 1 ? 's' : ''}';
        await _completeMatch(winnerTeamId: _battingTeam?.id, summary: _matchResultSummary!);
      } else if (_currentInnings!.totalRuns == target - 1) {
        _matchResultSummary = 'Match Tied!';
        await _completeMatch(winnerTeamId: null, summary: _matchResultSummary!);
      } else {
        final runMargin = (target - 1) - _currentInnings!.totalRuns;
        _matchResultSummary = '${_bowlingTeam?.name ?? 'Bowling team'} won by $runMargin run${runMargin > 1 ? 's' : ''}';
        await _completeMatch(winnerTeamId: _bowlingTeam?.id, summary: _matchResultSummary!);
      }
    }
    notifyListeners();
  }

  Future<void> _completeMatch({required String? winnerTeamId, required String summary}) async {
    if (_match == null) return;
    final updatedMatch = _match!.copyWith(
      status: 'completed',
      winnerTeamId: winnerTeamId,
      resultSummary: summary,
    );
    await _matchRepo.updateMatch(updatedMatch);
    _match = updatedMatch;
  }
}
