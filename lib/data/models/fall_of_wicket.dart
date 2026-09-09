import '../../core/utils/cricket_calc.dart';

class FallOfWicket {
  final String id;
  final String inningsId;
  final int wicketNumber;
  final int score;
  final int totalLegalBalls;
  final String playerId;
  final String playerName;

  const FallOfWicket({
    required this.id,
    required this.inningsId,
    required this.wicketNumber,
    required this.score,
    required this.totalLegalBalls,
    required this.playerId,
    required this.playerName,
  });

  String get overDisplay => CricketCalc.ballsToOversString(totalLegalBalls);

  String get display => '$wicketNumber-$score ($playerName, $overDisplay ov)';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inningsId': inningsId,
      'wicketNumber': wicketNumber,
      'score': score,
      'totalLegalBalls': totalLegalBalls,
      'playerId': playerId,
      'playerName': playerName,
    };
  }

  factory FallOfWicket.fromMap(Map<String, dynamic> map) {
    return FallOfWicket(
      id: map['id'] as String,
      inningsId: map['inningsId'] as String,
      wicketNumber: map['wicketNumber'] != null ? (map['wicketNumber'] as int) : 1,
      score: map['score'] != null ? (map['score'] as int) : 0,
      totalLegalBalls: map['totalLegalBalls'] != null ? (map['totalLegalBalls'] as int) : 0,
      playerId: map['playerId'] as String,
      playerName: map['playerName'] as String? ?? 'Player',
    );
  }
}
