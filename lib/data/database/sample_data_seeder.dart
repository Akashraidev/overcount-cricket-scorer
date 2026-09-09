import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'database_service.dart';
import 'db_tables.dart';

class SampleDataSeeder {
  SampleDataSeeder._();

  static const _uuid = Uuid();

  static Future<void> seedIfEmpty() async {
    final db = await DatabaseService.instance.database;

    final teamCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DbTables.teams}'),
    );

    if (teamCount == 0) {
      await seedSampleData();
    }
  }

  static Future<void> seedSampleData() async {
    final db = await DatabaseService.instance.database;

    await db.transaction((txn) async {
      final now = DateTime.now().millisecondsSinceEpoch;

      // 1. Tournaments
      final tourneyId1 = 'tourney_t20_2026';
      await txn.insert(DbTables.tournaments, {
        'id': tourneyId1,
        'name': 'World T20 Championship 2026',
        'format': 'T20',
        'startDate': now - 86400000 * 7,
        'endDate': now + 86400000 * 14,
        'status': 'active',
        'createdAt': now,
      });

      final tourneyId2 = 'tourney_tri_2026';
      await txn.insert(DbTables.tournaments, {
        'id': tourneyId2,
        'name': 'International ODI Tri-Series',
        'format': 'ODI',
        'startDate': now - 86400000 * 14,
        'endDate': now - 86400000 * 2,
        'status': 'completed',
        'createdAt': now,
      });

      // 2. Teams
      final indTeamId = 'team_ind';
      final ausTeamId = 'team_aus';
      final engTeamId = 'team_eng';
      final saTeamId = 'team_sa';

      final teams = [
        {'id': indTeamId, 'name': 'India', 'shortName': 'IND', 'colorValue': 0xFF1D4ED8},
        {'id': ausTeamId, 'name': 'Australia', 'shortName': 'AUS', 'colorValue': 0xFFEAB308},
        {'id': engTeamId, 'name': 'England', 'shortName': 'ENG', 'colorValue': 0xFFDC2626},
        {'id': saTeamId, 'name': 'South Africa', 'shortName': 'SA', 'colorValue': 0xFF059669},
      ];

      for (final t in teams) {
        await txn.insert(DbTables.teams, {
          'id': t['id'],
          'name': t['name'],
          'shortName': t['shortName'],
          'colorValue': t['colorValue'],
          'createdAt': now,
        });

        // Link to tournaments
        await txn.insert(DbTables.tournamentTeams, {
          'tournamentId': tourneyId1,
          'teamId': t['id'],
        });
      }

      // 3. Players
      // India Players
      final indPlayers = [
        {'id': 'p_ind_1', 'name': 'Rohit Sharma', 'num': 45, 'role': 'Batter', 'bat': 'Right-hand bat', 'bowl': 'Right-arm off break', 'cap': 1, 'wk': 0},
        {'id': 'p_ind_2', 'name': 'Virat Kohli', 'num': 18, 'role': 'Batter', 'bat': 'Right-hand bat', 'bowl': 'Right-arm medium', 'cap': 0, 'wk': 0},
        {'id': 'p_ind_3', 'name': 'Suryakumar Yadav', 'num': 63, 'role': 'Batter', 'bat': 'Right-hand bat', 'bowl': 'Right-arm medium', 'cap': 0, 'wk': 0},
        {'id': 'p_ind_4', 'name': 'Rishabh Pant', 'num': 17, 'role': 'Wicketkeeper', 'bat': 'Left-hand bat', 'bowl': 'None', 'cap': 0, 'wk': 1},
        {'id': 'p_ind_5', 'name': 'Hardik Pandya', 'num': 33, 'role': 'All Rounder', 'bat': 'Right-hand bat', 'bowl': 'Right-arm fast-medium', 'cap': 0, 'wk': 0},
        {'id': 'p_ind_6', 'name': 'Ravindra Jadeja', 'num': 8, 'role': 'All Rounder', 'bat': 'Left-hand bat', 'bowl': 'Slow left-arm orthodox', 'cap': 0, 'wk': 0},
        {'id': 'p_ind_7', 'name': 'Axar Patel', 'num': 20, 'role': 'All Rounder', 'bat': 'Left-hand bat', 'bowl': 'Slow left-arm orthodox', 'cap': 0, 'wk': 0},
        {'id': 'p_ind_8', 'name': 'Kuldeep Yadav', 'num': 23, 'role': 'Bowler', 'bat': 'Left-hand bat', 'bowl': 'Left-arm wrist spin', 'cap': 0, 'wk': 0},
        {'id': 'p_ind_9', 'name': 'Jasprit Bumrah', 'num': 93, 'role': 'Bowler', 'bat': 'Right-hand bat', 'bowl': 'Right-arm fast', 'cap': 0, 'wk': 0},
        {'id': 'p_ind_10', 'name': 'Arshdeep Singh', 'num': 2, 'role': 'Bowler', 'bat': 'Left-hand bat', 'bowl': 'Left-arm fast-medium', 'cap': 0, 'wk': 0},
        {'id': 'p_ind_11', 'name': 'Mohammed Siraj', 'num': 73, 'role': 'Bowler', 'bat': 'Right-hand bat', 'bowl': 'Right-arm fast-medium', 'cap': 0, 'wk': 0},
      ];

      for (final p in indPlayers) {
        await txn.insert(DbTables.players, {
          'id': p['id'],
          'teamId': indTeamId,
          'name': p['name'],
          'jerseyNumber': p['num'],
          'role': p['role'],
          'battingStyle': p['bat'],
          'bowlingStyle': p['bowl'],
          'isCaptain': p['cap'],
          'isWicketKeeper': p['wk'],
          'createdAt': now,
        });
      }

      // Update Captain/Keeper in India Team
      await txn.update(
        DbTables.teams,
        {'captainId': 'p_ind_1', 'keeperId': 'p_ind_4'},
        where: 'id = ?',
        whereArgs: [indTeamId],
      );

      // Australia Players
      final ausPlayers = [
        {'id': 'p_aus_1', 'name': 'Travis Head', 'num': 62, 'role': 'Batter', 'bat': 'Left-hand bat', 'bowl': 'Right-arm off break', 'cap': 0, 'wk': 0},
        {'id': 'p_aus_2', 'name': 'David Warner', 'num': 31, 'role': 'Batter', 'bat': 'Left-hand bat', 'bowl': 'Right-arm leg break', 'cap': 0, 'wk': 0},
        {'id': 'p_aus_3', 'name': 'Mitchell Marsh', 'num': 8, 'role': 'All Rounder', 'bat': 'Right-hand bat', 'bowl': 'Right-arm medium', 'cap': 1, 'wk': 0},
        {'id': 'p_aus_4', 'name': 'Glenn Maxwell', 'num': 32, 'role': 'All Rounder', 'bat': 'Right-hand bat', 'bowl': 'Right-arm off break', 'cap': 0, 'wk': 0},
        {'id': 'p_aus_5', 'name': 'Marcus Stoinis', 'num': 17, 'role': 'All Rounder', 'bat': 'Right-hand bat', 'bowl': 'Right-arm medium-fast', 'cap': 0, 'wk': 0},
        {'id': 'p_aus_6', 'name': 'Tim David', 'num': 85, 'role': 'Batter', 'bat': 'Right-hand bat', 'bowl': 'Right-arm off break', 'cap': 0, 'wk': 0},
        {'id': 'p_aus_7', 'name': 'Matthew Wade', 'num': 13, 'role': 'Wicketkeeper', 'bat': 'Left-hand bat', 'bowl': 'Right-arm medium', 'cap': 0, 'wk': 1},
        {'id': 'p_aus_8', 'name': 'Pat Cummins', 'num': 30, 'role': 'Bowler', 'bat': 'Right-hand bat', 'bowl': 'Right-arm fast', 'cap': 0, 'wk': 0},
        {'id': 'p_aus_9', 'name': 'Mitchell Starc', 'num': 56, 'role': 'Bowler', 'bat': 'Left-hand bat', 'bowl': 'Left-arm fast', 'cap': 0, 'wk': 0},
        {'id': 'p_aus_10', 'name': 'Adam Zampa', 'num': 88, 'role': 'Bowler', 'bat': 'Right-hand bat', 'bowl': 'Right-arm leg break', 'cap': 0, 'wk': 0},
        {'id': 'p_aus_11', 'name': 'Josh Hazlewood', 'num': 38, 'role': 'Bowler', 'bat': 'Left-hand bat', 'bowl': 'Right-arm fast-medium', 'cap': 0, 'wk': 0},
      ];

      for (final p in ausPlayers) {
        await txn.insert(DbTables.players, {
          'id': p['id'],
          'teamId': ausTeamId,
          'name': p['name'],
          'jerseyNumber': p['num'],
          'role': p['role'],
          'battingStyle': p['bat'],
          'bowlingStyle': p['bowl'],
          'isCaptain': p['cap'],
          'isWicketKeeper': p['wk'],
          'createdAt': now,
        });
      }

      await txn.update(
        DbTables.teams,
        {'captainId': 'p_aus_3', 'keeperId': 'p_aus_7'},
        where: 'id = ?',
        whereArgs: [ausTeamId],
      );

      // England Players
      final engPlayers = [
        {'id': 'p_eng_1', 'name': 'Jos Buttler', 'num': 63, 'role': 'Wicketkeeper', 'bat': 'Right-hand bat', 'bowl': 'None', 'cap': 1, 'wk': 1},
        {'id': 'p_eng_2', 'name': 'Phil Salt', 'num': 42, 'role': 'Batter', 'bat': 'Right-hand bat', 'bowl': 'Right-arm medium', 'cap': 0, 'wk': 0},
        {'id': 'p_eng_3', 'name': 'Jonny Bairstow', 'num': 51, 'role': 'Batter', 'bat': 'Right-hand bat', 'bowl': 'Right-arm medium', 'cap': 0, 'wk': 0},
        {'id': 'p_eng_4', 'name': 'Harry Brook', 'num': 88, 'role': 'Batter', 'bat': 'Right-hand bat', 'bowl': 'Right-arm medium', 'cap': 0, 'wk': 0},
        {'id': 'p_eng_5', 'name': 'Moeen Ali', 'num': 18, 'role': 'All Rounder', 'bat': 'Left-hand bat', 'bowl': 'Right-arm off break', 'cap': 0, 'wk': 0},
        {'id': 'p_eng_6', 'name': 'Liam Livingstone', 'num': 23, 'role': 'All Rounder', 'bat': 'Right-hand bat', 'bowl': 'Right-arm leg spin', 'cap': 0, 'wk': 0},
        {'id': 'p_eng_7', 'name': 'Sam Curran', 'num': 58, 'role': 'All Rounder', 'bat': 'Left-hand bat', 'bowl': 'Left-arm medium-fast', 'cap': 0, 'wk': 0},
        {'id': 'p_eng_8', 'name': 'Chris Jordan', 'num': 34, 'role': 'Bowler', 'bat': 'Right-hand bat', 'bowl': 'Right-arm fast', 'cap': 0, 'wk': 0},
        {'id': 'p_eng_9', 'name': 'Jofra Archer', 'num': 22, 'role': 'Bowler', 'bat': 'Right-hand bat', 'bowl': 'Right-arm fast', 'cap': 0, 'wk': 0},
        {'id': 'p_eng_10', 'name': 'Adil Rashid', 'num': 95, 'role': 'Bowler', 'bat': 'Right-hand bat', 'bowl': 'Right-arm leg break', 'cap': 0, 'wk': 0},
        {'id': 'p_eng_11', 'name': 'Mark Wood', 'num': 33, 'role': 'Bowler', 'bat': 'Right-hand bat', 'bowl': 'Right-arm fast', 'cap': 0, 'wk': 0},
      ];

      for (final p in engPlayers) {
        await txn.insert(DbTables.players, {
          'id': p['id'],
          'teamId': engTeamId,
          'name': p['name'],
          'jerseyNumber': p['num'],
          'role': p['role'],
          'battingStyle': p['bat'],
          'bowlingStyle': p['bowl'],
          'isCaptain': p['cap'],
          'isWicketKeeper': p['wk'],
          'createdAt': now,
        });
      }

      // South Africa Players
      final saPlayers = [
        {'id': 'p_sa_1', 'name': 'Quinton de Kock', 'num': 12, 'role': 'Wicketkeeper', 'bat': 'Left-hand bat', 'bowl': 'None', 'cap': 0, 'wk': 1},
        {'id': 'p_sa_2', 'name': 'Reeza Hendricks', 'num': 17, 'role': 'Batter', 'bat': 'Right-hand bat', 'bowl': 'Right-arm medium', 'cap': 0, 'wk': 0},
        {'id': 'p_sa_3', 'name': 'Aiden Markram', 'num': 94, 'role': 'Batter', 'bat': 'Right-hand bat', 'bowl': 'Right-arm off break', 'cap': 1, 'wk': 0},
        {'id': 'p_sa_4', 'name': 'Heinrich Klaasen', 'num': 45, 'role': 'Batter', 'bat': 'Right-hand bat', 'bowl': 'Right-arm off break', 'cap': 0, 'wk': 0},
        {'id': 'p_sa_5', 'name': 'David Miller', 'num': 10, 'role': 'Batter', 'bat': 'Left-hand bat', 'bowl': 'Right-arm off break', 'cap': 0, 'wk': 0},
        {'id': 'p_sa_6', 'name': 'Tristan Stubbs', 'num': 30, 'role': 'Batter', 'bat': 'Right-hand bat', 'bowl': 'Right-arm off break', 'cap': 0, 'wk': 0},
        {'id': 'p_sa_7', 'name': 'Marco Jansen', 'num': 70, 'role': 'All Rounder', 'bat': 'Right-hand bat', 'bowl': 'Left-arm fast', 'cap': 0, 'wk': 0},
        {'id': 'p_sa_8', 'name': 'Keshav Maharaj', 'num': 16, 'role': 'Bowler', 'bat': 'Right-hand bat', 'bowl': 'Slow left-arm orthodox', 'cap': 0, 'wk': 0},
        {'id': 'p_sa_9', 'name': 'Kagiso Rabada', 'num': 25, 'role': 'Bowler', 'bat': 'Left-hand bat', 'bowl': 'Right-arm fast', 'cap': 0, 'wk': 0},
        {'id': 'p_sa_10', 'name': 'Anrich Nortje', 'num': 20, 'role': 'Bowler', 'bat': 'Right-hand bat', 'bowl': 'Right-arm fast', 'cap': 0, 'wk': 0},
        {'id': 'p_sa_11', 'name': 'Tabraiz Shamsi', 'num': 26, 'role': 'Bowler', 'bat': 'Right-hand bat', 'bowl': 'Left-arm wrist spin', 'cap': 0, 'wk': 0},
      ];

      for (final p in saPlayers) {
        await txn.insert(DbTables.players, {
          'id': p['id'],
          'teamId': saTeamId,
          'name': p['name'],
          'jerseyNumber': p['num'],
          'role': p['role'],
          'battingStyle': p['bat'],
          'bowlingStyle': p['bowl'],
          'isCaptain': p['cap'],
          'isWicketKeeper': p['wk'],
          'createdAt': now,
        });
      }

      // 4. Sample Completed Match: IND vs AUS (T20 Final)
      final match1Id = 'match_ind_aus_final';
      await txn.insert(DbTables.matches, {
        'id': match1Id,
        'tournamentId': tourneyId1,
        'title': 'Grand Final: IND vs AUS',
        'venue': 'Kensington Oval, Bridgetown',
        'matchDate': now - 86400000 * 2,
        'format': 'T20',
        'totalOvers': 20,
        'wicketsPerInnings': 10,
        'ballsPerOver': 6,
        'teamAId': indTeamId,
        'teamBId': ausTeamId,
        'tossWinnerTeamId': indTeamId,
        'tossDecision': 'Bat',
        'status': 'completed',
        'resultSummary': 'India won by 24 runs',
        'winnerTeamId': indTeamId,
        'currentInningsNumber': 2,
        'createdAt': now - 86400000 * 2,
      });

      // Innings 1: India 205/5 (20.0 ov)
      final inn1Id = 'inn_ind_aus_1';
      await txn.insert(DbTables.innings, {
        'id': inn1Id,
        'matchId': match1Id,
        'inningsNumber': 1,
        'battingTeamId': indTeamId,
        'bowlingTeamId': ausTeamId,
        'totalRuns': 205,
        'totalWickets': 5,
        'totalLegalBalls': 120,
        'wides': 6,
        'noBalls': 1,
        'byes': 2,
        'legByes': 3,
        'penaltyRuns': 0,
        'targetRuns': null,
        'isCompleted': 1,
        'createdAt': now - 86400000 * 2,
      });

      // Innings 1 Batting Stats
      final indBatStats = [
        {'pId': 'p_ind_1', 'name': 'Rohit Sharma', 'r': 92, 'b': 41, 'f': 7, 's': 8, 'out': 1, 'dt': 'bowled', 'bName': 'Mitchell Starc'},
        {'pId': 'p_ind_2', 'name': 'Virat Kohli', 'r': 0, 'b': 5, 'f': 0, 's': 0, 'out': 1, 'dt': 'caught', 'bName': 'Josh Hazlewood', 'fName': 'Tim David'},
        {'pId': 'p_ind_3', 'name': 'Suryakumar Yadav', 'r': 31, 'b': 16, 'f': 3, 's': 2, 'out': 1, 'dt': 'caught', 'bName': 'Mitchell Starc', 'fName': 'Matthew Wade'},
        {'pId': 'p_ind_4', 'name': 'Rishabh Pant', 'r': 15, 'b': 14, 'f': 1, 's': 1, 'out': 1, 'dt': 'caught', 'bName': 'Marcus Stoinis', 'fName': 'Josh Hazlewood'},
        {'pId': 'p_ind_5', 'name': 'Hardik Pandya', 'r': 27, 'b': 17, 'f': 1, 's': 2, 'out': 0},
        {'pId': 'p_ind_6', 'name': 'Ravindra Jadeja', 'r': 9, 'b': 5, 'f': 0, 's': 1, 'out': 0},
        {'pId': 'p_ind_7', 'name': 'Axar Patel', 'r': 19, 'b': 22, 'f': 2, 's': 0, 'out': 1, 'dt': 'run out', 'fName': 'Pat Cummins'},
      ];

      for (int i = 0; i < indBatStats.length; i++) {
        final b = indBatStats[i];
        await txn.insert(DbTables.battingStats, {
          'id': _uuid.v4(),
          'inningsId': inn1Id,
          'playerId': b['pId'],
          'playerName': b['name'],
          'runs': b['r'],
          'balls': b['b'],
          'fours': b['f'],
          'sixes': b['s'],
          'dots': (b['b'] as int) ~/ 3,
          'isOut': b['out'],
          'dismissalType': b['dt'],
          'bowlerName': b['bName'],
          'fielderName': b['fName'],
          'battingOrder': i + 1,
        });
      }

      // Innings 1 Bowling Stats (AUS)
      final ausBowlStats = [
        {'pId': 'p_aus_9', 'name': 'Mitchell Starc', 'balls': 24, 'm': 0, 'r': 45, 'w': 2, 'wd': 3, 'nb': 1},
        {'pId': 'p_aus_11', 'name': 'Josh Hazlewood', 'balls': 24, 'm': 0, 'r': 14, 'w': 1, 'wd': 0, 'nb': 0},
        {'pId': 'p_aus_8', 'name': 'Pat Cummins', 'balls': 24, 'm': 0, 'r': 48, 'w': 0, 'wd': 1, 'nb': 0},
        {'pId': 'p_aus_10', 'name': 'Adam Zampa', 'balls': 24, 'm': 0, 'r': 41, 'w': 0, 'wd': 1, 'nb': 0},
        {'pId': 'p_aus_5', 'name': 'Marcus Stoinis', 'balls': 24, 'm': 0, 'r': 56, 'w': 2, 'wd': 1, 'nb': 0},
      ];

      for (int i = 0; i < ausBowlStats.length; i++) {
        final bw = ausBowlStats[i];
        await txn.insert(DbTables.bowlingStats, {
          'id': _uuid.v4(),
          'inningsId': inn1Id,
          'playerId': bw['pId'],
          'playerName': bw['name'],
          'totalLegalBalls': bw['balls'],
          'maidens': bw['m'],
          'runsConceded': bw['r'],
          'wickets': bw['w'],
          'wides': bw['wd'],
          'noBalls': bw['nb'],
          'dots': 8,
          'bowlingOrder': i + 1,
        });
      }

      // Innings 1 FOW & Partnerships
      await txn.insert(DbTables.fallOfWickets, {
        'id': _uuid.v4(),
        'inningsId': inn1Id,
        'wicketNumber': 1,
        'score': 6,
        'totalLegalBalls': 9,
        'playerId': 'p_ind_2',
        'playerName': 'Virat Kohli',
      });
      await txn.insert(DbTables.fallOfWickets, {
        'id': _uuid.v4(),
        'inningsId': inn1Id,
        'wicketNumber': 2,
        'score': 93,
        'totalLegalBalls': 48,
        'playerId': 'p_ind_4',
        'playerName': 'Rishabh Pant',
      });
      await txn.insert(DbTables.fallOfWickets, {
        'id': _uuid.v4(),
        'inningsId': inn1Id,
        'wicketNumber': 3,
        'score': 127,
        'totalLegalBalls': 68,
        'playerId': 'p_ind_1',
        'playerName': 'Rohit Sharma',
      });

      // Innings 2: Australia 181/7 (20.0 ov)
      final inn2Id = 'inn_ind_aus_2';
      await txn.insert(DbTables.innings, {
        'id': inn2Id,
        'matchId': match1Id,
        'inningsNumber': 2,
        'battingTeamId': ausTeamId,
        'bowlingTeamId': indTeamId,
        'totalRuns': 181,
        'totalWickets': 7,
        'totalLegalBalls': 120,
        'wides': 4,
        'noBalls': 0,
        'byes': 1,
        'legByes': 4,
        'penaltyRuns': 0,
        'targetRuns': 206,
        'isCompleted': 1,
        'createdAt': now - 86400000 * 2,
      });

      // Innings 2 Batting Stats (AUS)
      final ausBatStats = [
        {'pId': 'p_aus_1', 'name': 'Travis Head', 'r': 76, 'b': 43, 'f': 9, 's': 4, 'out': 1, 'dt': 'caught', 'bName': 'Jasprit Bumrah', 'fName': 'Rohit Sharma'},
        {'pId': 'p_aus_2', 'name': 'David Warner', 'r': 6, 'b': 6, 'f': 1, 's': 0, 'out': 1, 'dt': 'caught', 'bName': 'Arshdeep Singh', 'fName': 'Suryakumar Yadav'},
        {'pId': 'p_aus_3', 'name': 'Mitchell Marsh', 'r': 37, 'b': 28, 'f': 3, 's': 2, 'out': 1, 'dt': 'caught', 'bName': 'Kuldeep Yadav', 'fName': 'Axar Patel'},
        {'pId': 'p_aus_4', 'name': 'Glenn Maxwell', 'r': 20, 'b': 12, 'f': 2, 's': 1, 'out': 1, 'dt': 'bowled', 'bName': 'Kuldeep Yadav'},
        {'pId': 'p_aus_5', 'name': 'Marcus Stoinis', 'r': 2, 'b': 4, 'f': 0, 's': 0, 'out': 1, 'dt': 'caught', 'bName': 'Axar Patel', 'fName': 'Hardik Pandya'},
        {'pId': 'p_aus_6', 'name': 'Tim David', 'r': 15, 'b': 11, 'f': 1, 's': 1, 'out': 1, 'dt': 'caught', 'bName': 'Arshdeep Singh', 'fName': 'Jasprit Bumrah'},
        {'pId': 'p_aus_7', 'name': 'Matthew Wade', 'r': 1, 'b': 2, 'f': 0, 's': 0, 'out': 1, 'dt': 'caught', 'bName': 'Arshdeep Singh', 'fName': 'Kuldeep Yadav'},
        {'pId': 'p_aus_8', 'name': 'Pat Cummins', 'r': 11, 'b': 8, 'f': 1, 's': 0, 'out': 0},
      ];

      for (int i = 0; i < ausBatStats.length; i++) {
        final b = ausBatStats[i];
        await txn.insert(DbTables.battingStats, {
          'id': _uuid.v4(),
          'inningsId': inn2Id,
          'playerId': b['pId'],
          'playerName': b['name'],
          'runs': b['r'],
          'balls': b['b'],
          'fours': b['f'],
          'sixes': b['s'],
          'dots': 5,
          'isOut': b['out'],
          'dismissalType': b['dt'],
          'bowlerName': b['bName'],
          'fielderName': b['fName'],
          'battingOrder': i + 1,
        });
      }

      // Innings 2 Bowling Stats (IND)
      final indBowlStats = [
        {'pId': 'p_ind_10', 'name': 'Arshdeep Singh', 'balls': 24, 'm': 0, 'r': 37, 'w': 3, 'wd': 2, 'nb': 0},
        {'pId': 'p_ind_11', 'name': 'Mohammed Siraj', 'balls': 24, 'm': 0, 'r': 36, 'w': 0, 'wd': 1, 'nb': 0},
        {'pId': 'p_ind_9', 'name': 'Jasprit Bumrah', 'balls': 24, 'm': 0, 'r': 29, 'w': 1, 'wd': 0, 'nb': 0},
        {'pId': 'p_ind_5', 'name': 'Hardik Pandya', 'balls': 24, 'm': 0, 'r': 47, 'w': 0, 'wd': 1, 'nb': 0},
        {'pId': 'p_ind_8', 'name': 'Kuldeep Yadav', 'balls': 24, 'm': 0, 'r': 24, 'w': 2, 'wd': 0, 'nb': 0},
      ];

      for (int i = 0; i < indBowlStats.length; i++) {
        final bw = indBowlStats[i];
        await txn.insert(DbTables.bowlingStats, {
          'id': _uuid.v4(),
          'inningsId': inn2Id,
          'playerId': bw['pId'],
          'playerName': bw['name'],
          'totalLegalBalls': bw['balls'],
          'maidens': bw['m'],
          'runsConceded': bw['r'],
          'wickets': bw['w'],
          'wides': bw['wd'],
          'noBalls': bw['nb'],
          'dots': 9,
          'bowlingOrder': i + 1,
        });
      }

      // 5. Sample Live/Ongoing Match: ENG vs SA
      final match2Id = 'match_eng_sa_live';
      await txn.insert(DbTables.matches, {
        'id': match2Id,
        'tournamentId': tourneyId1,
        'title': 'Semi Final 2: ENG vs SA',
        'venue': 'Daren Sammy National Cricket Stadium, Gros Islet',
        'matchDate': now - 3600000,
        'format': 'T20',
        'totalOvers': 20,
        'wicketsPerInnings': 10,
        'ballsPerOver': 6,
        'teamAId': engTeamId,
        'teamBId': saTeamId,
        'tossWinnerTeamId': saTeamId,
        'tossDecision': 'Bowl',
        'status': 'live',
        'resultSummary': null,
        'winnerTeamId': null,
        'currentInningsNumber': 1,
        'createdAt': now - 3600000,
      });

      final innLiveId = 'inn_eng_sa_1';
      await txn.insert(DbTables.innings, {
        'id': innLiveId,
        'matchId': match2Id,
        'inningsNumber': 1,
        'battingTeamId': engTeamId,
        'bowlingTeamId': saTeamId,
        'totalRuns': 134,
        'totalWickets': 3,
        'totalLegalBalls': 87, // 14.3 overs
        'wides': 3,
        'noBalls': 1,
        'byes': 0,
        'legByes': 2,
        'penaltyRuns': 0,
        'targetRuns': null,
        'isCompleted': 0,
        'createdAt': now - 3600000,
      });

      // Batters in Live match
      await txn.insert(DbTables.battingStats, {
        'id': _uuid.v4(),
        'inningsId': innLiveId,
        'playerId': 'p_eng_1',
        'playerName': 'Jos Buttler',
        'runs': 58,
        'balls': 34,
        'fours': 6,
        'sixes': 3,
        'dots': 10,
        'isOut': 0,
        'battingOrder': 1,
      });
      await txn.insert(DbTables.battingStats, {
        'id': _uuid.v4(),
        'inningsId': innLiveId,
        'playerId': 'p_eng_4',
        'playerName': 'Harry Brook',
        'runs': 32,
        'balls': 21,
        'fours': 3,
        'sixes': 1,
        'dots': 6,
        'isOut': 0,
        'battingOrder': 4,
      });

      // Bowlers in Live match
      await txn.insert(DbTables.bowlingStats, {
        'id': _uuid.v4(),
        'inningsId': innLiveId,
        'playerId': 'p_sa_9',
        'playerName': 'Kagiso Rabada',
        'totalLegalBalls': 18,
        'maidens': 0,
        'runsConceded': 24,
        'wickets': 1,
        'wides': 1,
        'noBalls': 0,
        'dots': 6,
        'bowlingOrder': 1,
      });
      await txn.insert(DbTables.bowlingStats, {
        'id': _uuid.v4(),
        'inningsId': innLiveId,
        'playerId': 'p_sa_10',
        'playerName': 'Anrich Nortje',
        'totalLegalBalls': 15,
        'maidens': 0,
        'runsConceded': 21,
        'wickets': 1,
        'wides': 0,
        'noBalls': 1,
        'dots': 5,
        'bowlingOrder': 2,
      });
    });
  }
}
