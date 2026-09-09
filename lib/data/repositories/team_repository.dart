import 'package:sqflite/sqflite.dart';
import '../database/database_service.dart';
import '../database/db_tables.dart';
import '../models/player.dart';
import '../models/team.dart';

class TeamRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  Future<List<Team>> getAllTeams() async {
    final db = await _dbService.database;
    final maps = await db.query(DbTables.teams, orderBy: 'name ASC');
    return maps.map((m) => Team.fromMap(m)).toList();
  }

  Future<Team?> getTeamById(String id) async {
    final db = await _dbService.database;
    final maps = await db.query(
      DbTables.teams,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Team.fromMap(maps.first);
  }

  Future<int> insertTeam(Team team) async {
    final db = await _dbService.database;
    return await db.insert(
      DbTables.teams,
      team.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateTeam(Team team) async {
    final db = await _dbService.database;
    return await db.update(
      DbTables.teams,
      team.toMap(),
      where: 'id = ?',
      whereArgs: [team.id],
    );
  }

  Future<int> deleteTeam(String id) async {
    final db = await _dbService.database;
    return await db.delete(
      DbTables.teams,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Player>> getPlayersForTeam(String teamId) async {
    final db = await _dbService.database;
    final maps = await db.query(
      DbTables.players,
      where: 'teamId = ?',
      whereArgs: [teamId],
      orderBy: 'isCaptain DESC, isWicketKeeper DESC, name ASC',
    );
    return maps.map((m) => Player.fromMap(m)).toList();
  }

  Future<int> getPlayerCountForTeam(String teamId) async {
    final db = await _dbService.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DbTables.players} WHERE teamId = ?', [teamId]),
    );
    return count ?? 0;
  }
}
