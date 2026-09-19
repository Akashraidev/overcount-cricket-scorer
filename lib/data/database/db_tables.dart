class DbTables {
  DbTables._();

  static const String tournaments = 'tournaments';
  static const String teams = 'teams';
  static const String players = 'players';
  static const String tournamentTeams = 'tournament_teams';
  static const String matches = 'matches';
  static const String matchSquads = 'match_squads';
  static const String innings = 'innings';
  static const String balls = 'balls';
  static const String battingStats = 'batting_stats';
  static const String bowlingStats = 'bowling_stats';
  static const String partnerships = 'partnerships';
  static const String fallOfWickets = 'fall_of_wickets';

  static const List<String> createTablesSql = [
    '''
    CREATE TABLE IF NOT EXISTS $tournaments (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      format TEXT NOT NULL,
      startDate INTEGER NOT NULL,
      endDate INTEGER,
      status TEXT NOT NULL,
      createdAt INTEGER NOT NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS $teams (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      shortName TEXT NOT NULL,
      colorValue INTEGER NOT NULL,
      captainId TEXT,
      keeperId TEXT,
      createdAt INTEGER NOT NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS $players (
      id TEXT PRIMARY KEY,
      teamId TEXT NOT NULL,
      name TEXT NOT NULL,
      jerseyNumber INTEGER NOT NULL,
      role TEXT NOT NULL,
      battingStyle TEXT NOT NULL,
      bowlingStyle TEXT NOT NULL,
      isCaptain INTEGER NOT NULL DEFAULT 0,
      isWicketKeeper INTEGER NOT NULL DEFAULT 0,
      photoUrl TEXT,
      createdAt INTEGER NOT NULL,
      FOREIGN KEY (teamId) REFERENCES $teams(id) ON DELETE CASCADE
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS $tournamentTeams (
      tournamentId TEXT NOT NULL,
      teamId TEXT NOT NULL,
      PRIMARY KEY (tournamentId, teamId),
      FOREIGN KEY (tournamentId) REFERENCES $tournaments(id) ON DELETE CASCADE,
      FOREIGN KEY (teamId) REFERENCES $teams(id) ON DELETE CASCADE
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS $matches (
      id TEXT PRIMARY KEY,
      tournamentId TEXT,
      title TEXT NOT NULL,
      venue TEXT NOT NULL,
      matchDate INTEGER NOT NULL,
      format TEXT NOT NULL,
      totalOvers INTEGER NOT NULL,
      wicketsPerInnings INTEGER NOT NULL DEFAULT 10,
      ballsPerOver INTEGER NOT NULL DEFAULT 6,
      teamAId TEXT NOT NULL,
      teamBId TEXT NOT NULL,
      tossWinnerTeamId TEXT,
      tossDecision TEXT,
      status TEXT NOT NULL,
      resultSummary TEXT,
      winnerTeamId TEXT,
      currentInningsNumber INTEGER NOT NULL DEFAULT 1,
      createdAt INTEGER NOT NULL,
      FOREIGN KEY (teamAId) REFERENCES $teams(id) ON DELETE CASCADE,
      FOREIGN KEY (teamBId) REFERENCES $teams(id) ON DELETE CASCADE
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS $matchSquads (
      id TEXT PRIMARY KEY,
      matchId TEXT NOT NULL,
      teamId TEXT NOT NULL,
      playerId TEXT NOT NULL,
      isPlayingXi INTEGER NOT NULL DEFAULT 1,
      isCaptain INTEGER NOT NULL DEFAULT 0,
      isWicketKeeper INTEGER NOT NULL DEFAULT 0,
      battingOrder INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (matchId) REFERENCES $matches(id) ON DELETE CASCADE,
      FOREIGN KEY (teamId) REFERENCES $teams(id) ON DELETE CASCADE,
      FOREIGN KEY (playerId) REFERENCES $players(id) ON DELETE CASCADE
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS $innings (
      id TEXT PRIMARY KEY,
      matchId TEXT NOT NULL,
      inningsNumber INTEGER NOT NULL,
      battingTeamId TEXT NOT NULL,
      bowlingTeamId TEXT NOT NULL,
      totalRuns INTEGER NOT NULL DEFAULT 0,
      totalWickets INTEGER NOT NULL DEFAULT 0,
      totalLegalBalls INTEGER NOT NULL DEFAULT 0,
      wides INTEGER NOT NULL DEFAULT 0,
      noBalls INTEGER NOT NULL DEFAULT 0,
      byes INTEGER NOT NULL DEFAULT 0,
      legByes INTEGER NOT NULL DEFAULT 0,
      penaltyRuns INTEGER NOT NULL DEFAULT 0,
      targetRuns INTEGER,
      isCompleted INTEGER NOT NULL DEFAULT 0,
      createdAt INTEGER NOT NULL,
      FOREIGN KEY (matchId) REFERENCES $matches(id) ON DELETE CASCADE,
      FOREIGN KEY (battingTeamId) REFERENCES $teams(id) ON DELETE CASCADE,
      FOREIGN KEY (bowlingTeamId) REFERENCES $teams(id) ON DELETE CASCADE
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS $balls (
      id TEXT PRIMARY KEY,
      matchId TEXT NOT NULL,
      inningsId TEXT NOT NULL,
      overNumber INTEGER NOT NULL,
      ballNumber INTEGER NOT NULL,
      legalBallNumber INTEGER NOT NULL DEFAULT 0,
      bowlerId TEXT NOT NULL,
      batsmanId TEXT NOT NULL,
      nonStrikerId TEXT NOT NULL,
      runsBat INTEGER NOT NULL DEFAULT 0,
      extras INTEGER NOT NULL DEFAULT 0,
      extraType TEXT NOT NULL DEFAULT 'none',
      isLegalBall INTEGER NOT NULL DEFAULT 1,
      isWicket INTEGER NOT NULL DEFAULT 0,
      wicketType TEXT,
      dismissedPlayerId TEXT,
      fielderId TEXT,
      commentary TEXT,
      strikeChanged INTEGER NOT NULL DEFAULT 0,
      timestamp INTEGER NOT NULL,
      FOREIGN KEY (matchId) REFERENCES $matches(id) ON DELETE CASCADE,
      FOREIGN KEY (inningsId) REFERENCES $innings(id) ON DELETE CASCADE
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS $battingStats (
      id TEXT PRIMARY KEY,
      inningsId TEXT NOT NULL,
      playerId TEXT NOT NULL,
      playerName TEXT NOT NULL,
      runs INTEGER NOT NULL DEFAULT 0,
      balls INTEGER NOT NULL DEFAULT 0,
      fours INTEGER NOT NULL DEFAULT 0,
      sixes INTEGER NOT NULL DEFAULT 0,
      dots INTEGER NOT NULL DEFAULT 0,
      isOut INTEGER NOT NULL DEFAULT 0,
      dismissalType TEXT,
      bowlerId TEXT,
      bowlerName TEXT,
      fielderId TEXT,
      fielderName TEXT,
      battingOrder INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (inningsId) REFERENCES $innings(id) ON DELETE CASCADE
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS $bowlingStats (
      id TEXT PRIMARY KEY,
      inningsId TEXT NOT NULL,
      playerId TEXT NOT NULL,
      playerName TEXT NOT NULL,
      totalLegalBalls INTEGER NOT NULL DEFAULT 0,
      maidens INTEGER NOT NULL DEFAULT 0,
      runsConceded INTEGER NOT NULL DEFAULT 0,
      wickets INTEGER NOT NULL DEFAULT 0,
      wides INTEGER NOT NULL DEFAULT 0,
      noBalls INTEGER NOT NULL DEFAULT 0,
      dots INTEGER NOT NULL DEFAULT 0,
      bowlingOrder INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (inningsId) REFERENCES $innings(id) ON DELETE CASCADE
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS $partnerships (
      id TEXT PRIMARY KEY,
      inningsId TEXT NOT NULL,
      wicketNumber INTEGER NOT NULL,
      batter1Id TEXT NOT NULL,
      batter1Name TEXT NOT NULL,
      batter1Runs INTEGER NOT NULL DEFAULT 0,
      batter1Balls INTEGER NOT NULL DEFAULT 0,
      batter2Id TEXT NOT NULL,
      batter2Name TEXT NOT NULL,
      batter2Runs INTEGER NOT NULL DEFAULT 0,
      batter2Balls INTEGER NOT NULL DEFAULT 0,
      totalRuns INTEGER NOT NULL DEFAULT 0,
      totalBalls INTEGER NOT NULL DEFAULT 0,
      isUnbroken INTEGER NOT NULL DEFAULT 1,
      FOREIGN KEY (inningsId) REFERENCES $innings(id) ON DELETE CASCADE
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS $fallOfWickets (
      id TEXT PRIMARY KEY,
      inningsId TEXT NOT NULL,
      wicketNumber INTEGER NOT NULL,
      score INTEGER NOT NULL,
      totalLegalBalls INTEGER NOT NULL,
      playerId TEXT NOT NULL,
      playerName TEXT NOT NULL,
      FOREIGN KEY (inningsId) REFERENCES $innings(id) ON DELETE CASCADE
    );
    ''',
  ];
}
