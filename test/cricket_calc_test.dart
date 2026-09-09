import 'package:flutter_test/flutter_test.dart';
import 'package:scorecard/core/utils/commentary_generator.dart';
import 'package:scorecard/core/utils/cricket_calc.dart';

void main() {
  group('Cricket Calculations Tests', () {
    test('ballsToOversString converts balls to standard cricket notation', () {
      expect(CricketCalc.ballsToOversString(0), '0.0');
      expect(CricketCalc.ballsToOversString(1), '0.1');
      expect(CricketCalc.ballsToOversString(6), '1.0');
      expect(CricketCalc.ballsToOversString(15), '2.3');
      expect(CricketCalc.ballsToOversString(93), '15.3');
      expect(CricketCalc.ballsToOversString(120), '20.0');
    });

    test('oversStringToBalls converts overs notation back to legal balls count', () {
      expect(CricketCalc.oversStringToBalls('0.0'), 0);
      expect(CricketCalc.oversStringToBalls('1.0'), 6);
      expect(CricketCalc.oversStringToBalls('15.3'), 93);
      expect(CricketCalc.oversStringToBalls('20.0'), 120);
    });

    test('calculateCRR calculates current run rate accurately', () {
      // 120 runs in 15 overs = 8.00
      expect(CricketCalc.calculateCRR(120, 90), 8.0);
      // 150 runs in 20 overs = 7.50
      expect(CricketCalc.calculateCRR(150, 120), 7.5);
      // 0 balls faced = 0.0
      expect(CricketCalc.calculateCRR(0, 0), 0.0);
    });

    test('calculateRRR calculates required run rate accurately', () {
      // Need 50 runs from 5 overs (30 balls) -> 10.00
      final rrr = CricketCalc.calculateRRR(
        targetRuns: 200,
        currentRuns: 150,
        totalMatchBalls: 120,
        currentLegalBalls: 90,
      );
      expect(rrr, 10.0);

      // Target already achieved -> 0.0
      final rrrAchieved = CricketCalc.calculateRRR(
        targetRuns: 150,
        currentRuns: 152,
        totalMatchBalls: 120,
        currentLegalBalls: 90,
      );
      expect(rrrAchieved, 0.0);
    });

    test('calculateStrikeRate computes batsman SR', () {
      // 50 runs in 25 balls = 200.0
      expect(CricketCalc.calculateStrikeRate(50, 25), 200.0);
      // 0 balls = 0.0
      expect(CricketCalc.calculateStrikeRate(0, 0), 0.0);
      // 100 runs in 80 balls = 125.0
      expect(CricketCalc.calculateStrikeRate(100, 80), 125.0);
    });

    test('calculateEconomy computes bowler economy', () {
      // 24 runs in 4 overs (24 balls) = 6.00
      expect(CricketCalc.calculateEconomy(24, 24), 6.0);
      // 36 runs in 3 overs (18 balls) = 12.00
      expect(CricketCalc.calculateEconomy(36, 18), 12.0);
    });

    test('calculateNRR computes Net Run Rate', () {
      // Team scored 200 in 20 ov (10.0), conceded 160 in 20 ov (8.0) -> +2.0
      final nrr = CricketCalc.calculateNRR(
        runsScored: 200,
        ballsFaced: 120,
        runsConceded: 160,
        ballsBowled: 120,
      );
      expect(nrr, 2.0);
      expect(CricketCalc.formatNRR(nrr), '+2.000');
    });

    test('CommentaryGenerator creates descriptive commentary', () {
      final comm4 = CommentaryGenerator.generateCommentary(
        bowlerName: 'Starc',
        batsmanName: 'Rohit',
        runs: 4,
        extraType: 'none',
        extraRuns: 0,
        isWicket: false,
      );
      expect(comm4.isNotEmpty, true);

      final commWkt = CommentaryGenerator.generateCommentary(
        bowlerName: 'Bumrah',
        batsmanName: 'Head',
        runs: 0,
        extraType: 'none',
        extraRuns: 0,
        isWicket: true,
        wicketType: 'bowled',
      );
      expect(commWkt.contains('Bumrah') || commWkt.contains('Rohit') || commWkt.contains('Head') || commWkt.contains('OUT'), true);
    });
  });
}
