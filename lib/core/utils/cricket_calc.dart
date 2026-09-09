class CricketCalc {
  CricketCalc._();

  /// Converts total legal balls to standard overs display (e.g., 93 balls -> "15.3")
  static String ballsToOversString(int totalBalls, {int ballsPerOver = 6}) {
    if (totalBalls <= 0) return '0.0';
    final overs = totalBalls ~/ ballsPerOver;
    final balls = totalBalls % ballsPerOver;
    return '$overs.$balls';
  }

  /// Converts standard overs decimal notation (e.g. 15.3) to total legal balls
  static int oversStringToBalls(String oversStr, {int ballsPerOver = 6}) {
    final parts = oversStr.split('.');
    if (parts.isEmpty) return 0;
    final overs = int.tryParse(parts[0]) ?? 0;
    final balls = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return (overs * ballsPerOver) + balls;
  }

  /// Decimal overs for rate calculations (e.g. 15.3 overs = 15.5)
  static double ballsToDecimalOvers(int totalBalls, {int ballsPerOver = 6}) {
    if (totalBalls <= 0) return 0.0;
    return totalBalls / ballsPerOver;
  }

  /// Current Run Rate (CRR)
  static double calculateCRR(int totalRuns, int totalLegalBalls, {int ballsPerOver = 6}) {
    if (totalLegalBalls <= 0) return 0.0;
    final decimalOvers = ballsToDecimalOvers(totalLegalBalls, ballsPerOver: ballsPerOver);
    if (decimalOvers <= 0) return 0.0;
    return totalRuns / decimalOvers;
  }

  /// Required Run Rate (RRR)
  static double calculateRRR({
    required int targetRuns,
    required int currentRuns,
    required int totalMatchBalls,
    required int currentLegalBalls,
    int ballsPerOver = 6,
  }) {
    final runsNeeded = targetRuns - currentRuns;
    final ballsRemaining = totalMatchBalls - currentLegalBalls;
    if (runsNeeded <= 0) return 0.0;
    if (ballsRemaining <= 0) return 99.99;
    final decimalOversRemaining = ballsRemaining / ballsPerOver;
    return runsNeeded / decimalOversRemaining;
  }

  /// Batsman Strike Rate
  static double calculateStrikeRate(int runs, int balls) {
    if (balls <= 0) return 0.0;
    return (runs / balls) * 100.0;
  }

  /// Bowler Economy Rate
  static double calculateEconomy(int runsConceded, int totalBallsBowled, {int ballsPerOver = 6}) {
    if (totalBallsBowled <= 0) return 0.0;
    final decimalOvers = ballsToDecimalOvers(totalBallsBowled, ballsPerOver: ballsPerOver);
    if (decimalOvers <= 0) return 0.0;
    return runsConceded / decimalOvers;
  }

  /// Net Run Rate (NRR) = (Runs Scored / Overs Faced) - (Runs Conceded / Overs Bowled)
  static double calculateNRR({
    required int runsScored,
    required int ballsFaced,
    required int runsConceded,
    required int ballsBowled,
    int ballsPerOver = 6,
  }) {
    final oversFacedDec = ballsFaced > 0 ? (ballsFaced / ballsPerOver) : 0.0;
    final oversBowledDec = ballsBowled > 0 ? (ballsBowled / ballsPerOver) : 0.0;

    final forRate = oversFacedDec > 0 ? (runsScored / oversFacedDec) : 0.0;
    final againstRate = oversBowledDec > 0 ? (runsConceded / oversBowledDec) : 0.0;

    return forRate - againstRate;
  }

  /// Format NRR string with sign (e.g. +1.450 or -0.820)
  static String formatNRR(double nrr) {
    final sign = nrr > 0 ? '+' : '';
    return '$sign${nrr.toStringAsFixed(3)}';
  }
}
