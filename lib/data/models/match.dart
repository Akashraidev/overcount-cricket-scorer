class CricketMatch {
  final String id;
  final String? tournamentId;
  final String title;
  final String venue;
  final int matchDate;
  final String format; // 'T10', 'T20', 'ODI', 'Test', 'Custom'
  final int totalOvers;
  final int wicketsPerInnings;
  final int ballsPerOver;
  final String teamAId;
  final String teamBId;
  final String? tossWinnerTeamId;
  final String? tossDecision; // 'Bat', 'Bowl'
  final String status; // 'upcoming', 'live', 'completed', 'abandoned'
  final String? resultSummary;
  final String? winnerTeamId;
  final int currentInningsNumber;
  final int createdAt;

  const CricketMatch({
    required this.id,
    this.tournamentId,
    required this.title,
    required this.venue,
    required this.matchDate,
    required this.format,
    required this.totalOvers,
    this.wicketsPerInnings = 10,
    this.ballsPerOver = 6,
    required this.teamAId,
    required this.teamBId,
    this.tossWinnerTeamId,
    this.tossDecision,
    this.status = 'upcoming',
    this.resultSummary,
    this.winnerTeamId,
    this.currentInningsNumber = 1,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tournamentId': tournamentId,
      'title': title,
      'venue': venue,
      'matchDate': matchDate,
      'format': format,
      'totalOvers': totalOvers,
      'wicketsPerInnings': wicketsPerInnings,
      'ballsPerOver': ballsPerOver,
      'teamAId': teamAId,
      'teamBId': teamBId,
      'tossWinnerTeamId': tossWinnerTeamId,
      'tossDecision': tossDecision,
      'status': status,
      'resultSummary': resultSummary,
      'winnerTeamId': winnerTeamId,
      'currentInningsNumber': currentInningsNumber,
      'createdAt': createdAt,
    };
  }

  factory CricketMatch.fromMap(Map<String, dynamic> map) {
    return CricketMatch(
      id: map['id'] as String,
      tournamentId: map['tournamentId'] as String?,
      title: map['title'] as String? ?? 'Match',
      venue: map['venue'] as String? ?? '',
      matchDate: map['matchDate'] != null ? (map['matchDate'] as int) : 0,
      format: map['format'] as String? ?? 'T20',
      totalOvers: map['totalOvers'] != null ? (map['totalOvers'] as int) : 20,
      wicketsPerInnings: map['wicketsPerInnings'] != null ? (map['wicketsPerInnings'] as int) : 10,
      ballsPerOver: map['ballsPerOver'] != null ? (map['ballsPerOver'] as int) : 6,
      teamAId: map['teamAId'] as String,
      teamBId: map['teamBId'] as String,
      tossWinnerTeamId: map['tossWinnerTeamId'] as String?,
      tossDecision: map['tossDecision'] as String?,
      status: map['status'] as String? ?? 'upcoming',
      resultSummary: map['resultSummary'] as String?,
      winnerTeamId: map['winnerTeamId'] as String?,
      currentInningsNumber: map['currentInningsNumber'] != null ? (map['currentInningsNumber'] as int) : 1,
      createdAt: map['createdAt'] != null ? (map['createdAt'] as int) : 0,
    );
  }

  CricketMatch copyWith({
    String? id,
    String? tournamentId,
    String? title,
    String? venue,
    int? matchDate,
    String? format,
    int? totalOvers,
    int? wicketsPerInnings,
    int? ballsPerOver,
    String? teamAId,
    String? teamBId,
    String? tossWinnerTeamId,
    String? tossDecision,
    String? status,
    String? resultSummary,
    String? winnerTeamId,
    int? currentInningsNumber,
    int? createdAt,
  }) {
    return CricketMatch(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      title: title ?? this.title,
      venue: venue ?? this.venue,
      matchDate: matchDate ?? this.matchDate,
      format: format ?? this.format,
      totalOvers: totalOvers ?? this.totalOvers,
      wicketsPerInnings: wicketsPerInnings ?? this.wicketsPerInnings,
      ballsPerOver: ballsPerOver ?? this.ballsPerOver,
      teamAId: teamAId ?? this.teamAId,
      teamBId: teamBId ?? this.teamBId,
      tossWinnerTeamId: tossWinnerTeamId ?? this.tossWinnerTeamId,
      tossDecision: tossDecision ?? this.tossDecision,
      status: status ?? this.status,
      resultSummary: resultSummary ?? this.resultSummary,
      winnerTeamId: winnerTeamId ?? this.winnerTeamId,
      currentInningsNumber: currentInningsNumber ?? this.currentInningsNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
