import 'package:flutter_test/flutter_test.dart';
import 'package:scorecard/core/utils/cricket_calc.dart';
import 'package:scorecard/data/models/match.dart';

void main() {
  group('10 Overs Match & Quota Tests', () {
    test('10 overs match has 60 legal balls total', () {
      const totalOvers = 10;
      const ballsPerOver = 6;
      final maxBalls = totalOvers * ballsPerOver;

      expect(maxBalls, 60);
      expect(CricketCalc.ballsToOversString(maxBalls), '10.0');
    });

    test('10 overs match bowler quota is ceil(10 / 5) = 2 overs max', () {
      final match = CricketMatch(
        id: 'test_m1',
        title: 'T10 Final',
        venue: 'Stadium',
        matchDate: 1700000000000,
        format: 'T10',
        totalOvers: 10,
        teamAId: 'team1',
        teamBId: 'team2',
        createdAt: 1700000000000,
      );

      final maxOversPerBowler = (match.totalOvers / 5).ceil();
      expect(maxOversPerBowler, 2);

      // Bowler with 12 balls has completed 2 overs -> quota exhausted
      const bowlerBalls = 12;
      final completedOvers = bowlerBalls ~/ match.ballsPerOver;
      expect(completedOvers >= maxOversPerBowler, true);

      // Bowler with 6 balls has completed 1 over -> quota remaining
      const bowlerBalls1 = 6;
      final completedOvers1 = bowlerBalls1 ~/ match.ballsPerOver;
      expect(completedOvers1 >= maxOversPerBowler, false);
    });

    test('Legal ball 60 marks exactly 10.0 overs completed', () {
      const currentLegalBalls = 59;
      expect(CricketCalc.ballsToOversString(currentLegalBalls), '9.5');

      const nextLegalBall = 60;
      expect(CricketCalc.ballsToOversString(nextLegalBall), '10.0');

      // Beyond 60 is strictly invalid for a 10 over match
      const maxBalls = 10 * 6;
      expect(nextLegalBall >= maxBalls, true);
    });

    test('Target calculation for 1st innings score of 85', () {
      const runs = 85;
      const target = runs + 1;
      expect(target, 86);

      final rrr = CricketCalc.calculateRRR(
        targetRuns: target,
        currentRuns: 0,
        totalMatchBalls: 60,
        currentLegalBalls: 0,
      );
      // 86 runs in 10 overs = 8.60 RPO
      expect(rrr, 8.6);
    });
  });
}
