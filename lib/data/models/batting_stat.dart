import '../../core/utils/cricket_calc.dart';

class BattingStat {
  final String id;
  final String inningsId;
  final String playerId;
  final String playerName;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final int dots;
  final bool isOut;
  final String? dismissalType; // 'bowled', 'caught', 'lbw', 'run out', etc.
  final String? bowlerId;
  final String? bowlerName;
  final String? fielderId;
  final String? fielderName;
  final int battingOrder;

  const BattingStat({
    required this.id,
    required this.inningsId,
    required this.playerId,
    required this.playerName,
    this.runs = 0,
    this.balls = 0,
    this.fours = 0,
    this.sixes = 0,
    this.dots = 0,
    this.isOut = false,
    this.dismissalType,
    this.bowlerId,
    this.bowlerName,
    this.fielderId,
    this.fielderName,
    this.battingOrder = 0,
  });

  double get strikeRate => CricketCalc.calculateStrikeRate(runs, balls);

  String get dismissalSummary {
    if (!isOut) return 'not out';
    switch (dismissalType?.toLowerCase()) {
      case 'bowled':
        return 'b $bowlerName';
      case 'caught':
        if (fielderName != null && fielderName!.isNotEmpty) {
          if (fielderName == bowlerName) return 'c & b $bowlerName';
          return 'c $fielderName b $bowlerName';
        }
        return 'c sub b $bowlerName';
      case 'lbw':
        return 'lbw b $bowlerName';
      case 'run out':
      case 'runout':
        return (fielderName != null && fielderName!.isNotEmpty) ? 'run out ($fielderName)' : 'run out';
      case 'stumped':
        return (fielderName != null && fielderName!.isNotEmpty) ? 'st $fielderName b $bowlerName' : 'st b $bowlerName';
      case 'hit wicket':
      case 'hitwicket':
        return 'hit wicket b $bowlerName';
      case 'retired hurt':
        return 'retired hurt';
      case 'retired out':
        return 'retired out';
      default:
        return dismissalType ?? 'out';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inningsId': inningsId,
      'playerId': playerId,
      'playerName': playerName,
      'runs': runs,
      'balls': balls,
      'fours': fours,
      'sixes': sixes,
      'dots': dots,
      'isOut': isOut ? 1 : 0,
      'dismissalType': dismissalType,
      'bowlerId': bowlerId,
      'bowlerName': bowlerName,
      'fielderId': fielderId,
      'fielderName': fielderName,
      'battingOrder': battingOrder,
    };
  }

  factory BattingStat.fromMap(Map<String, dynamic> map) {
    return BattingStat(
      id: map['id'] as String,
      inningsId: map['inningsId'] as String,
      playerId: map['playerId'] as String,
      playerName: map['playerName'] as String? ?? 'Player',
      runs: map['runs'] != null ? (map['runs'] as int) : 0,
      balls: map['balls'] != null ? (map['balls'] as int) : 0,
      fours: map['fours'] != null ? (map['fours'] as int) : 0,
      sixes: map['sixes'] != null ? (map['sixes'] as int) : 0,
      dots: map['dots'] != null ? (map['dots'] as int) : 0,
      isOut: map['isOut'] == 1 || map['isOut'] == true,
      dismissalType: map['dismissalType'] as String?,
      bowlerId: map['bowlerId'] as String?,
      bowlerName: map['bowlerName'] as String?,
      fielderId: map['fielderId'] as String?,
      fielderName: map['fielderName'] as String?,
      battingOrder: map['battingOrder'] != null ? (map['battingOrder'] as int) : 0,
    );
  }

  BattingStat copyWith({
    String? id,
    String? inningsId,
    String? playerId,
    String? playerName,
    int? runs,
    int? balls,
    int? fours,
    int? sixes,
    int? dots,
    bool? isOut,
    String? dismissalType,
    String? bowlerId,
    String? bowlerName,
    String? fielderId,
    String? fielderName,
    int? battingOrder,
  }) {
    return BattingStat(
      id: id ?? this.id,
      inningsId: inningsId ?? this.inningsId,
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      runs: runs ?? this.runs,
      balls: balls ?? this.balls,
      fours: fours ?? this.fours,
      sixes: sixes ?? this.sixes,
      dots: dots ?? this.dots,
      isOut: isOut ?? this.isOut,
      dismissalType: dismissalType ?? this.dismissalType,
      bowlerId: bowlerId ?? this.bowlerId,
      bowlerName: bowlerName ?? this.bowlerName,
      fielderId: fielderId ?? this.fielderId,
      fielderName: fielderName ?? this.fielderName,
      battingOrder: battingOrder ?? this.battingOrder,
    );
  }
}
