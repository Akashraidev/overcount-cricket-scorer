import 'ball.dart';
import 'batting_stat.dart';
import 'bowling_stat.dart';
import 'fall_of_wicket.dart';
import 'innings.dart';
import 'match.dart';
import 'partnership.dart';
import 'player.dart';
import 'team.dart';

enum LocalSyncRole { none, host, viewer }

enum ViewerConnectionStatus { disconnected, connecting, connected, reconnecting, rejected }

class ViewerDevice {
  final String id;
  final String ip;
  final String deviceName;
  final int connectedAt;

  const ViewerDevice({
    required this.id,
    required this.ip,
    required this.deviceName,
    required this.connectedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ip': ip,
      'deviceName': deviceName,
      'connectedAt': connectedAt,
    };
  }

  factory ViewerDevice.fromMap(Map<String, dynamic> map) {
    return ViewerDevice(
      id: map['id']?.toString() ?? '',
      ip: map['ip']?.toString() ?? '',
      deviceName: map['deviceName']?.toString() ?? 'Viewer Phone',
      connectedAt: (map['connectedAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}

class DiscoveredMatchBeacon {
  final String pin;
  final String hostIp;
  final int port;
  final String matchTitle;
  final String? battingTeamName;
  final String? bowlingTeamName;
  final int scoreRuns;
  final int scoreWickets;
  final String oversDisplay;
  final int timestamp;

  const DiscoveredMatchBeacon({
    required this.pin,
    required this.hostIp,
    required this.port,
    required this.matchTitle,
    this.battingTeamName,
    this.bowlingTeamName,
    this.scoreRuns = 0,
    this.scoreWickets = 0,
    this.oversDisplay = '0.0',
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'pin': pin,
      'hostIp': hostIp,
      'port': port,
      'matchTitle': matchTitle,
      'battingTeamName': battingTeamName,
      'bowlingTeamName': bowlingTeamName,
      'scoreRuns': scoreRuns,
      'scoreWickets': scoreWickets,
      'oversDisplay': oversDisplay,
      'timestamp': timestamp,
    };
  }

  factory DiscoveredMatchBeacon.fromMap(Map<String, dynamic> map) {
    return DiscoveredMatchBeacon(
      pin: map['pin']?.toString() ?? '',
      hostIp: map['hostIp']?.toString() ?? '',
      port: (map['port'] as num?)?.toInt() ?? 40404,
      matchTitle: map['matchTitle']?.toString() ?? 'Live Cricket Match',
      battingTeamName: map['battingTeamName']?.toString(),
      bowlingTeamName: map['bowlingTeamName']?.toString(),
      scoreRuns: (map['scoreRuns'] as num?)?.toInt() ?? 0,
      scoreWickets: (map['scoreWickets'] as num?)?.toInt() ?? 0,
      oversDisplay: map['oversDisplay']?.toString() ?? '0.0',
      timestamp: (map['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}

class LiveMatchSnapshot {
  final CricketMatch match;
  final Innings currentInnings;
  final Innings? firstInnings;
  final Team battingTeam;
  final Team bowlingTeam;
  final Player? striker;
  final Player? nonStriker;
  final Player? currentBowler;
  final List<Player> battingSquad;
  final List<Player> bowlingSquad;
  final List<BattingStat> battingStats;
  final List<BowlingStat> bowlingStats;
  final List<Ball> recentBalls;
  final Partnership? currentPartnership;
  final List<FallOfWicket> fallOfWickets;
  final bool isOverComplete;
  final bool isInningsComplete;
  final bool isMatchComplete;
  final String? matchResultSummary;
  final int timestamp;

  const LiveMatchSnapshot({
    required this.match,
    required this.currentInnings,
    this.firstInnings,
    required this.battingTeam,
    required this.bowlingTeam,
    this.striker,
    this.nonStriker,
    this.currentBowler,
    this.battingSquad = const [],
    this.bowlingSquad = const [],
    this.battingStats = const [],
    this.bowlingStats = const [],
    this.recentBalls = const [],
    this.currentPartnership,
    this.fallOfWickets = const [],
    this.isOverComplete = false,
    this.isInningsComplete = false,
    this.isMatchComplete = false,
    this.matchResultSummary,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'match': match.toMap(),
      'currentInnings': currentInnings.toMap(),
      'firstInnings': firstInnings?.toMap(),
      'battingTeam': battingTeam.toMap(),
      'bowlingTeam': bowlingTeam.toMap(),
      'striker': striker?.toMap(),
      'nonStriker': nonStriker?.toMap(),
      'currentBowler': currentBowler?.toMap(),
      'battingSquad': battingSquad.map((p) => p.toMap()).toList(),
      'bowlingSquad': bowlingSquad.map((p) => p.toMap()).toList(),
      'battingStats': battingStats.map((s) => s.toMap()).toList(),
      'bowlingStats': bowlingStats.map((s) => s.toMap()).toList(),
      'recentBalls': recentBalls.map((b) => b.toMap()).toList(),
      'currentPartnership': currentPartnership?.toMap(),
      'fallOfWickets': fallOfWickets.map((w) => w.toMap()).toList(),
      'isOverComplete': isOverComplete,
      'isInningsComplete': isInningsComplete,
      'isMatchComplete': isMatchComplete,
      'matchResultSummary': matchResultSummary,
      'timestamp': timestamp,
    };
  }

  factory LiveMatchSnapshot.fromMap(Map<String, dynamic> map) {
    return LiveMatchSnapshot(
      match: CricketMatch.fromMap(Map<String, dynamic>.from(map['match'] as Map)),
      currentInnings: Innings.fromMap(Map<String, dynamic>.from(map['currentInnings'] as Map)),
      firstInnings: map['firstInnings'] != null
          ? Innings.fromMap(Map<String, dynamic>.from(map['firstInnings'] as Map))
          : null,
      battingTeam: Team.fromMap(Map<String, dynamic>.from(map['battingTeam'] as Map)),
      bowlingTeam: Team.fromMap(Map<String, dynamic>.from(map['bowlingTeam'] as Map)),
      striker: map['striker'] != null
          ? Player.fromMap(Map<String, dynamic>.from(map['striker'] as Map))
          : null,
      nonStriker: map['nonStriker'] != null
          ? Player.fromMap(Map<String, dynamic>.from(map['nonStriker'] as Map))
          : null,
      currentBowler: map['currentBowler'] != null
          ? Player.fromMap(Map<String, dynamic>.from(map['currentBowler'] as Map))
          : null,
      battingSquad: (map['battingSquad'] as List? ?? [])
          .map((p) => Player.fromMap(Map<String, dynamic>.from(p as Map)))
          .toList(),
      bowlingSquad: (map['bowlingSquad'] as List? ?? [])
          .map((p) => Player.fromMap(Map<String, dynamic>.from(p as Map)))
          .toList(),
      battingStats: (map['battingStats'] as List? ?? [])
          .map((s) => BattingStat.fromMap(Map<String, dynamic>.from(s as Map)))
          .toList(),
      bowlingStats: (map['bowlingStats'] as List? ?? [])
          .map((s) => BowlingStat.fromMap(Map<String, dynamic>.from(s as Map)))
          .toList(),
      recentBalls: (map['recentBalls'] as List? ?? [])
          .map((b) => Ball.fromMap(Map<String, dynamic>.from(b as Map)))
          .toList(),
      currentPartnership: map['currentPartnership'] != null
          ? Partnership.fromMap(Map<String, dynamic>.from(map['currentPartnership'] as Map))
          : null,
      fallOfWickets: (map['fallOfWickets'] as List? ?? [])
          .map((w) => FallOfWicket.fromMap(Map<String, dynamic>.from(w as Map)))
          .toList(),
      isOverComplete: map['isOverComplete'] as bool? ?? false,
      isInningsComplete: map['isInningsComplete'] as bool? ?? false,
      isMatchComplete: map['isMatchComplete'] as bool? ?? false,
      matchResultSummary: map['matchResultSummary']?.toString(),
      timestamp: (map['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}
