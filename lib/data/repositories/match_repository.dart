import 'package:sqflite/sqflite.dart';
import '../database/database_service.dart';
import '../database/db_tables.dart';
import '../models/innings.dart';
import '../models/match.dart';

class MatchRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  Future<List<CricketMatch>> getAllMatches() async {
    final db = await _dbService.database;
    final maps = await db.query(DbTables.matches, orderBy: 'matchDate DESC, createdAt DESC');
    return maps.map((m) => CricketMatch.fromMap(m)).toList();
  }

  Future<CricketMatch?> getMatchById(String id) async {
    final db = await _dbService.database;
    final maps = await db.query(
      DbTables.matches,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CricketMatch.fromMap(maps.first);
  }

  Future<List<CricketMatch>> getMatchesByStatus(String status) async {
    final db = await _dbService.database;
    final maps = await db.query(
      DbTables.matches,
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'matchDate DESC',
    );
    return maps.map((m) => CricketMatch.fromMap(m)).toList();
  }

  Future<List<CricketMatch>> getMatchesByTournament(String tournamentId) async {
    final db = await _dbService.database;
    final maps = await db.query(
      DbTables.matches,
      where: 'tournamentId = ?',
      whereArgs: [tournamentId],
      orderBy: 'matchDate DESC',
    );
    return maps.map((m) => CricketMatch.fromMap(m)).toList();
  }

  Future<CricketMatch?> getLatestActiveMatch() async {
    final db = await _dbService.database;
    final maps = await db.query(
      DbTables.matches,
      where: 'status = ?',
      whereArgs: ['live'],
      orderBy: 'createdAt DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CricketMatch.fromMap(maps.first);
  }

  Future<List<CricketMatch>> getRecentMatches({int limit = 5}) async {
    final db = await _dbService.database;
    final maps = await db.query(
      DbTables.matches,
      orderBy: 'matchDate DESC, createdAt DESC',
      limit: limit,
    );
    return maps.map((m) => CricketMatch.fromMap(m)).toList();
  }

  Future<int> insertMatch(CricketMatch match) async {
    final db = await _dbService.database;
    return await db.insert(
      DbTables.matches,
      match.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateMatch(CricketMatch match) async {
    final db = await _dbService.database;
    return await db.update(
      DbTables.matches,
      match.toMap(),
      where: 'id = ?',
      whereArgs: [match.id],
    );
  }

  Future<int> deleteMatch(String id) async {
    final db = await _dbService.database;
    return await db.delete(
      DbTables.matches,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, int>> getMatchCounts() async {
    final db = await _dbService.database;
    final total = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DbTables.matches}'),
    ) ?? 0;
    final live = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DbTables.matches} WHERE status = ?', ['live']),
    ) ?? 0;
    final completed = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DbTables.matches} WHERE status = ?', ['completed']),
    ) ?? 0;
    final upcoming = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DbTables.matches} WHERE status = ?', ['upcoming']),
    ) ?? 0;

    return {
      'total': total,
      'live': live,
      'completed': completed,
      'upcoming': upcoming,
    };
  }

  Future<List<Innings>> getInningsForMatch(String matchId) async {
    final db = await _dbService.database;
    final maps = await db.query(
      DbTables.innings,
      where: 'matchId = ?',
      whereArgs: [matchId],
      orderBy: 'inningsNumber ASC',
    );
    return maps.map((m) => Innings.fromMap(m)).toList();
  }
}
