import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'db_tables.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String dbPath;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final appDocDir = await getApplicationDocumentsDirectory();
      dbPath = join(appDocDir.path, 'cricket_scorecard.db');
    } else {
      final databasesPath = await getDatabasesPath();
      dbPath = join(databasesPath, 'cricket_scorecard.db');
    }

    return await openDatabase(
      dbPath,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: (db, version) async {
        for (final sql in DbTables.createTablesSql) {
          await db.execute(sql);
        }
      },
    );
  }

  Future<void> resetDatabase() async {
    final db = await database;
    for (final table in [
      DbTables.fallOfWickets,
      DbTables.partnerships,
      DbTables.bowlingStats,
      DbTables.battingStats,
      DbTables.balls,
      DbTables.innings,
      DbTables.matchSquads,
      DbTables.matches,
      DbTables.tournamentTeams,
      DbTables.players,
      DbTables.teams,
      DbTables.tournaments,
    ]) {
      await db.execute('DELETE FROM $table;');
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }
}
