import 'package:sqflite/sqflite.dart';
import '../database/database_service.dart';
import '../database/db_tables.dart';
import '../models/team.dart';
import '../models/tournament.dart';

class TournamentRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  Future<List<Tournament>> getAllTournaments() async {
    final db = await _dbService.database;
    final maps = await db.query(DbTables.tournaments, orderBy: 'createdAt DESC');
    return maps.map((m) => Tournament.fromMap(m)).toList();
  }

  Future<Tournament?> getTournamentById(String id) async {
    final db = await _dbService.database;
    final maps = await db.query(
      DbTables.tournaments,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Tournament.fromMap(maps.first);
  }

  Future<int> insertTournament(Tournament tournament) async {
    final db = await _dbService.database;
    return await db.insert(
      DbTables.tournaments,
      tournament.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateTournament(Tournament tournament) async {
    final db = await _dbService.database;
    return await db.update(
      DbTables.tournaments,
      tournament.toMap(),
      where: 'id = ?',
      whereArgs: [tournament.id],
    );
  }

  Future<int> deleteTournament(String id) async {
    final db = await _dbService.database;
    return await db.delete(
      DbTables.tournaments,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> addTeamToTournament(String tournamentId, String teamId) async {
    final db = await _dbService.database;
    await db.insert(
      DbTables.tournamentTeams,
      {'tournamentId': tournamentId, 'teamId': teamId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeTeamFromTournament(String tournamentId, String teamId) async {
    final db = await _dbService.database;
    await db.delete(
      DbTables.tournamentTeams,
      where: 'tournamentId = ? AND teamId = ?',
      whereArgs: [tournamentId, teamId],
    );
  }

  Future<List<Team>> getTeamsForTournament(String tournamentId) async {
    final db = await _dbService.database;
    final maps = await db.rawQuery('''
      SELECT t.* FROM ${DbTables.teams} t
      INNER JOIN ${DbTables.tournamentTeams} tt ON t.id = tt.teamId
      WHERE tt.tournamentId = ?
      ORDER BY t.name ASC
    ''', [tournamentId]);
    return maps.map((m) => Team.fromMap(m)).toList();
  }

  Future<List<TournamentStanding>> getStandings(String tournamentId) async {
    final db = await _dbService.database;
    final teams = await getTeamsForTournament(tournamentId);

    final standingsMap = <String, TournamentStanding>{};
    for (final t in teams) {
      standingsMap[t.id] = TournamentStanding(
        teamId: t.id,
        teamName: t.name,
        teamShortName: t.shortName,
        colorValue: t.colorValue,
      );
    }

    // Fetch all completed matches in this tournament
    final matchMaps = await db.query(
      DbTables.matches,
      where: 'tournamentId = ? AND status = ?',
      whereArgs: [tournamentId, 'completed'],
    );

    for (final m in matchMaps) {
      final matchId = m['id'] as String;
      final winnerTeamId = m['winnerTeamId'] as String?;
      final teamAId = m['teamAId'] as String;
      final teamBId = m['teamBId'] as String;

      final sA = standingsMap[teamAId];
      final sB = standingsMap[teamBId];

      if (sA != null) sA.matchesPlayed++;
      if (sB != null) sB.matchesPlayed++;

      if (winnerTeamId != null && winnerTeamId.isNotEmpty) {
        if (winnerTeamId == teamAId && sA != null) {
          sA.won++;
          sA.points += 2;
          if (sB != null) sB.lost++;
        } else if (winnerTeamId == teamBId && sB != null) {
          sB.won++;
          sB.points += 2;
          if (sA != null) sA.lost++;
        }
      } else {
        // Tied / No result
        if (sA != null) {
          sA.tied++;
          sA.points += 1;
        }
        if (sB != null) {
          sB.tied++;
          sB.points += 1;
        }
      }

      // Fetch innings to accumulate runs & balls for NRR
      final innMaps = await db.query(
        DbTables.innings,
        where: 'matchId = ?',
        whereArgs: [matchId],
      );

      for (final inn in innMaps) {
        final batTeamId = inn['battingTeamId'] as String;
        final bowlTeamId = inn['bowlingTeamId'] as String;
        final runs = (inn['totalRuns'] as int?) ?? 0;
        final balls = (inn['totalLegalBalls'] as int?) ?? 0;

        final batStanding = standingsMap[batTeamId];
        final bowlStanding = standingsMap[bowlTeamId];

        if (batStanding != null) {
          batStanding.runsScored += runs;
          batStanding.ballsFaced += balls;
        }
        if (bowlStanding != null) {
          bowlStanding.runsConceded += runs;
          bowlStanding.ballsBowled += balls;
        }
      }
    }

    final list = standingsMap.values.toList();
    list.sort((a, b) {
      if (b.points != a.points) return b.points.compareTo(a.points);
      return b.netRunRate.compareTo(a.netRunRate);
    });

    return list;
  }
}
