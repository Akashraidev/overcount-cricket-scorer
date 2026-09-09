import '../../core/utils/cricket_calc.dart';

class BowlingStat {
  final String id;
  final String inningsId;
  final String playerId;
  final String playerName;
  final int totalLegalBalls;
  final int maidens;
  final int runsConceded;
  final int wickets;
  final int wides;
  final int noBalls;
  final int dots;
  final int bowlingOrder;

  const BowlingStat({
    required this.id,
    required this.inningsId,
    required this.playerId,
    required this.playerName,
    this.totalLegalBalls = 0,
    this.maidens = 0,
    this.runsConceded = 0,
    this.wickets = 0,
    this.wides = 0,
    this.noBalls = 0,
    this.dots = 0,
    this.bowlingOrder = 0,
  });

  String get oversDisplay => CricketCalc.ballsToOversString(totalLegalBalls);

  double get economy => CricketCalc.calculateEconomy(runsConceded, totalLegalBalls);

  String get figuresDisplay => '$wickets/$runsConceded ($oversDisplay)';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inningsId': inningsId,
      'playerId': playerId,
      'playerName': playerName,
      'totalLegalBalls': totalLegalBalls,
      'maidens': maidens,
      'runsConceded': runsConceded,
      'wickets': wickets,
      'wides': wides,
      'noBalls': noBalls,
      'dots': dots,
      'bowlingOrder': bowlingOrder,
    };
  }

  factory BowlingStat.fromMap(Map<String, dynamic> map) {
    return BowlingStat(
      id: map['id'] as String,
      inningsId: map['inningsId'] as String,
      playerId: map['playerId'] as String,
      playerName: map['playerName'] as String? ?? 'Bowler',
      totalLegalBalls: map['totalLegalBalls'] != null ? (map['totalLegalBalls'] as int) : 0,
      maidens: map['maidens'] != null ? (map['maidens'] as int) : 0,
      runsConceded: map['runsConceded'] != null ? (map['runsConceded'] as int) : 0,
      wickets: map['wickets'] != null ? (map['wickets'] as int) : 0,
      wides: map['wides'] != null ? (map['wides'] as int) : 0,
      noBalls: map['noBalls'] != null ? (map['noBalls'] as int) : 0,
      dots: map['dots'] != null ? (map['dots'] as int) : 0,
      bowlingOrder: map['bowlingOrder'] != null ? (map['bowlingOrder'] as int) : 0,
    );
  }

  BowlingStat copyWith({
    String? id,
    String? inningsId,
    String? playerId,
    String? playerName,
    int? totalLegalBalls,
    int? maidens,
    int? runsConceded,
    int? wickets,
    int? wides,
    int? noBalls,
    int? dots,
    int? bowlingOrder,
  }) {
    return BowlingStat(
      id: id ?? this.id,
      inningsId: inningsId ?? this.inningsId,
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      totalLegalBalls: totalLegalBalls ?? this.totalLegalBalls,
      maidens: maidens ?? this.maidens,
      runsConceded: runsConceded ?? this.runsConceded,
      wickets: wickets ?? this.wickets,
      wides: wides ?? this.wides,
      noBalls: noBalls ?? this.noBalls,
      dots: dots ?? this.dots,
      bowlingOrder: bowlingOrder ?? this.bowlingOrder,
    );
  }
}
