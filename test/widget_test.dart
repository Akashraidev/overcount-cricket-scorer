import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scorecard/core/theme/app_theme.dart';
import 'package:scorecard/data/models/team.dart';
import 'package:scorecard/data/models/player.dart';
import 'package:scorecard/data/models/innings.dart';
import 'package:scorecard/data/models/ball.dart';
import 'package:scorecard/data/models/bowling_stat.dart';
import 'package:scorecard/data/models/batting_stat.dart';
import 'package:scorecard/features/scoring/widgets/live_bowler_card.dart';
import 'package:scorecard/features/scoring/widgets/live_batters_card.dart';
import 'package:scorecard/features/scoring/scoring_provider.dart';
import 'package:scorecard/features/scoring/widgets/end_over_dialog.dart';
import 'package:scorecard/core/widgets/app_button.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:scorecard/core/widgets/app_dropdown.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Core Domain Models Smoke Test', () {
    test('Team model serialization', () {
      final team = Team(
        id: 'team_1',
        name: 'India',
        shortName: 'IND',
        colorValue: 0xFF1D4ED8,
        createdAt: 1000,
      );

      final map = team.toMap();
      final fromMap = Team.fromMap(map);
      expect(fromMap.id, 'team_1');
      expect(fromMap.name, 'India');
      expect(fromMap.shortName, 'IND');
    });

    test('Player model serialization', () {
      final player = Player(
        id: 'p_1',
        teamId: 'team_1',
        name: 'Virat Kohli',
        jerseyNumber: 18,
        role: 'Batter',
        isCaptain: true,
        createdAt: 1000,
      );

      final map = player.toMap();
      final fromMap = Player.fromMap(map);
      expect(fromMap.name, 'Virat Kohli');
      expect(fromMap.isCaptain, true);
    });

    test('Innings model calculations', () {
      final inn = Innings(
        id: 'inn_1',
        matchId: 'match_1',
        inningsNumber: 1,
        battingTeamId: 'team_1',
        bowlingTeamId: 'team_2',
        totalRuns: 180,
        totalWickets: 4,
        totalLegalBalls: 120,
        wides: 4,
        noBalls: 1,
        byes: 2,
        legByes: 1,
        createdAt: 1000,
      );

      expect(inn.totalExtras, 8);
      expect(inn.oversDisplay, '20.0');
      expect(inn.currentRunRate, 9.0);
    });

    test('Ball model total runs computation', () {
      final ball = Ball(
        id: 'ball_1',
        matchId: 'match_1',
        inningsId: 'inn_1',
        overNumber: 0,
        ballNumber: 1,
        legalBallNumber: 1,
        bowlerId: 'p_bowl',
        batsmanId: 'p_bat',
        nonStrikerId: 'p_ns',
        runsBat: 4,
        extras: 0,
        timestamp: 1000,
      );

      expect(ball.totalRuns, 4);
      expect(ball.isLegalBall, true);
    });

    testWidgets('Theme definitions smoke test', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(body: SizedBox()),
        ),
      );
      expect(AppTheme.darkTheme.useMaterial3, true);
      expect(AppTheme.lightTheme.useMaterial3, true);
    });
  });

  group('LiveBowlerCard & LiveBattersCard Tests', () {
    final testBowler = Player(
      id: 'b_1',
      teamId: 'team_2',
      name: 'Jasprit Bumrah',
      role: 'Bowler',
      bowlingStyle: 'Right-arm fast',
      createdAt: 1000,
    );

    final testStriker = Player(
      id: 's_1',
      teamId: 'team_1',
      name: 'Rohit Sharma',
      role: 'Batter',
      createdAt: 1000,
    );

    final testNonStriker = Player(
      id: 'ns_1',
      teamId: 'team_1',
      name: 'Virat Kohli',
      role: 'Batter',
      createdAt: 1000,
    );

    testWidgets('LiveBowlerCard shows "+ Add Bowler" and empty state when bowler is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: LiveBowlerCard(
              bowler: null,
              bowlerStat: null,
              onChangeBowler: () {},
            ),
          ),
        ),
      );

      expect(find.text('+ Add Bowler'), findsOneWidget);
      expect(find.text('Tap to Add / Select Bowler'), findsOneWidget);
      expect(find.text('Change Bowler'), findsNothing);
    });

    testWidgets('LiveBowlerCard shows "Change Bowler" and figures when bowler is present', (tester) async {
      final stat = BowlingStat(
        id: 'stat_1',
        inningsId: 'inn_1',
        playerId: testBowler.id,
        playerName: testBowler.name,
        bowlingOrder: 1,
        totalLegalBalls: 6,
        runsConceded: 4,
        wickets: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: LiveBowlerCard(
              bowler: testBowler,
              bowlerStat: stat,
              onChangeBowler: () {},
            ),
          ),
        ),
      );

      expect(find.text('Change Bowler'), findsOneWidget);
      expect(find.text('+ Add Bowler'), findsNothing);
      expect(find.text('Jasprit Bumrah'), findsOneWidget);
      expect(find.text('1.0 - 0 - 4 - 1'), findsOneWidget);
      expect(find.text('Eco: 4.00'), findsOneWidget);
    });

    testWidgets('LiveBattersCard shows empty placeholders when batters are null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: LiveBattersCard(
              striker: null,
              strikerStat: null,
              nonStriker: null,
              nonStrikerStat: null,
              onSwapStrike: () {},
            ),
          ),
        ),
      );

      expect(find.text('No Striker — Tap to Add / Select Striker (*)'), findsOneWidget);
      expect(find.text('No Non-Striker — Tap to Add / Select Non-Striker'), findsOneWidget);
    });

    testWidgets('LiveBattersCard shows batter details and strike indicator when present', (tester) async {
      final strikerStat = BattingStat(
        id: 'bs_1',
        inningsId: 'inn_1',
        playerId: testStriker.id,
        playerName: testStriker.name,
        battingOrder: 1,
        runs: 14,
        balls: 8,
        fours: 2,
        sixes: 1,
      );

      final nonStrikerStat = BattingStat(
        id: 'bs_2',
        inningsId: 'inn_1',
        playerId: testNonStriker.id,
        playerName: testNonStriker.name,
        battingOrder: 2,
        runs: 6,
        balls: 4,
        fours: 1,
        sixes: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: LiveBattersCard(
              striker: testStriker,
              strikerStat: strikerStat,
              nonStriker: testNonStriker,
              nonStrikerStat: nonStrikerStat,
              onSwapStrike: () {},
            ),
          ),
        ),
      );

      expect(find.text('Rohit Sharma *'), findsOneWidget);
      expect(find.text('Virat Kohli'), findsOneWidget);
      expect(find.text('14 (8)'), findsOneWidget);
      expect(find.text('6 (4)'), findsOneWidget);
    });
  });

  group('AppDropdown Resilience Tests', () {
    testWidgets('AppDropdown safely handles values not present in items list without crashing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDropdown<String>(
              label: 'Test Dropdown',
              value: 'non-existent-id-620fe3c5-3908-4671-8d39-98735d7c4227',
              items: const [
                DropdownMenuItem(value: 'id_1', child: Text('Option 1')),
                DropdownMenuItem(value: 'id_2', child: Text('Option 2')),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Successfully renders without throwing DropdownButton assertion failure
      expect(find.text('Test Dropdown'), findsOneWidget);
    });

    testWidgets('AppDropdown deduplicates duplicate item values without throwing assertion error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDropdown<String>(
              label: 'Deduplicated Dropdown',
              value: 'id_1',
              items: const [
                DropdownMenuItem(value: 'id_1', child: Text('Option 1 (First)')),
                DropdownMenuItem(value: 'id_1', child: Text('Option 1 (Duplicate)')),
                DropdownMenuItem(value: 'id_2', child: Text('Option 2')),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Deduplicated Dropdown'), findsOneWidget);
      expect(find.text('Option 1 (First)'), findsOneWidget);
    });

    testWidgets('AppDropdown opens modal bottom sheet and selects option', (tester) async {
      String? selectedValue = 'item_1';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AppDropdown<String>(
                  label: 'Select Captain',
                  value: selectedValue,
                  items: const [
                    DropdownMenuItem(value: 'item_1', child: Text('Rohit Sharma')),
                    DropdownMenuItem(value: 'item_2', child: Text('Virat Kohli')),
                    DropdownMenuItem(value: 'item_3', child: Text('Jasprit Bumrah')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      selectedValue = val;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // Verify dropdown displays the initial label and selected text
      expect(find.text('Select Captain'), findsOneWidget);
      expect(find.text('Rohit Sharma'), findsOneWidget);

      // Tap to open bottom sheet
      await tester.tap(find.text('Rohit Sharma'));
      await tester.pumpAndSettle();

      // Verify bottom sheet appears with header and all options
      expect(find.text('Select Captain'), findsNWidgets(2));
      expect(find.text('Virat Kohli'), findsOneWidget);
      expect(find.text('Jasprit Bumrah'), findsOneWidget);

      // Select 'Virat Kohli'
      await tester.tap(find.text('Virat Kohli'));
      await tester.pumpAndSettle();

      // Modal is dismissed and selected value is updated
      expect(selectedValue, 'item_2');
      expect(find.text('Virat Kohli'), findsOneWidget);
    });

    testWidgets('AppDropdown search filter narrows options in modal bottom sheet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppDropdown<String>(
              label: 'Select City',
              value: null,
              items: const [
                DropdownMenuItem(value: 'mumbai', child: Text('Mumbai')),
                DropdownMenuItem(value: 'delhi', child: Text('Delhi')),
                DropdownMenuItem(value: 'chennai', child: Text('Chennai')),
                DropdownMenuItem(value: 'kolkata', child: Text('Kolkata')),
                DropdownMenuItem(value: 'bengaluru', child: Text('Bengaluru')),
                DropdownMenuItem(value: 'hyderabad', child: Text('Hyderabad')),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Tap dropdown to open bottom sheet (has 6 items, so search bar is enabled)
      await tester.tap(find.text('Select...'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Mumbai'), findsOneWidget);
      expect(find.text('Bengaluru'), findsOneWidget);

      // Enter search query
      await tester.enterText(find.byType(TextField), 'Beng');
      await tester.pumpAndSettle();

      // Only Bengaluru matches
      expect(find.text('Bengaluru'), findsOneWidget);
      expect(find.text('Mumbai'), findsNothing);
    });
  });

  group('Bowler Over Limits and Innings Logic Tests', () {
    test('ScoringProvider bowler limit configuration', () {
      final provider = ScoringProvider();

      // By default without match, fallback is 4
      expect(provider.isUnlimitedBowlerOvers, false);
      expect(provider.maxOversPerBowler, 4);

      // Set unlimited limit (0)
      provider.setMaxOversPerBowler(0);
      expect(provider.isUnlimitedBowlerOvers, true);
      expect(provider.maxOversPerBowler, 0);

      // Set custom limit (5)
      provider.setMaxOversPerBowler(5);
      expect(provider.isUnlimitedBowlerOvers, false);
      expect(provider.maxOversPerBowler, 5);

      // Reset to null
      provider.setMaxOversPerBowler(null);
      expect(provider.isUnlimitedBowlerOvers, false);
    });

    testWidgets('EndOverDialog shows unlimited bowler limit and allows bowler with completed overs', (tester) async {
      final bowler1 = Player(id: 'b1', teamId: 't1', name: 'Bowler 1', role: 'Bowler', createdAt: 1000);
      final bowler2 = Player(id: 'b2', teamId: 't1', name: 'Bowler 2', role: 'Bowler', createdAt: 1000);

      // bowler2 has bowled 6 balls = 1 over
      final stat2 = BowlingStat(
        id: 's2',
        inningsId: 'inn1',
        playerId: 'b2',
        playerName: 'Bowler 2',
        bowlingOrder: 1,
        totalLegalBalls: 6,
        runsConceded: 6,
        wickets: 0,
      );

      bool declareCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: EndOverDialog(
              completedOverNumber: 1,
              previousBowler: bowler1,
              availableBowlers: [bowler1, bowler2],
              bowlingStats: [stat2],
              maxOversPerBowler: 0, // Unlimited
              teamId: 't1',
              onBowlerSelected: (_) {},
              onAddNewBowler: (_, _) async => bowler1,
              onDeclareInnings: () {
                declareCalled = true;
              },
            ),
          ),
        ),
      );

      // Check unlimited badge or indicators
      expect(find.text('Over 1 Finished! 🏏'), findsOneWidget);
      expect(find.text('No Limit'), findsOneWidget);
      expect(find.textContaining('No bowler limit'), findsOneWidget);
      expect(find.text('Bowler 2'), findsOneWidget);

      // In unlimited mode, bowler2 has 1.0 ov shown instead of quota completed
      expect(find.textContaining('1.0 ov'), findsOneWidget);

      // Test declare button
      final declareBtn = find.text('End / Declare Innings Early');
      expect(declareBtn, findsOneWidget);
      await tester.tap(declareBtn);
      await tester.pumpAndSettle();

      expect(declareCalled, true);
    });

    testWidgets('EndOverDialog disables bowler exceeding limit in limited overs mode', (tester) async {
      final bowler1 = Player(id: 'b1', teamId: 't1', name: 'Bowler 1', role: 'Bowler', createdAt: 1000);
      final bowler2 = Player(id: 'b2', teamId: 't1', name: 'Bowler 2', role: 'Bowler', createdAt: 1000);

      // bowler2 has bowled 1 over (6 legal balls)
      final stat2 = BowlingStat(
        id: 's2',
        inningsId: 'inn1',
        playerId: 'b2',
        playerName: 'Bowler 2',
        bowlingOrder: 1,
        totalLegalBalls: 6,
        runsConceded: 8,
        wickets: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: EndOverDialog(
              completedOverNumber: 1,
              previousBowler: bowler1,
              availableBowlers: [bowler1, bowler2],
              bowlingStats: [stat2],
              maxOversPerBowler: 1, // Max 1 over
              teamId: 't1',
              onBowlerSelected: (_) {},
              onAddNewBowler: (_, _) async => bowler1,
              onDeclareInnings: () {},
            ),
          ),
        ),
      );

      // In limited mode with max 1 over, bowler2 has completed quota
      expect(find.textContaining('Max 1 overs/bowler'), findsOneWidget);
      expect(find.text('Max Overs'), findsOneWidget);
    });
  });

  group('AppButton Resilience Tests', () {
    testWidgets('AppButton handles narrow constraints without overflowing Row', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 80,
              child: AppButton(
                label: 'Very Long Action Button Label Exceeding Bound',
                icon: Icons.check,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      // Verify it renders safely without throwing RenderFlex overflow
      expect(find.byType(AppButton), findsOneWidget);
    });
  });
}
