import '../database/database_service.dart';
import '../database/db_tables.dart';

class LeaderboardBatter {
  final String playerId;
  final String playerName;
  final String teamName;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final int innings;
  final int highestScore;
  final double average;
  final double strikeRate;

  const LeaderboardBatter({
    required this.playerId,
    required this.playerName,
    required this.teamName,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
    required this.innings,
    required this.highestScore,
    required this.average,
    required this.strikeRate,
  });
}

class LeaderboardBowler {
  final String playerId;
  final String playerName;
  final String teamName;
  final int wickets;
  final int runsConceded;
  final int totalLegalBalls;
  final double economy;
  final double average;
  final String bestBowling;

  const LeaderboardBowler({
    required this.playerId,
    required this.playerName,
    required this.teamName,
    required this.wickets,
    required this.runsConceded,
    required this.totalLegalBalls,
    required this.economy,
    required this.average,
    required this.bestBowling,
  });
}

class StatisticsRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  Future<List<LeaderboardBatter>> getTopRunScorers({int limit = 10}) async {
    final db = await _dbService.database;
    final results = await db.rawQuery('''
      SELECT 
        bs.playerId,
        bs.playerName,
        IFNULL(t.shortName, 'TEAM') as teamName,
        SUM(bs.runs) as totalRuns,
        SUM(bs.balls) as totalBalls,
        SUM(bs.fours) as totalFours,
        SUM(bs.sixes) as totalSixes,
        COUNT(bs.id) as inningsCount,
        MAX(bs.runs) as highScore,
        SUM(CASE WHEN bs.isOut = 1 THEN 1 ELSE 0 END) as outs
      FROM ${DbTables.battingStats} bs
      LEFT JOIN ${DbTables.players} p ON bs.playerId = p.id
      LEFT JOIN ${DbTables.teams} t ON p.teamId = t.id
      GROUP BY bs.playerId, bs.playerName
      HAVING totalRuns > 0
      ORDER BY totalRuns DESC
      LIMIT ?
    ''', [limit]);

    return results.map((r) {
      final runs = (r['totalRuns'] as int?) ?? 0;
      final balls = (r['totalBalls'] as int?) ?? 0;
      final outs = (r['outs'] as int?) ?? 0;
      final avg = outs > 0 ? (runs / outs) : runs.toDouble();
      final sr = balls > 0 ? (runs / balls) * 100.0 : 0.0;

      return LeaderboardBatter(
        playerId: r['playerId'] as String,
        playerName: r['playerName'] as String,
        teamName: r['teamName'] as String,
        runs: runs,
        balls: balls,
        fours: (r['totalFours'] as int?) ?? 0,
        sixes: (r['totalSixes'] as int?) ?? 0,
        innings: (r['inningsCount'] as int?) ?? 0,
        highestScore: (r['highScore'] as int?) ?? 0,
        average: avg,
        strikeRate: sr,
      );
    }).toList();
  }

  Future<List<LeaderboardBowler>> getTopWicketTakers({int limit = 10}) async {
    final db = await _dbService.database;
    final results = await db.rawQuery('''
      SELECT 
        bw.playerId,
        bw.playerName,
        IFNULL(t.shortName, 'TEAM') as teamName,
        SUM(bw.wickets) as totalWickets,
        SUM(bw.runsConceded) as totalRunsConceded,
        SUM(bw.totalLegalBalls) as totalBalls
      FROM ${DbTables.bowlingStats} bw
      LEFT JOIN ${DbTables.players} p ON bw.playerId = p.id
      LEFT JOIN ${DbTables.teams} t ON p.teamId = t.id
      GROUP BY bw.playerId, bw.playerName
      HAVING totalWickets > 0 OR totalBalls > 0
      ORDER BY totalWickets DESC, totalRunsConceded ASC
      LIMIT ?
    ''', [limit]);

    return results.map((r) {
      final wickets = (r['totalWickets'] as int?) ?? 0;
      final runs = (r['totalRunsConceded'] as int?) ?? 0;
      final balls = (r['totalBalls'] as int?) ?? 0;
      final overs = balls > 0 ? balls / 6.0 : 0.0;
      final eco = overs > 0 ? runs / overs : 0.0;
      final avg = wickets > 0 ? runs / wickets : 0.0;

      return LeaderboardBowler(
        playerId: r['playerId'] as String,
        playerName: r['playerName'] as String,
        teamName: r['teamName'] as String,
        wickets: wickets,
        runsConceded: runs,
        totalLegalBalls: balls,
        economy: eco,
        average: avg,
        bestBowling: '$wickets/$runs',
      );
    }).toList();
  }
}
