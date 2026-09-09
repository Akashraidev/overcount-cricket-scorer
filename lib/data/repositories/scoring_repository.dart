import 'package:sqflite/sqflite.dart';
import '../database/database_service.dart';
import '../database/db_tables.dart';
import '../models/ball.dart';
import '../models/batting_stat.dart';
import '../models/bowling_stat.dart';
import '../models/fall_of_wicket.dart';
import '../models/innings.dart';
import '../models/partnership.dart';

class ScoringRepository {
  final DatabaseService _dbService = DatabaseService.instance;

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

  Future<Innings?> getInningsById(String id) async {
    final db = await _dbService.database;
    final maps = await db.query(
      DbTables.innings,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Innings.fromMap(maps.first);
  }

  Future<int> insertInnings(Innings innings) async {
    final db = await _dbService.database;
    return await db.insert(
      DbTables.innings,
      innings.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateInnings(Innings innings) async {
    final db = await _dbService.database;
    return await db.update(
      DbTables.innings,
      innings.toMap(),
      where: 'id = ?',
      whereArgs: [innings.id],
    );
  }

  Future<List<Ball>> getBallsForInnings(String inningsId) async {
    final db = await _dbService.database;
    final maps = await db.query(
      DbTables.balls,
      where: 'inningsId = ?',
      whereArgs: [inningsId],
      orderBy: 'overNumber ASC, ballNumber ASC',
    );
    return maps.map((m) => Ball.fromMap(m)).toList();
  }

  Future<Ball?> getLastBallForInnings(String inningsId) async {
    final db = await _dbService.database;
    final maps = await db.query(
      DbTables.balls,
      where: 'inningsId = ?',
      whereArgs: [inningsId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Ball.fromMap(maps.first);
  }

  Future<List<BattingStat>> getBattingStats(String inningsId) async {
    final db = await _dbService.database;
    final maps = await db.query(
      DbTables.battingStats,
      where: 'inningsId = ?',
      whereArgs: [inningsId],
      orderBy: 'battingOrder ASC',
    );
    return maps.map((m) => BattingStat.fromMap(m)).toList();
  }

  Future<void> upsertBattingStat(BattingStat stat) async {
    final db = await _dbService.database;
    await db.insert(
      DbTables.battingStats,
      stat.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<BowlingStat>> getBowlingStats(String inningsId) async {
    final db = await _dbService.database;
    final maps = await db.query(
      DbTables.bowlingStats,
      where: 'inningsId = ?',
      whereArgs: [inningsId],
      orderBy: 'bowlingOrder ASC',
    );
    return maps.map((m) => BowlingStat.fromMap(m)).toList();
  }

  Future<void> upsertBowlingStat(BowlingStat stat) async {
    final db = await _dbService.database;
    await db.insert(
      DbTables.bowlingStats,
      stat.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Partnership>> getPartnerships(String inningsId) async {
    final db = await _dbService.database;
    final maps = await db.query(
      DbTables.partnerships,
      where: 'inningsId = ?',
      whereArgs: [inningsId],
      orderBy: 'wicketNumber ASC',
    );
    return maps.map((m) => Partnership.fromMap(m)).toList();
  }

  Future<void> upsertPartnership(Partnership partnership) async {
    final db = await _dbService.database;
    await db.insert(
      DbTables.partnerships,
      partnership.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<FallOfWicket>> getFallOfWickets(String inningsId) async {
    final db = await _dbService.database;
    final maps = await db.query(
      DbTables.fallOfWickets,
      where: 'inningsId = ?',
      whereArgs: [inningsId],
      orderBy: 'wicketNumber ASC',
    );
    return maps.map((m) => FallOfWicket.fromMap(m)).toList();
  }

  Future<void> saveBallTransaction({
    required Ball ball,
    required Innings updatedInnings,
    required BattingStat strikerStat,
    BattingStat? nonStrikerStat,
    required BowlingStat bowlerStat,
    Partnership? currentPartnership,
    FallOfWicket? newFow,
  }) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      // 1. Insert Ball
      await txn.insert(
        DbTables.balls,
        ball.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Update Innings
      await txn.update(
        DbTables.innings,
        updatedInnings.toMap(),
        where: 'id = ?',
        whereArgs: [updatedInnings.id],
      );

      // 3. Upsert Striker Stat
      await txn.insert(
        DbTables.battingStats,
        strikerStat.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 4. Upsert Non-Striker Stat if needed
      if (nonStrikerStat != null) {
        await txn.insert(
          DbTables.battingStats,
          nonStrikerStat.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // 5. Upsert Bowler Stat
      await txn.insert(
        DbTables.bowlingStats,
        bowlerStat.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 6. Upsert Partnership
      if (currentPartnership != null) {
        await txn.insert(
          DbTables.partnerships,
          currentPartnership.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // 7. Insert FOW if wicket
      if (newFow != null) {
        await txn.insert(
          DbTables.fallOfWickets,
          newFow.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> undoBallTransaction({
    required String ballId,
    required Innings revertedInnings,
    required BattingStat strikerStat,
    BattingStat? nonStrikerStat,
    required BowlingStat bowlerStat,
    Partnership? updatedPartnership,
    String? fowIdToDelete,
  }) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      // 1. Delete Ball
      await txn.delete(
        DbTables.balls,
        where: 'id = ?',
        whereArgs: [ballId],
      );

      // 2. Update Innings
      await txn.update(
        DbTables.innings,
        revertedInnings.toMap(),
        where: 'id = ?',
        whereArgs: [revertedInnings.id],
      );

      // 3. Update Striker Stat
      await txn.insert(
        DbTables.battingStats,
        strikerStat.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 4. Update Non-Striker Stat
      if (nonStrikerStat != null) {
        await txn.insert(
          DbTables.battingStats,
          nonStrikerStat.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // 5. Update Bowler Stat
      await txn.insert(
        DbTables.bowlingStats,
        bowlerStat.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 6. Update Partnership
      if (updatedPartnership != null) {
        await txn.insert(
          DbTables.partnerships,
          updatedPartnership.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // 7. Delete FOW if was wicket
      if (fowIdToDelete != null) {
        await txn.delete(
          DbTables.fallOfWickets,
          where: 'id = ?',
          whereArgs: [fowIdToDelete],
        );
      }
    });
  }
}
