import '../../core/utils/cricket_calc.dart';

class Innings {
  final String id;
  final String matchId;
  final int inningsNumber;
  final String battingTeamId;
  final String bowlingTeamId;
  final int totalRuns;
  final int totalWickets;
  final int totalLegalBalls;
  final int wides;
  final int noBalls;
  final int byes;
  final int legByes;
  final int penaltyRuns;
  final int? targetRuns;
  final bool isCompleted;
  final int createdAt;

  const Innings({
    required this.id,
    required this.matchId,
    required this.inningsNumber,
    required this.battingTeamId,
    required this.bowlingTeamId,
    this.totalRuns = 0,
    this.totalWickets = 0,
    this.totalLegalBalls = 0,
    this.wides = 0,
    this.noBalls = 0,
    this.byes = 0,
    this.legByes = 0,
    this.penaltyRuns = 0,
    this.targetRuns,
    this.isCompleted = false,
    required this.createdAt,
  });

  int get totalExtras => wides + noBalls + byes + legByes + penaltyRuns;

  String get oversDisplay => CricketCalc.ballsToOversString(totalLegalBalls);

  double get currentRunRate => CricketCalc.calculateCRR(totalRuns, totalLegalBalls);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'matchId': matchId,
      'inningsNumber': inningsNumber,
      'battingTeamId': battingTeamId,
      'bowlingTeamId': bowlingTeamId,
      'totalRuns': totalRuns,
      'totalWickets': totalWickets,
      'totalLegalBalls': totalLegalBalls,
      'wides': wides,
      'noBalls': noBalls,
      'byes': byes,
      'legByes': legByes,
      'penaltyRuns': penaltyRuns,
      'targetRuns': targetRuns,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt,
    };
  }

  factory Innings.fromMap(Map<String, dynamic> map) {
    return Innings(
      id: map['id'] as String,
      matchId: map['matchId'] as String,
      inningsNumber: map['inningsNumber'] != null ? (map['inningsNumber'] as int) : 1,
      battingTeamId: map['battingTeamId'] as String,
      bowlingTeamId: map['bowlingTeamId'] as String,
      totalRuns: map['totalRuns'] != null ? (map['totalRuns'] as int) : 0,
      totalWickets: map['totalWickets'] != null ? (map['totalWickets'] as int) : 0,
      totalLegalBalls: map['totalLegalBalls'] != null ? (map['totalLegalBalls'] as int) : 0,
      wides: map['wides'] != null ? (map['wides'] as int) : 0,
      noBalls: map['noBalls'] != null ? (map['noBalls'] as int) : 0,
      byes: map['byes'] != null ? (map['byes'] as int) : 0,
      legByes: map['legByes'] != null ? (map['legByes'] as int) : 0,
      penaltyRuns: map['penaltyRuns'] != null ? (map['penaltyRuns'] as int) : 0,
      targetRuns: map['targetRuns'] as int?,
      isCompleted: map['isCompleted'] == 1 || map['isCompleted'] == true,
      createdAt: map['createdAt'] != null ? (map['createdAt'] as int) : 0,
    );
  }

  Innings copyWith({
    String? id,
    String? matchId,
    int? inningsNumber,
    String? battingTeamId,
    String? bowlingTeamId,
    int? totalRuns,
    int? totalWickets,
    int? totalLegalBalls,
    int? wides,
    int? noBalls,
    int? byes,
    int? legByes,
    int? penaltyRuns,
    int? targetRuns,
    bool? isCompleted,
    int? createdAt,
  }) {
    return Innings(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      inningsNumber: inningsNumber ?? this.inningsNumber,
      battingTeamId: battingTeamId ?? this.battingTeamId,
      bowlingTeamId: bowlingTeamId ?? this.bowlingTeamId,
      totalRuns: totalRuns ?? this.totalRuns,
      totalWickets: totalWickets ?? this.totalWickets,
      totalLegalBalls: totalLegalBalls ?? this.totalLegalBalls,
      wides: wides ?? this.wides,
      noBalls: noBalls ?? this.noBalls,
      byes: byes ?? this.byes,
      legByes: legByes ?? this.legByes,
      penaltyRuns: penaltyRuns ?? this.penaltyRuns,
      targetRuns: targetRuns ?? this.targetRuns,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
