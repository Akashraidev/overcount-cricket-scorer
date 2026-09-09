class Partnership {
  final String id;
  final String inningsId;
  final int wicketNumber; // 1 for 1st wicket, 2 for 2nd, etc.
  final String batter1Id;
  final String batter1Name;
  final int batter1Runs;
  final int batter1Balls;
  final String batter2Id;
  final String batter2Name;
  final int batter2Runs;
  final int batter2Balls;
  final int totalRuns;
  final int totalBalls;
  final bool isUnbroken;

  const Partnership({
    required this.id,
    required this.inningsId,
    required this.wicketNumber,
    required this.batter1Id,
    required this.batter1Name,
    this.batter1Runs = 0,
    this.batter1Balls = 0,
    required this.batter2Id,
    required this.batter2Name,
    this.batter2Runs = 0,
    this.batter2Balls = 0,
    this.totalRuns = 0,
    this.totalBalls = 0,
    this.isUnbroken = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inningsId': inningsId,
      'wicketNumber': wicketNumber,
      'batter1Id': batter1Id,
      'batter1Name': batter1Name,
      'batter1Runs': batter1Runs,
      'batter1Balls': batter1Balls,
      'batter2Id': batter2Id,
      'batter2Name': batter2Name,
      'batter2Runs': batter2Runs,
      'batter2Balls': batter2Balls,
      'totalRuns': totalRuns,
      'totalBalls': totalBalls,
      'isUnbroken': isUnbroken ? 1 : 0,
    };
  }

  factory Partnership.fromMap(Map<String, dynamic> map) {
    return Partnership(
      id: map['id'] as String,
      inningsId: map['inningsId'] as String,
      wicketNumber: map['wicketNumber'] != null ? (map['wicketNumber'] as int) : 1,
      batter1Id: map['batter1Id'] as String,
      batter1Name: map['batter1Name'] as String? ?? 'Batter 1',
      batter1Runs: map['batter1Runs'] != null ? (map['batter1Runs'] as int) : 0,
      batter1Balls: map['batter1Balls'] != null ? (map['batter1Balls'] as int) : 0,
      batter2Id: map['batter2Id'] as String,
      batter2Name: map['batter2Name'] as String? ?? 'Batter 2',
      batter2Runs: map['batter2Runs'] != null ? (map['batter2Runs'] as int) : 0,
      batter2Balls: map['batter2Balls'] != null ? (map['batter2Balls'] as int) : 0,
      totalRuns: map['totalRuns'] != null ? (map['totalRuns'] as int) : 0,
      totalBalls: map['totalBalls'] != null ? (map['totalBalls'] as int) : 0,
      isUnbroken: map['isUnbroken'] == 1 || map['isUnbroken'] == true,
    );
  }

  Partnership copyWith({
    String? id,
    String? inningsId,
    int? wicketNumber,
    String? batter1Id,
    String? batter1Name,
    int? batter1Runs,
    int? batter1Balls,
    String? batter2Id,
    String? batter2Name,
    int? batter2Runs,
    int? batter2Balls,
    int? totalRuns,
    int? totalBalls,
    bool? isUnbroken,
  }) {
    return Partnership(
      id: id ?? this.id,
      inningsId: inningsId ?? this.inningsId,
      wicketNumber: wicketNumber ?? this.wicketNumber,
      batter1Id: batter1Id ?? this.batter1Id,
      batter1Name: batter1Name ?? this.batter1Name,
      batter1Runs: batter1Runs ?? this.batter1Runs,
      batter1Balls: batter1Balls ?? this.batter1Balls,
      batter2Id: batter2Id ?? this.batter2Id,
      batter2Name: batter2Name ?? this.batter2Name,
      batter2Runs: batter2Runs ?? this.batter2Runs,
      batter2Balls: batter2Balls ?? this.batter2Balls,
      totalRuns: totalRuns ?? this.totalRuns,
      totalBalls: totalBalls ?? this.totalBalls,
      isUnbroken: isUnbroken ?? this.isUnbroken,
    );
  }
}
