class Ball {
  final String id;
  final String matchId;
  final String inningsId;
  final int overNumber; // 0-based over index (0, 1, 2...)
  final int ballNumber; // 1-based ball index in over (including illegal balls)
  final int legalBallNumber; // 1-6 for legal balls, 0 for wides/noballs
  final String bowlerId;
  final String batsmanId; // Striker
  final String nonStrikerId;
  final int runsBat; // Runs scored from the bat (0..6)
  final int extras; // Extra runs (0..5)
  final String extraType; // 'none', 'wide', 'noball', 'bye', 'legbye', 'penalty'
  final bool isLegalBall;
  final bool isWicket;
  final String? wicketType; // 'bowled', 'caught', 'lbw', 'runout', 'stumped', 'hitwicket', 'retiredhurt', 'retiredout'
  final String? dismissedPlayerId;
  final String? fielderId;
  final String commentary;
  final bool strikeChanged;
  final int timestamp;

  const Ball({
    required this.id,
    required this.matchId,
    required this.inningsId,
    required this.overNumber,
    required this.ballNumber,
    this.legalBallNumber = 0,
    required this.bowlerId,
    required this.batsmanId,
    required this.nonStrikerId,
    this.runsBat = 0,
    this.extras = 0,
    this.extraType = 'none',
    this.isLegalBall = true,
    this.isWicket = false,
    this.wicketType,
    this.dismissedPlayerId,
    this.fielderId,
    this.commentary = '',
    this.strikeChanged = false,
    required this.timestamp,
  });

  int get totalRuns => runsBat + extras;

  String get overDisplay => isLegalBall ? '$overNumber.$legalBallNumber' : '$overNumber.$legalBallNumber (Extra)';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'matchId': matchId,
      'inningsId': inningsId,
      'overNumber': overNumber,
      'ballNumber': ballNumber,
      'legalBallNumber': legalBallNumber,
      'bowlerId': bowlerId,
      'batsmanId': batsmanId,
      'nonStrikerId': nonStrikerId,
      'runsBat': runsBat,
      'extras': extras,
      'extraType': extraType,
      'isLegalBall': isLegalBall ? 1 : 0,
      'isWicket': isWicket ? 1 : 0,
      'wicketType': wicketType,
      'dismissedPlayerId': dismissedPlayerId,
      'fielderId': fielderId,
      'commentary': commentary,
      'strikeChanged': strikeChanged ? 1 : 0,
      'timestamp': timestamp,
    };
  }

  factory Ball.fromMap(Map<String, dynamic> map) {
    return Ball(
      id: map['id'] as String,
      matchId: map['matchId'] as String,
      inningsId: map['inningsId'] as String,
      overNumber: map['overNumber'] != null ? (map['overNumber'] as int) : 0,
      ballNumber: map['ballNumber'] != null ? (map['ballNumber'] as int) : 1,
      legalBallNumber: map['legalBallNumber'] != null ? (map['legalBallNumber'] as int) : 0,
      bowlerId: map['bowlerId'] as String,
      batsmanId: map['batsmanId'] as String,
      nonStrikerId: map['nonStrikerId'] as String,
      runsBat: map['runsBat'] != null ? (map['runsBat'] as int) : 0,
      extras: map['extras'] != null ? (map['extras'] as int) : 0,
      extraType: map['extraType'] as String? ?? 'none',
      isLegalBall: map['isLegalBall'] == 1 || map['isLegalBall'] == true,
      isWicket: map['isWicket'] == 1 || map['isWicket'] == true,
      wicketType: map['wicketType'] as String?,
      dismissedPlayerId: map['dismissedPlayerId'] as String?,
      fielderId: map['fielderId'] as String?,
      commentary: map['commentary'] as String? ?? '',
      strikeChanged: map['strikeChanged'] == 1 || map['strikeChanged'] == true,
      timestamp: map['timestamp'] != null ? (map['timestamp'] as int) : 0,
    );
  }

  Ball copyWith({
    String? id,
    String? matchId,
    String? inningsId,
    int? overNumber,
    int? ballNumber,
    int? legalBallNumber,
    String? bowlerId,
    String? batsmanId,
    String? nonStrikerId,
    int? runsBat,
    int? extras,
    String? extraType,
    bool? isLegalBall,
    bool? isWicket,
    String? wicketType,
    String? dismissedPlayerId,
    String? fielderId,
    String? commentary,
    bool? strikeChanged,
    int? timestamp,
  }) {
    return Ball(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      inningsId: inningsId ?? this.inningsId,
      overNumber: overNumber ?? this.overNumber,
      ballNumber: ballNumber ?? this.ballNumber,
      legalBallNumber: legalBallNumber ?? this.legalBallNumber,
      bowlerId: bowlerId ?? this.bowlerId,
      batsmanId: batsmanId ?? this.batsmanId,
      nonStrikerId: nonStrikerId ?? this.nonStrikerId,
      runsBat: runsBat ?? this.runsBat,
      extras: extras ?? this.extras,
      extraType: extraType ?? this.extraType,
      isLegalBall: isLegalBall ?? this.isLegalBall,
      isWicket: isWicket ?? this.isWicket,
      wicketType: wicketType ?? this.wicketType,
      dismissedPlayerId: dismissedPlayerId ?? this.dismissedPlayerId,
      fielderId: fielderId ?? this.fielderId,
      commentary: commentary ?? this.commentary,
      strikeChanged: strikeChanged ?? this.strikeChanged,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
