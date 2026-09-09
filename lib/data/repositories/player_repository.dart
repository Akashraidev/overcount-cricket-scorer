import 'package:sqflite/sqflite.dart';
import '../database/database_service.dart';
import '../database/db_tables.dart';
import '../models/player.dart';

class PlayerCareerStats {
  final int matches;
  final int innings;
  final int runs;
  final int highestScore;
  final int notOuts;
  final int ballsFaced;
  final int fours;
  final int sixes;
  final int fifties;
  final int hundreds;
  final int wickets;
  final int runsConceded;
  final int totalLegalBallsBowled;
  final String bestBowling;

  const PlayerCareerStats({
    this.matches = 0,
    this.innings = 0,
    this.runs = 0,
    this.highestScore = 0,
    this.notOuts = 0,
    this.ballsFaced = 0,
    this.fours = 0,
    this.sixes = 0,
    this.fifties = 0,
    this.hundreds = 0,
    this.wickets = 0,
    this.runsConceded = 0,
    this.totalLegalBallsBowled = 0,
    this.bestBowling = '-',
  });

  double get battingAverage {
    final dismissedTimes = innings - notOuts;
    if (dismissedTimes <= 0) return runs.toDouble();
    return runs / dismissedTimes;
  }

  double get strikeRate {
    if (ballsFaced <= 0) return 0.0;
    return (runs / ballsFaced) * 100.0;
  }

  double get bowlingAverage {
    if (wickets <= 0) return 0.0;
    return runsConceded / wickets;
  }

  double get bowlingEconomy {
    if (totalLegalBallsBowled <= 0) return 0.0;
    final overs = totalLegalBallsBowled / 6.0;
    return runsConceded / overs;
  }
}

class PlayerRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  Future<List<Player>> getAllPlayers() async {
    final db = await _dbService.database;
    final maps = await db.query(DbTables.players, orderBy: 'name ASC');
    return maps.map((m) => Player.fromMap(m)).toList();
  }

  Future<Player?> getPlayerById(String id) async {
    final db = await _dbService.database;
    final maps = await db.query(
      DbTables.players,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Player.fromMap(maps.first);
  }

  Future<List<Player>> getPlayersByTeam(String teamId) async {
    final db = await _dbService.database;
    final maps = await db.query(
      DbTables.players,
      where: 'teamId = ?',
      whereArgs: [teamId],
      orderBy: 'isCaptain DESC, isWicketKeeper DESC, name ASC',
    );
    return maps.map((m) => Player.fromMap(m)).toList();
  }

  Future<int> insertPlayer(Player player) async {
    final db = await _dbService.database;
    return await db.insert(
      DbTables.players,
      player.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updatePlayer(Player player) async {
    final db = await _dbService.database;
    return await db.update(
      DbTables.players,
      player.toMap(),
      where: 'id = ?',
      whereArgs: [player.id],
    );
  }

  Future<int> deletePlayer(String id) async {
    final db = await _dbService.database;
    return await db.delete(
      DbTables.players,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<PlayerCareerStats> getPlayerCareerStats(String playerId) async {
    final db = await _dbService.database;

    // Batting stats aggregation
    final batMaps = await db.query(
      DbTables.battingStats,
      where: 'playerId = ?',
      whereArgs: [playerId],
    );

    int inningsCount = batMaps.length;
    int totalRuns = 0;
    int highestScore = 0;
    int notOuts = 0;
    int ballsFaced = 0;
    int fours = 0;
    int sixes = 0;
    int fifties = 0;
    int hundreds = 0;

    for (final m in batMaps) {
      final r = (m['runs'] as int?) ?? 0;
      final b = (m['balls'] as int?) ?? 0;
      final f = (m['fours'] as int?) ?? 0;
      final s = (m['sixes'] as int?) ?? 0;
      final isOut = (m['isOut'] == 1);

      totalRuns += r;
      ballsFaced += b;
      fours += f;
      sixes += s;
      if (!isOut) notOuts++;
      if (r > highestScore) highestScore = r;
      if (r >= 100) {
        hundreds++;
      } else if (r >= 50) {
        fifties++;
      }
    }

    // Bowling stats aggregation
    final bowlMaps = await db.query(
      DbTables.bowlingStats,
      where: 'playerId = ?',
      whereArgs: [playerId],
    );

    int totalWickets = 0;
    int runsConceded = 0;
    int ballsBowled = 0;
    int bestWickets = 0;
    int bestRuns = 999;

    for (final m in bowlMaps) {
      final w = (m['wickets'] as int?) ?? 0;
      final rc = (m['runsConceded'] as int?) ?? 0;
      final b = (m['totalLegalBalls'] as int?) ?? 0;

      totalWickets += w;
      runsConceded += rc;
      ballsBowled += b;

      if (w > bestWickets || (w == bestWickets && rc < bestRuns && w > 0)) {
        bestWickets = w;
        bestRuns = rc;
      }
    }

    final bestBowlingStr = bestWickets > 0 ? '$bestWickets/$bestRuns' : '-';

    return PlayerCareerStats(
      matches: inningsCount > 0 ? inningsCount : (bowlMaps.isNotEmpty ? bowlMaps.length : 0),
      innings: inningsCount,
      runs: totalRuns,
      highestScore: highestScore,
      notOuts: notOuts,
      ballsFaced: ballsFaced,
      fours: fours,
      sixes: sixes,
      fifties: fifties,
      hundreds: hundreds,
      wickets: totalWickets,
      runsConceded: runsConceded,
      totalLegalBallsBowled: ballsBowled,
      bestBowling: bestBowlingStr,
    );
  }
}
