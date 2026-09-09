import '../../core/utils/cricket_calc.dart';

class Tournament {
  final String id;
  final String name;
  final String format; // 'T10', 'T20', 'ODI', 'Test', 'Custom'
  final int startDate;
  final int? endDate;
  final String status; // 'upcoming', 'active', 'completed'
  final int createdAt;

  const Tournament({
    required this.id,
    required this.name,
    required this.format,
    required this.startDate,
    this.endDate,
    this.status = 'active',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'format': format,
      'startDate': startDate,
      'endDate': endDate,
      'status': status,
      'createdAt': createdAt,
    };
  }

  factory Tournament.fromMap(Map<String, dynamic> map) {
    return Tournament(
      id: map['id'] as String,
      name: map['name'] as String,
      format: map['format'] as String? ?? 'T20',
      startDate: map['startDate'] != null ? (map['startDate'] as int) : 0,
      endDate: map['endDate'] as int?,
      status: map['status'] as String? ?? 'active',
      createdAt: map['createdAt'] != null ? (map['createdAt'] as int) : 0,
    );
  }

  Tournament copyWith({
    String? id,
    String? name,
    String? format,
    int? startDate,
    int? endDate,
    String? status,
    int? createdAt,
  }) {
    return Tournament(
      id: id ?? this.id,
      name: name ?? this.name,
      format: format ?? this.format,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class TournamentStanding {
  final String teamId;
  final String teamName;
  final String teamShortName;
  final int colorValue;
  int matchesPlayed;
  int won;
  int lost;
  int tied;
  int points;
  int runsScored;
  int ballsFaced;
  int runsConceded;
  int ballsBowled;

  TournamentStanding({
    required this.teamId,
    required this.teamName,
    required this.teamShortName,
    this.colorValue = 0xFF0F9D58,
    this.matchesPlayed = 0,
    this.won = 0,
    this.lost = 0,
    this.tied = 0,
    this.points = 0,
    this.runsScored = 0,
    this.ballsFaced = 0,
    this.runsConceded = 0,
    this.ballsBowled = 0,
  });

  double get netRunRate => CricketCalc.calculateNRR(
        runsScored: runsScored,
        ballsFaced: ballsFaced,
        runsConceded: runsConceded,
        ballsBowled: ballsBowled,
      );

  String get formattedNRR => CricketCalc.formatNRR(netRunRate);
}
