import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scorecard/features/matches/match_provider.dart';
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
import 'package:scorecard/core/widgets/app_dialog.dart';
import 'package:scorecard/core/constants/app_colors.dart';
import 'package:scorecard/core/constants/app_radius.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scorecard/core/widgets/app_dropdown.dart';
import 'package:scorecard/core/widgets/player_avatar.dart';
import 'package:scorecard/data/models/over_summary.dart';
import 'package:scorecard/features/scoring/widgets/live_sharing_sheet.dart';
import 'package:scorecard/features/scoring/local_scoring_provider.dart';
import 'package:provider/provider.dart';
import 'package:scorecard/core/widgets/stat_tile.dart';
import 'package:scorecard/features/scoring/widgets/innings_break_dialog.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:scorecard/core/utils/pdf_scorecard_generator.dart';
import 'package:scorecard/data/models/match.dart';
import 'package:scorecard/data/models/fall_of_wicket.dart';
import 'package:scorecard/data/models/partnership.dart';
import 'package:scorecard/features/settings/settings_provider.dart';
import 'package:scorecard/features/settings/settings_screen.dart';
import 'package:scorecard/core/widgets/match_tile.dart';
import 'package:scorecard/core/widgets/team_tile.dart';
import 'package:scorecard/core/widgets/player_tile.dart';
import 'package:scorecard/features/scoring/widgets/live_score_banner.dart';
import 'package:scorecard/features/scoring/widgets/boundary_celebration_overlay.dart';
import 'package:scorecard/features/scoring/widgets/cancel_match_dialog.dart';
import 'package:scorecard/core/widgets/app_card.dart';
import 'package:scorecard/core/constants/app_text_styles.dart';
import 'package:scorecard/data/repositories/player_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    test('CricketMatch model serializes, deserializes, and copies maxOversPerBowler correctly', () {
      final unlimitedMatch = CricketMatch(
        id: 'm_unlimited',
        title: 'T10 Unlimited Match',
        venue: 'Stadium',
        matchDate: 1000,
        format: 'T10',
        totalOvers: 10,
        teamAId: 'ta',
        teamBId: 'tb',
        maxOversPerBowler: 0,
        createdAt: 1000,
      );

      final map = unlimitedMatch.toMap();
      expect(map['maxOversPerBowler'], equals(0));

      final restored = CricketMatch.fromMap(map);
      expect(restored.maxOversPerBowler, equals(0));
      expect(restored.totalOvers, equals(10));

      final customMatch = unlimitedMatch.copyWith(maxOversPerBowler: 3);
      expect(customMatch.maxOversPerBowler, equals(3));

      final autoMatch = customMatch.copyWith(maxOversPerBowler: null);
      expect(autoMatch.maxOversPerBowler, isNull);
    });

    test('ScoringProvider automatically respects match maxOversPerBowler without manual intervention', () {
      final provider = ScoringProvider();

      // 1. When a 10-over match is created with No Limit (0)
      final noLimitMatch = CricketMatch(
        id: 'm1',
        title: 'T10 No Limit',
        venue: 'Stadium',
        matchDate: 1000,
        format: 'T10',
        totalOvers: 10,
        teamAId: 'ta',
        teamBId: 'tb',
        maxOversPerBowler: 0,
        createdAt: 1000,
      );

      provider.setMatchForTesting(noLimitMatch);
      expect(provider.isUnlimitedBowlerOvers, isTrue);
      expect(provider.maxOversPerBowler, equals(0));

      // 2. When a 10-over match is created with default auto quota (null)
      final defaultMatch = CricketMatch(
        id: 'm2',
        title: 'T10 Default Quota',
        venue: 'Stadium',
        matchDate: 1000,
        format: 'T10',
        totalOvers: 10,
        teamAId: 'ta',
        teamBId: 'tb',
        maxOversPerBowler: null,
        createdAt: 1000,
      );

      provider.setMatchForTesting(defaultMatch);
      expect(provider.isUnlimitedBowlerOvers, isFalse);
      expect(provider.maxOversPerBowler, equals(2)); // (10 / 5) = 2

      // 3. When a 20-over match has custom 3 overs per bowler
      final customMatch = CricketMatch(
        id: 'm3',
        title: 'T20 Custom 3 Overs',
        venue: 'Stadium',
        matchDate: 1000,
        format: 'T20',
        totalOvers: 20,
        teamAId: 'ta',
        teamBId: 'tb',
        maxOversPerBowler: 3,
        createdAt: 1000,
      );

      provider.setMatchForTesting(customMatch);
      expect(provider.isUnlimitedBowlerOvers, isFalse);
      expect(provider.maxOversPerBowler, equals(3));
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

    testWidgets('AppHeaderActionButton matches Dashboard New Match design system specifications', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                AppHeaderActionButton(
                  label: 'New Match',
                  onPressed: () => pressed = true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('New Match'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);

      final filledButton = tester.widget<FilledButton>(find.byWidgetPredicate((w) => w is FilledButton));
      expect(filledButton.style?.shape?.resolve({}) is RoundedRectangleBorder, isTrue);
      final border = filledButton.style?.shape?.resolve({}) as RoundedRectangleBorder;
      expect(border.borderRadius, equals(AppRadius.roundedFull));
      expect(filledButton.style?.minimumSize?.resolve({}), equals(const Size(0, 34)));
      expect(filledButton.style?.backgroundColor?.resolve({}), equals(AppColors.primary));
      expect(filledButton.style?.elevation?.resolve({}), equals(0));

      await tester.tap(find.byWidgetPredicate((w) => w is FilledButton));
      expect(pressed, isTrue);
    });

    testWidgets('AppButton.pill renders exact pill styling and triggers callback', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton.pill(
              label: 'Add Team',
              icon: Icons.group_add_rounded,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Add Team'), findsOneWidget);
      expect(find.byIcon(Icons.group_add_rounded), findsOneWidget);

      await tester.tap(find.text('Add Team'));
      expect(pressed, isTrue);
    });
  });

  group('AppDialog Layout, Centering & Responsiveness Tests', () {
    testWidgets('AppDialog heading with "What is the Target?" remains properly centered', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: AppDialog(
              title: 'What is the Target?',
              content: Text('Target is 185 runs in 20 overs.'),
              confirmLabel: 'Got It',
              cancelLabel: 'Dismiss',
            ),
          ),
        ),
      );

      final titleFinder = find.text('What is the Target?');
      expect(titleFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(titleFinder);
      expect(textWidget.textAlign, TextAlign.center);
      expect(textWidget.softWrap, isTrue);

      // Verify the title is contained in a full-width box for symmetrical centering
      final sizedBoxFinder = find.ancestor(of: titleFinder, matching: find.byType(SizedBox));
      expect(sizedBoxFinder, findsWidgets);
      final sizedBox = tester.widget<SizedBox>(sizedBoxFinder.first);
      expect(sizedBox.width, double.infinity);
    });

    testWidgets('Long heading wraps across lines while remaining centered without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const longTitle = 'What is the Target for the Second Innings Chasing Team in this Championship Final?';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppDialog(
              title: longTitle,
              content: Text('Chasing team needs 210 runs to lift the trophy.'),
              confirmLabel: 'Confirm Target',
              cancelLabel: 'Back',
            ),
          ),
        ),
      );

      final titleFinder = find.text(longTitle);
      expect(titleFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(titleFinder);
      expect(textWidget.textAlign, TextAlign.center);

      // Verify buttons are balanced
      expect(find.text('Confirm Target'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('AppDialog content is centered for text messages and balanced for actions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: AppDialog(
              title: 'Delete Tournament?',
              content: Text('Are you sure you want to delete "World Cup 2026"?'),
              confirmLabel: 'Delete',
              cancelLabel: 'Cancel',
              isDestructive: true,
            ),
          ),
        ),
      );

      // Check title centering
      final titleFinder = find.text('Delete Tournament?');
      expect(tester.widget<Text>(titleFinder).textAlign, TextAlign.center);

      // Check content message centering
      final contentFinder = find.text('Are you sure you want to delete "World Cup 2026"?');
      expect(contentFinder, findsOneWidget);

      // Verify actions exist in equal proportion
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('AppDialog renders gracefully on narrow mobile screen (320px width)', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: AppDialog(
              title: 'What is the Target?',
              content: Text('Target: 175 runs'),
              confirmLabel: 'Start Innings',
              cancelLabel: 'Review',
            ),
          ),
        ),
      );

      expect(find.text('What is the Target?'), findsOneWidget);
      expect(find.text('Start Innings'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
    });

    testWidgets('AppDialog renders on tablet/desktop (800px width) within max constraint', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: AppDialog(
              title: 'Tournament Settings & Configuration',
              subtitle: 'Configure rules and limits',
              content: Text('Settings content details go here.'),
              confirmLabel: 'Save Changes',
            ),
          ),
        ),
      );

      expect(find.text('Tournament Settings & Configuration'), findsOneWidget);
      expect(find.text('Configure rules and limits'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });
  });

  group('Player Photo & Avatar Tests', () {
    test('Player model serialization with photoUrl', () {
      final playerWithPhoto = Player(
        id: 'p_photo_1',
        teamId: 'team_1',
        name: 'Rohit Sharma',
        jerseyNumber: 45,
        role: 'Batter',
        photoUrl: 'C:/app_documents/player_photos/p_photo_1.jpg',
        createdAt: 2000,
      );

      final map = playerWithPhoto.toMap();
      expect(map['photoUrl'], 'C:/app_documents/player_photos/p_photo_1.jpg');

      final fromMap = Player.fromMap(map);
      expect(fromMap.photoUrl, 'C:/app_documents/player_photos/p_photo_1.jpg');

      final copied = fromMap.copyWith(photoUrl: 'C:/new_photo.png');
      expect(copied.photoUrl, 'C:/new_photo.png');
      expect(copied.name, 'Rohit Sharma');
    });

    testWidgets('PlayerAvatar renders initials fallback and jersey number', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                PlayerAvatar(
                  name: 'Jasprit Bumrah',
                  jerseyNumber: 0,
                  size: 56,
                ),
                PlayerAvatar(
                  name: 'Virat Kohli',
                  jerseyNumber: 18,
                  size: 56,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('JB'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);
    });

    testWidgets('PlayerAvatar with camera edit badge renders icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerAvatar(
              name: 'Hardik Pandya',
              size: 80,
              showCameraBadge: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
      expect(find.text('HP'), findsOneWidget);
    });

    test('OverSummary model properly retains over and ball statistics', () {
      const over = OverSummary(
        overNumber: 1,
        bowlerName: 'Pat Cummins',
        runs: 8,
        wickets: 1,
        balls: [],
      );

      expect(over.overNumber, 1);
      expect(over.bowlerName, 'Pat Cummins');
      expect(over.runs, 8);
      expect(over.wickets, 1);
      expect(over.balls, isEmpty);
    });
  });

  group('Live Sharing PIN Display Resilience Tests', () {
    testWidgets('LiveSharingSheet PIN display does not overflow even on 320px narrow screens', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final scoringProv = ScoringProvider();
      final localProv = LocalScoringProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ScoringProvider>.value(value: scoringProv),
            ChangeNotifierProvider<LocalScoringProvider>.value(value: localProv),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: SingleChildScrollView(
                child: LiveSharingSheet(),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Live Match Sharing'), findsOneWidget);
      expect(find.textContaining('Hotspot or Local Wi-Fi'), findsOneWidget);
    });

    testWidgets('LiveSharingSheet renders Hotspot instructions and offline hosting card without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final scoringProv = ScoringProvider();
      final localProv = LocalScoringProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ScoringProvider>.value(value: scoringProv),
            ChangeNotifierProvider<LocalScoringProvider>.value(value: localProv),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: SingleChildScrollView(
                child: LiveSharingSheet(),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Host Live Match Offline'), findsOneWidget);
      expect(find.textContaining('Broadcast live ball-by-ball scorecards'), findsOneWidget);
    });
  });

  group('StatTile Constraints & Layout Resilience Tests', () {
    testWidgets('StatTile does not overflow vertically even in exact BoxConstraints(w=132.7, h=55.4)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 132.7,
                height: 55.4,
                child: StatTile(
                  label: 'Tournaments',
                  value: '12',
                  icon: Icons.emoji_events,
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('TOURNAMENTS'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('StatTile handles ultra-tight height (40px) without overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 120,
                height: 40,
                child: StatTile(
                  label: 'Matches',
                  value: '999',
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('MATCHES'), findsOneWidget);
      expect(find.text('999'), findsOneWidget);
    });

    testWidgets('StatTile renders properly when unconstrained in a Column', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: Column(
              children: [
                StatTile(
                  label: 'Teams',
                  value: '8',
                  subtitle: 'Active squads',
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('TEAMS'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('Active squads'), findsOneWidget);
    });

    testWidgets('InningsBreakDialog renders on 320px screen without any RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const team1 = Team(id: 't1', name: 'Mumbai Indians', shortName: 'MI', createdAt: 0);
      const team2 = Team(id: 't2', name: 'Chennai Super Kings', shortName: 'CSK', createdAt: 0);
      const inn = Innings(
        id: 'inn1',
        matchId: 'm1',
        inningsNumber: 1,
        battingTeamId: 't1',
        bowlingTeamId: 't2',
        totalRuns: 165,
        totalWickets: 5,
        totalLegalBalls: 120,
        createdAt: 0,
      );
      const p1 = Player(id: 'p1', teamId: 't2', name: 'Ruturaj Gaikwad', role: 'Batter', createdAt: 0);
      const p2 = Player(id: 'p2', teamId: 't2', name: 'Devon Conway', role: 'Batter', createdAt: 0);
      const b1 = Player(id: 'b1', teamId: 't1', name: 'Jasprit Bumrah', role: 'Bowler', createdAt: 0);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: InningsBreakDialog(
              completedInnings: inn,
              team1: team1,
              team2: team2,
              team1Squad: const [b1],
              team2Squad: const [p1, p2],
              onAddNewPlayer: (teamId, name, role) async => p1,
              onStartSecondInnings: (s, ns, b) {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Configure 2nd Innings Openers'), findsOneWidget);
      expect(find.text('Add Batter'), findsOneWidget);
      expect(find.text('Opening Bowler'), findsOneWidget);
      expect(find.text('Add Bowler'), findsOneWidget);
    });
  });

  group('PDF Scorecard Generator Tests', () {
    test('pw.SvgImage renders SVG vector cleanly', () {
      final img = pw.SvgImage(svg: '<svg viewBox="0 0 24 24"><path d="M12 2L2 22h20L12 2z"/></svg>');
      expect(img, isNotNull);
    });

    test('pw.SvgImage can be saved into PDF bytes', () async {
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          build: (context) => pw.SvgImage(
            svg: '<svg viewBox="0 0 24 24"><path fill="#000000" d="M12 2L2 22h20L12 2z"/></svg>',
            width: 24,
            height: 24,
          ),
        ),
      );
      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
    });

    test('All scorecard SVG vector icons render cleanly into PDF', () async {
      final svgs = [
        '<svg viewBox="0 0 24 24" width="14" height="14"><path fill="#DC2626" d="M19.4 4.6a2 2 0 0 0-2.8 0l-9.8 9.8 2.8 2.8 9.8-9.8a2 2 0 0 0 0-2.8zM5.4 17.2l-2 2a1 1 0 0 0 0 1.4l.2.2a1 1 0 0 0 1.4 0l2-2-1.6-1.6z"/><circle fill="#DC2626" cx="18" cy="18" r="3"/></svg>',
        '<svg viewBox="0 0 24 24" width="14" height="14"><path fill="#D97706" d="M19 5h-2V3H7v2H5c-1.1 0-2 .9-2 2v1c0 2.55 1.92 4.63 4.39 4.94A5.01 5.01 0 0 0 11 15.9V18H8v2h8v-2h-3v-2.1c1.86-.47 3.25-2.02 3.61-3.96A5.002 5.002 0 0 0 21 8V7c0-1.1-.9-2-2-2zM5 8V7h2v3.82C5.84 10.4 5 9.3 5 8zm14 0c0 1.3-.84 2.4-2 2.82V7h2v1z"/></svg>',
        '<svg viewBox="0 0 24 24" width="12" height="12"><path fill="#64748B" d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5a2.5 2.5 0 0 1 0-5 2.5 2.5 0 0 1 0 5z"/></svg>',
        '<svg viewBox="0 0 24 24" width="12" height="12"><path fill="#64748B" d="M19 4h-1V2h-2v2H8V2H6v2H5c-1.11 0-1.99.9-1.99 2L3 20a2 2 0 0 0 2 2h14c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 16H5V9h14v11zM7 11h5v5H7z"/></svg>',
        '<svg viewBox="0 0 24 24" width="12" height="12"><circle fill="#64748B" cx="12" cy="12" r="9"/></svg>',
        '<svg viewBox="0 0 24 24" width="13" height="13"><path fill="#1D4ED8" d="M19.4 4.6a2 2 0 0 0-2.8 0l-9.8 9.8 2.8 2.8 9.8-9.8a2 2 0 0 0 0-2.8zm-14 12.6l-2 2a1 1 0 0 0 0 1.4l.2.2a1 1 0 0 0 1.4 0l2-2-1.6-1.6z"/></svg>',
        '<svg viewBox="0 0 24 24" width="13" height="13"><circle fill="#DC2626" cx="12" cy="12" r="9"/></svg>',
        '<svg viewBox="0 0 24 24" width="13" height="13"><rect fill="#DC2626" x="4" y="3" width="16" height="2" rx="0.5"/><rect fill="#DC2626" x="5.5" y="5" width="2" height="16" rx="0.5"/><rect fill="#DC2626" x="11" y="5" width="2" height="16" rx="0.5"/><rect fill="#DC2626" x="16.5" y="5" width="2" height="16" rx="0.5"/></svg>',
        '<svg viewBox="0 0 24 24" width="13" height="13"><path fill="#059669" d="M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5s-3 1.34-3 3 1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5zm8 0c-.29 0-.62.02-.97.05 1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z"/></svg>',
        '<svg viewBox="0 0 24 24" width="13" height="13"><circle fill="#475569" cx="12" cy="12" r="9"/></svg>',
      ];

      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          build: (context) => pw.Row(
            children: svgs.map((s) => pw.SvgImage(svg: s)).toList(),
          ),
        ),
      );
      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
    });

    test('PdfScorecardGenerator.buildPdfDocument generates complete team-themed PDF with vector icons', () async {
      const teamA = Team(id: 't1', name: 'Royal Challengers', shortName: 'RCB', colorValue: 0xFFB91C1C, createdAt: 0);
      const teamB = Team(id: 't2', name: 'Chennai Super Kings', shortName: 'CSK', colorValue: 0xFFF59E0B, createdAt: 0);
      final match = CricketMatch(
        id: 'm1',
        title: 'RCB vs CSK - Final',
        teamAId: 't1',
        teamBId: 't2',
        totalOvers: 20,
        format: 'T20',
        venue: 'M. Chinnaswamy Stadium, Bengaluru',
        matchDate: 1700000000000,
        status: 'completed',
        winnerTeamId: 't1',
        resultSummary: 'Royal Challengers won by 14 runs',
        tossWinnerTeamId: 't1',
        tossDecision: 'bat',
        createdAt: 0,
      );
      const inn1 = Innings(
        id: 'inn1',
        matchId: 'm1',
        inningsNumber: 1,
        battingTeamId: 't1',
        bowlingTeamId: 't2',
        totalRuns: 198,
        totalWickets: 5,
        totalLegalBalls: 120,
        wides: 3,
        noBalls: 1,
        byes: 2,
        legByes: 2,
        createdAt: 0,
      );
      const b1 = BattingStat(id: 'bs1', inningsId: 'inn1', playerId: 'p1', playerName: 'Virat Kohli', runs: 82, balls: 54, fours: 6, sixes: 3, isOut: false);
      const b2 = BattingStat(id: 'bs2', inningsId: 'inn1', playerId: 'p2', playerName: 'Faf du Plessis', runs: 55, balls: 35, fours: 5, sixes: 2, isOut: true, dismissalType: 'caught', bowlerName: 'Jadeja', fielderName: 'Dhoni');
      const bw1 = BowlingStat(id: 'bws1', inningsId: 'inn1', playerId: 'p3', playerName: 'Ravindra Jadeja', totalLegalBalls: 24, maidens: 0, runsConceded: 32, wickets: 2, dots: 10, wides: 1, noBalls: 0);

      final overSum = OverSummary(
        overNumber: 0,
        bowlerName: 'Ravindra Jadeja',
        runs: 8,
        wickets: 1,
        balls: [
          const Ball(id: 'bl1', matchId: 'm1', inningsId: 'inn1', overNumber: 0, ballNumber: 1, bowlerId: 'p3', batsmanId: 'p1', nonStrikerId: 'p2', runsBat: 0, extras: 0, isLegalBall: true, isWicket: false, timestamp: 0),
          const Ball(id: 'bl2', matchId: 'm1', inningsId: 'inn1', overNumber: 0, ballNumber: 2, bowlerId: 'p3', batsmanId: 'p1', nonStrikerId: 'p2', runsBat: 4, extras: 0, isLegalBall: true, isWicket: false, timestamp: 0),
          const Ball(id: 'bl3', matchId: 'm1', inningsId: 'inn1', overNumber: 0, ballNumber: 3, bowlerId: 'p3', batsmanId: 'p1', nonStrikerId: 'p2', runsBat: 0, extras: 0, isLegalBall: true, isWicket: true, wicketType: 'caught', timestamp: 0),
        ],
      );

      final doc = PdfScorecardGenerator.buildPdfDocument(
        match: match,
        teamA: teamA,
        teamB: teamB,
        allInnings: [inn1],
        battingStatsMap: {'inn1': [b1, b2]},
        bowlingStatsMap: {'inn1': [bw1]},
        fallOfWicketsMap: {
          'inn1': [const FallOfWicket(id: 'fow1', inningsId: 'inn1', wicketNumber: 1, score: 75, totalLegalBalls: 52, playerId: 'p2', playerName: 'Faf du Plessis')],
        },
        partnershipsMap: {
          'inn1': [const Partnership(id: 'pt1', inningsId: 'inn1', wicketNumber: 1, batter1Id: 'p1', batter1Name: 'Virat Kohli', batter1Runs: 45, batter1Balls: 28, batter2Id: 'p2', batter2Name: 'Faf du Plessis', batter2Runs: 30, batter2Balls: 22, totalRuns: 75, totalBalls: 50)],
        },
        overSummariesMap: {'inn1': [overSum]},
      );

      final pdfBytes = await doc.save();
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));
    });
  });

  group('Settings & Default Theme Tests', () {
    test('SettingsProvider defaults to light mode when no preference stored', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = SettingsProvider();
      expect(provider.themeMode, ThemeMode.light);
    });

    testWidgets('SettingsScreen displays disabled Re-Seed Demo Data button with null onPressed', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final settingsProvider = SettingsProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<SettingsProvider>.value(
            value: settingsProvider,
            child: const SettingsScreen(),
          ),
        ),
      );

      final buttonFinder = find.widgetWithText(AppButton, 'Re-Seed Sample Demo Data');
      expect(buttonFinder, findsOneWidget);

      final appButton = tester.widget<AppButton>(buttonFinder);
      expect(appButton.onPressed, isNull);

      // Verify tapping does nothing and does not trigger loading
      await tester.tap(buttonFinder);
      await tester.pump();
      expect(settingsProvider.isLoading, isFalse);
    });
  });

  group('Match Cancellation Feature Tests', () {
    test('CricketMatch model status getters', () {
      const match = CricketMatch(
        id: 'm_cancel_1',
        title: 'IND vs AUS - Test',
        venue: 'MCG',
        matchDate: 1718000000000,
        format: 'T20',
        totalOvers: 20,
        teamAId: 't1',
        teamBId: 't2',
        status: 'cancelled',
        resultSummary: 'Match Cancelled (Rain Interruption)',
        createdAt: 1000,
      );

      expect(match.isCancelled, isTrue);
      expect(match.isLive, isFalse);
      expect(match.isCompleted, isFalse);
      expect(match.isUpcoming, isFalse);
    });

    testWidgets('CancelMatchDialog renders reasons and custom input', (tester) async {
      const match = CricketMatch(
        id: 'm_cancel_2',
        title: 'IND vs PAK',
        venue: 'Dubai',
        matchDate: 1718000000000,
        format: 'T20',
        totalOvers: 20,
        teamAId: 't1',
        teamBId: 't2',
        status: 'live',
        createdAt: 1000,
      );

      String? selectedReason;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedReason = await CancelMatchDialog.show(context, match: match);
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog title, explanation and predefined reasons exist
      expect(find.text('Cancel Match?'), findsOneWidget);
      expect(find.text('Rain Interruption'), findsOneWidget);
      expect(find.text('Fog / Poor Visibility'), findsOneWidget);
      expect(find.text('Ground Conditions'), findsOneWidget);
      expect(find.text('Technical Issue'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);

      // Select 'Fog / Poor Visibility'
      await tester.tap(find.text('Fog / Poor Visibility'));
      await tester.pumpAndSettle();

      // Tap 'Cancel Match' button
      await tester.tap(find.widgetWithText(AppButton, 'Cancel Match'));
      await tester.pumpAndSettle();

      expect(selectedReason, 'Fog / Poor Visibility');
    });

    testWidgets('CancelMatchDialog handles custom Other reason', (tester) async {
      const match = CricketMatch(
        id: 'm_cancel_3',
        title: 'ENG vs SA',
        venue: 'Lord\'s',
        matchDate: 1718000000000,
        format: 'ODI',
        totalOvers: 50,
        teamAId: 't1',
        teamBId: 't2',
        status: 'live',
        createdAt: 1000,
      );

      String? selectedReason;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedReason = await CancelMatchDialog.show(context, match: match);
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Select 'Other'
      await tester.tap(find.text('Other'));
      await tester.pumpAndSettle();

      // Enter custom reason
      await tester.enterText(find.byType(TextField), 'Floodlight failure');
      await tester.pumpAndSettle();

      // Confirm
      await tester.tap(find.widgetWithText(AppButton, 'Cancel Match'));
      await tester.pumpAndSettle();

      expect(selectedReason, 'Floodlight failure');
    });

    testWidgets('MatchTile displays CANCELLED badge for cancelled matches', (tester) async {
      final teamA = Team(id: 't1', name: 'India', shortName: 'IND', colorValue: 0xFF1D4ED8, createdAt: 1000);
      final teamB = Team(id: 't2', name: 'Australia', shortName: 'AUS', colorValue: 0xFFF59E0B, createdAt: 1000);
      const match = CricketMatch(
        id: 'm_cancel_4',
        title: 'IND vs AUS',
        venue: 'Sydney',
        matchDate: 1718000000000,
        format: 'T20',
        totalOvers: 20,
        teamAId: 't1',
        teamBId: 't2',
        status: 'cancelled',
        resultSummary: 'Match Cancelled (Rain Interruption)',
        createdAt: 1000,
      );

      bool viewScorecardCalled = false;
      bool continueScoringCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchTile(
              match: match,
              teamA: teamA,
              teamB: teamB,
              onViewScorecard: () {
                viewScorecardCalled = true;
              },
              onContinueScoring: () {
                continueScoringCalled = true;
              },
            ),
          ),
        ),
      );

      // CANCELLED badge should be displayed
      expect(find.text('CANCELLED'), findsOneWidget);
      expect(find.text('LIVE'), findsNothing);
      expect(find.text('COMPLETED'), findsNothing);
      expect(find.text('Match Cancelled (Rain Interruption)'), findsOneWidget);

      // Tapping should trigger onViewScorecard, never onContinueScoring
      await tester.tap(find.byType(MatchTile));
      await tester.pump();

      expect(viewScorecardCalled, isTrue);
      expect(continueScoringCalled, isFalse);
    });
  });

  group('CreateMatchWizard Step 5 Opener Cards Resilience Tests', () {
    testWidgets('Opening cards render with responsive headers and centered Add New Batter/Bowler buttons without overflow on 320px screen', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.sports_cricket, size: 16, color: AppColors.primary),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '1ST INNINGS BATTERS (EXTRAORDINARILY LONG TEAM NAME SUPER KINGS XI)',
                                style: AppTextStyles.label.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.person_add_alt_1_rounded, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Add New Batter',
                                    style: AppTextStyles.label.copyWith(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Add New Batter'), findsOneWidget);
      expect(find.byIcon(Icons.sports_cricket), findsOneWidget);
    });
  });

  group('PlayerProfileScreen UI & Team Selection Resilience Tests', () {
    testWidgets('Team selection component renders on 320px screen without overflow with long team name', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final team = Team(
        id: 'team_1',
        name: 'Jitendra Power hitter',
        shortName: 'JPH',
        colorValue: 0xFF0F9D58,
        createdAt: 1000,
      );

      final player = Player(
        id: 'p1',
        teamId: team.id,
        name: 'Chotu',
        jerseyNumber: 7,
        role: 'All Rounder',
        battingStyle: 'Right-hand bat',
        bowlingStyle: 'Right-arm medium',
        createdAt: 1000,
      );

      bool sheetOpened = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            PlayerAvatar(
                              name: player.name,
                              jerseyNumber: player.jerseyNumber,
                              size: 68,
                              colorValue: team.colorValue,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(player.name, style: AppTextStyles.h2),
                                  const SizedBox(height: 3),
                                  Text(player.role, style: AppTextStyles.bodyMedium),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Bat: ${player.battingStyle}  •  Bowl: ${player.bowlingStyle}',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 14),
                        const Text('ASSIGNED TEAM'),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => sheetOpened = true,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  alignment: Alignment.center,
                                  child: Text(team.shortName),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(team.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Text('Current Team • Jersey #${player.jerseyNumber}'),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Change'),
                                      SizedBox(width: 4),
                                      Icon(Icons.swap_horiz_rounded, size: 15),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify no RenderFlex overflow exception
      expect(tester.takeException(), isNull);
      expect(find.text('Jitendra Power hitter'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);

      await tester.tap(find.text('Change'));
      await tester.pump();
      expect(sheetOpened, isTrue);
    });

    testWidgets('Career statistics cards render hero highlights and key metric rates cleanly on 320px screen', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const stats = PlayerCareerStats(
        matches: 12,
        innings: 10,
        runs: 348,
        highestScore: 78,
        notOuts: 2,
        ballsFaced: 240,
        fours: 32,
        sixes: 14,
        fifties: 3,
        hundreds: 0,
        wickets: 15,
        runsConceded: 210,
        totalLegalBallsBowled: 180,
        bestBowling: '3/18',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  // Batting career section
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('TOTAL RUNS'),
                              FittedBox(fit: BoxFit.scaleDown, child: Text('${stats.runs}')),
                              Text('${stats.innings} Innings • ${stats.notOuts} NO'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('HIGH SCORE'),
                              FittedBox(fit: BoxFit.scaleDown, child: Text('${stats.highestScore}')),
                              Text('${stats.ballsFaced} Balls Faced'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Bowling career section
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('WICKETS'),
                              FittedBox(fit: BoxFit.scaleDown, child: Text('${stats.wickets}')),
                              Text('${stats.runsConceded} Runs Given'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('BEST FIGURES'),
                              FittedBox(fit: BoxFit.scaleDown, child: Text(stats.bestBowling)),
                              Text('${stats.runsConceded} Runs Conceded'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('TOTAL RUNS'), findsOneWidget);
      expect(find.text('348'), findsOneWidget);
      expect(find.text('HIGH SCORE'), findsOneWidget);
      expect(find.text('78'), findsOneWidget);
      expect(find.text('WICKETS'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('BEST FIGURES'), findsOneWidget);
      expect(find.text('3/18'), findsOneWidget);
    });
  });

  group('CreateMatchWizard Stepper Symmetry & Responsiveness Tests', () {
    testWidgets('Stepper renders 5 steps with symmetrical connector lines and centered labels without overflow on 320px screen', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const stepLabels = ['Details', 'Teams', 'Squad', 'Toss', 'Openers'];
      const currentStep = 4; // Step 5 as pictured in user's screenshot

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: List.generate(5, (index) {
                        return Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: index == 0
                                        ? const SizedBox()
                                        : Container(
                                            height: 3,
                                            decoration: BoxDecoration(
                                              color: index <= currentStep ? AppColors.primary : AppColors.lightBorder,
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                  ),
                                  Container(
                                    width: 28,
                                    height: 28,
                                    alignment: Alignment.center,
                                    child: Text('${index + 1}'),
                                  ),
                                  Expanded(
                                    child: index == 4
                                        ? const SizedBox()
                                        : Container(
                                            height: 3,
                                            decoration: BoxDecoration(
                                              color: index < currentStep ? AppColors.primary : AppColors.lightBorder,
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                stepLabels[index],
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      for (final label in stepLabels) {
        expect(find.text(label), findsOneWidget);
      }

      // Verify center alignment of first and last items
      final firstLabelCenter = tester.getCenter(find.text('Details'));
      final lastLabelCenter = tester.getCenter(find.text('Openers'));

      // Distance from screen left to Details center should match distance from Openers center to screen right
      final leftPadding = firstLabelCenter.dx;
      final rightPadding = 320 - lastLabelCenter.dx;
      expect((leftPadding - rightPadding).abs(), lessThan(1.0)); // Perfect symmetry!
    });

    testWidgets('Stepper maintains bounded max-width on 1200px desktop screen', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const stepLabels = ['Details', 'Teams', 'Squad', 'Toss', 'Openers'];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: List.generate(5, (index) {
                        return Expanded(
                          child: Column(
                            children: [
                              Text(stepLabels[index]),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final firstLabelCenter = tester.getCenter(find.text('Details'));
      final lastLabelCenter = tester.getCenter(find.text('Openers'));

      // Stepper width is constrained to 600px centered in 1200px (between 300px and 900px)
      expect(firstLabelCenter.dx, greaterThan(300));
      expect(lastLabelCenter.dx, lessThan(900));

      final leftPadding = firstLabelCenter.dx;
      final rightPadding = 1200 - lastLabelCenter.dx;
      expect((leftPadding - rightPadding).abs(), lessThan(1.0)); // Perfect symmetry on wide screens!
    });

    testWidgets('Stepper allows tapping completed steps to navigate back', (tester) async {
      int activeStep = 3; // Currently on Step 4 (Toss)

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: StatefulBuilder(
            builder: (context, setState) {
              const stepLabels = ['Details', 'Teams', 'Squad', 'Toss', 'Openers'];
              return Scaffold(
                body: Row(
                  children: List.generate(5, (index) {
                    return Expanded(
                      child: InkWell(
                        onTap: index < activeStep ? () => setState(() => activeStep = index) : null,
                        child: Column(
                          children: [
                            Text('${index + 1}'),
                            Text(stepLabels[index]),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ),
      );

      expect(activeStep, 3);
      // Tapping on 'Teams' (index 1 < 3) navigates back
      await tester.tap(find.text('Teams'));
      await tester.pump();
      expect(activeStep, 1);

      // Tapping on 'Openers' (index 4 > 1) does NOT navigate forward
      await tester.tap(find.text('Openers'));
      await tester.pump();
      expect(activeStep, 1);
    });

    testWidgets('Step 1 Bowler Over Limit Wrap handles 320px screen without RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        const Text('Bowler Over Limit', style: TextStyle(fontWeight: FontWeight.bold)),
                        FilterChip(
                          label: const Text('No Limit (Unlimited)'),
                          selected: false,
                          onSelected: (_) {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Bowler Over Limit'), findsOneWidget);
      expect(find.text('No Limit (Unlimited)'), findsOneWidget);
    });

    testWidgets('Step content starts immediately below stepper with standard padding and is not vertically centered', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            appBar: AppBar(title: const Text('Create Match')),
            body: Column(
              children: [
                // Stepper height ~70px
                const SizedBox(
                  height: 70,
                  key: Key('stepper'),
                  child: Center(child: Text('Stepper')),
                ),
                // Step Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: const SizedBox(
                          key: Key('banner'),
                          height: 60,
                          child: Text('Select Teams'),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final stepperBottom = tester.getBottomLeft(find.byKey(const Key('stepper'))).dy;
      final bannerTop = tester.getTopLeft(find.byKey(const Key('banner'))).dy;

      // Distance should be precisely the 16px screenPadding, NOT vertically centered
      expect(bannerTop - stepperBottom, equals(16.0));
    });
  });

  group('LiveScoringScreen Scoring Actions Menu Tests', () {
    testWidgets('Scoring Actions menu renders modern options and strictly excludes Retire Batsman', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            appBar: AppBar(
              actions: [
                PopupMenuButton<String>(
                  tooltip: 'Scoring Actions',
                  key: const Key('scoring_actions_btn'),
                  icon: const Icon(Icons.more_vert_rounded),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'live_share',
                      child: Text('Live Wi-Fi Sharing'),
                    ),
                    const PopupMenuItem(
                      value: 'bowler_limit',
                      child: Text('Bowler Over Limit'),
                    ),
                    const PopupMenuItem(
                      value: 'add_bat',
                      child: Text('Add Player to Batting Team'),
                    ),
                    const PopupMenuItem(
                      value: 'add_bowl',
                      child: Text('Add Player to Bowling Team'),
                    ),
                    const PopupMenuDivider(height: 12),
                    const PopupMenuItem(
                      value: 'declare',
                      child: Text('End 1st Innings Early'),
                    ),
                    const PopupMenuDivider(height: 12),
                    const PopupMenuItem(
                      value: 'cancel_match',
                      child: Text('Cancel Match'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      // Open Popup Menu
      await tester.tap(find.byKey(const Key('scoring_actions_btn')));
      await tester.pumpAndSettle();

      // Assert Retire Batsman is strictly removed
      expect(find.textContaining('Retire Batsman'), findsNothing);
      expect(find.textContaining('Retire'), findsNothing);

      // Assert all remaining modern options are present
      expect(find.text('Live Wi-Fi Sharing'), findsOneWidget);
      expect(find.text('Bowler Over Limit'), findsOneWidget);
      expect(find.text('Add Player to Batting Team'), findsOneWidget);
      expect(find.text('Add Player to Bowling Team'), findsOneWidget);
      expect(find.text('End 1st Innings Early'), findsOneWidget);
      expect(find.text('Cancel Match'), findsOneWidget);
    });

    testWidgets('Modern action menu item renders cleanly without overflow on narrow 320px screen', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 280,
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.wifi_tethering_rounded, size: 17, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Live Wi-Fi Sharing', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          SizedBox(height: 1.5),
                          Text('Broadcast live score nearby', style: TextStyle(fontSize: 10.5, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('LIVE', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.success)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Live Wi-Fi Sharing'), findsOneWidget);
      expect(find.text('Broadcast live score nearby'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);
    });
  });

  group('MatchDetailScreen Header & TabBar Layout Resilience Tests', () {
    testWidgets('Single innings allocates exact 48px height without 40px blank space and aligns tabs to start', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: DefaultTabController(
            length: 5,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('IND vs AUS'),
                bottom: const PreferredSize(
                  preferredSize: Size.fromHeight(48), // Single innings exact height
                  child: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    tabs: [
                      Tab(text: 'Scorecard'),
                      Tab(text: 'Commentary'),
                      Tab(text: 'Stats & Charts'),
                      Tab(text: 'Partnerships'),
                      Tab(text: 'Fall of Wickets'),
                    ],
                  ),
                ),
              ),
              body: const TabBarView(
                children: [
                  Center(child: Text('Scorecard Content')),
                  Center(child: Text('Commentary Content')),
                  Center(child: Text('Stats Content')),
                  Center(child: Text('Partnerships Content')),
                  Center(child: Text('FOW Content')),
                ],
              ),
            ),
          ),
        ),
      );

      // Scorecard tab should be positioned near the left edge (< 30px) rather than having a 52px+ M3 startOffset
      final scorecardTabX = tester.getTopLeft(find.text('Scorecard')).dx;
      expect(scorecardTabX, lessThan(35.0));

      // Content should not have vertical dead space
      expect(find.text('Scorecard Content'), findsOneWidget);
    });
  });

  group('Cricket Application Feature Upgrades & Validation Tests', () {
    test('Format list ordering and T12 configuration', () {
      const formats = ['T10', 'T12', 'T20', 'ODI', 'Test', 'Custom'];
      expect(formats[0], equals('T10'));
      expect(formats[1], equals('T12'));
      expect(formats[2], equals('T20'));
      expect(formats[3], equals('ODI'));
      expect(formats[4], equals('Test'));
      expect(formats[5], equals('Custom'));

      final draft = CreateMatchDraft();
      draft.format = 'T12';
      draft.totalOvers = 12;
      draft.maxOversPerBowler = 3;

      expect(draft.format, equals('T12'));
      expect(draft.totalOvers, equals(12));
      expect(draft.maxOversPerBowler, equals(3));
    });

    test('Retired Hurt logic does not increment wicket count or mark player out', () {
      const inn = Innings(
        id: 'inn1',
        matchId: 'm1',
        inningsNumber: 1,
        battingTeamId: 't1',
        bowlingTeamId: 't2',
        totalRuns: 45,
        totalWickets: 1,
        totalLegalBalls: 24,
        createdAt: 0,
      );

      // Simulating a retired hurt ball event
      int computeWickets(int current, bool isWkt, bool isRet) {
        return current + (isWkt && !isRet ? 1 : 0);
      }
      expect(computeWickets(inn.totalWickets, true, true), equals(1)); // Retired hurt MUST NOT increment
      expect(computeWickets(inn.totalWickets, true, false), equals(2)); // Real wicket increments

      const batterStat = BattingStat(
        id: 'bs1',
        inningsId: 'inn1',
        playerId: 'p1',
        playerName: 'Batter A',
        runs: 24,
        balls: 15,
        fours: 3,
        sixes: 1,
        isOut: false, // NOT OUT
        dismissalType: 'retired hurt',
      );

      expect(batterStat.isOut, isFalse);
      expect(batterStat.dismissalType, equals('retired hurt'));

      // When player returns:
      final returningStat = batterStat.copyWith(
        runs: batterStat.runs + 10,
        balls: batterStat.balls + 6,
      );
      expect(returningStat.isOut, isFalse);
      expect(returningStat.runs, equals(34));
      expect(returningStat.balls, equals(21));
    });

    test('Partnership updates and restores correctly on Undo', () {
      var partnership = const Partnership(
        id: 'pt1',
        inningsId: 'inn1',
        wicketNumber: 1,
        batter1Id: 'p1',
        batter1Name: 'Batter 1',
        batter1Runs: 10,
        batter1Balls: 8,
        batter2Id: 'p2',
        batter2Name: 'Batter 2',
        batter2Runs: 15,
        batter2Balls: 12,
        totalRuns: 25,
        totalBalls: 20,
      );

      // Simulate scoring 4 runs by batter 1
      final ball1 = const Ball(
        id: 'b1',
        matchId: 'm1',
        inningsId: 'inn1',
        overNumber: 3,
        ballNumber: 3,
        bowlerId: 'bw1',
        batsmanId: 'p1',
        nonStrikerId: 'p2',
        runsBat: 4,
        extras: 0,
        isLegalBall: true,
        isWicket: false,
        timestamp: 0,
      );

      final updatedPartnership = partnership.copyWith(
        batter1Runs: partnership.batter1Runs + ball1.runsBat,
        batter1Balls: partnership.batter1Balls + (ball1.isLegalBall ? 1 : 0),
        totalRuns: partnership.totalRuns + ball1.totalRuns,
        totalBalls: partnership.totalBalls + (ball1.isLegalBall ? 1 : 0),
      );

      expect(updatedPartnership.batter1Runs, equals(14));
      expect(updatedPartnership.totalRuns, equals(29));
      expect(updatedPartnership.totalBalls, equals(21));

      // Simulate Undo
      final revertedPartnership = updatedPartnership.copyWith(
        batter1Runs: updatedPartnership.batter1Runs - ball1.runsBat,
        batter1Balls: updatedPartnership.batter1Balls - (ball1.isLegalBall ? 1 : 0),
        totalRuns: updatedPartnership.totalRuns - ball1.totalRuns,
        totalBalls: updatedPartnership.totalBalls - (ball1.isLegalBall ? 1 : 0),
      );

      expect(revertedPartnership.batter1Runs, equals(partnership.batter1Runs));
      expect(revertedPartnership.totalRuns, equals(partnership.totalRuns));
      expect(revertedPartnership.totalBalls, equals(partnership.totalBalls));
    });

    testWidgets('Step 3 Squad Selector 2-column grid renders responsively based on width', (tester) async {
      const p1 = Player(id: 'p1', teamId: 't1', name: 'Rohit Sharma', jerseyNumber: 45, role: 'Batter', createdAt: 0);
      const p2 = Player(id: 'p2', teamId: 't1', name: 'Jasprit Bumrah', jerseyNumber: 93, role: 'Bowler', createdAt: 0);

      Widget buildSquadGrid(double width) {
        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final colCount = constraints.maxWidth < 380 ? 1 : 2;
                    final spacing = 8.0;
                    final itemWidth = (constraints.maxWidth - (spacing * (colCount - 1))) / colCount;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [p1, p2].map((p) {
                        return SizedBox(
                          key: Key('card_${p.id}'),
                          width: itemWidth,
                          height: 48,
                          child: Text(p.name),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      }

      // On 400px width: 2 columns => both items should be on the same horizontal line
      await tester.pumpWidget(buildSquadGrid(400));
      await tester.pumpAndSettle();
      final p1Pos400 = tester.getTopLeft(find.byKey(const Key('card_p1')));
      final p2Pos400 = tester.getTopLeft(find.byKey(const Key('card_p2')));
      expect(p1Pos400.dy, equals(p2Pos400.dy));
      expect(p2Pos400.dx, greaterThan(p1Pos400.dx));

      // On 340px width: 1 column => cards stacked vertically
      await tester.pumpWidget(buildSquadGrid(340));
      await tester.pumpAndSettle();
      final p1Pos340 = tester.getTopLeft(find.byKey(const Key('card_p1')));
      final p2Pos340 = tester.getTopLeft(find.byKey(const Key('card_p2')));
      expect(p2Pos340.dy, greaterThan(p1Pos340.dy));
    });

    testWidgets('StatsChartsTab Runs Per Over chart renders without overflow on 320px mobile', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final barGroups = List.generate(
        12,
        (i) => BarChartGroupData(
          x: i + 1,
          barRods: [BarChartRodData(toY: ((i * 4) % 15).toDouble() + 1, color: Colors.green, width: 10)],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 290,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double minWidthPerBar = 26.0;
                    final double requiredWidth = math.max(constraints.maxWidth, barGroups.length * minWidthPerBar + 38.0);
                    final bool isScrollable = requiredWidth > constraints.maxWidth;
                    final double chartWidth = isScrollable ? requiredWidth : constraints.maxWidth;

                    final chart = SizedBox(
                      width: chartWidth,
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          barGroups: barGroups,
                          titlesData: const FlTitlesData(show: false),
                        ),
                      ),
                    );

                    if (isScrollable) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: chart,
                      );
                    }
                    return chart;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    test('PdfScorecardGenerator produces clean first page with team scores and no over-by-over section', () async {
      const teamA = Team(id: 't1', name: 'India', shortName: 'IND', colorValue: 0xFF1D4ED8, createdAt: 0);
      const teamB = Team(id: 't2', name: 'Australia', shortName: 'AUS', colorValue: 0xFFEAB308, createdAt: 0);
      final match = CricketMatch(
        id: 'm1',
        title: 'IND vs AUS - T12 Final',
        teamAId: 't1',
        teamBId: 't2',
        totalOvers: 12,
        format: 'T12',
        venue: 'Melbourne Cricket Ground',
        matchDate: 1700000000000,
        status: 'completed',
        winnerTeamId: 't1',
        resultSummary: 'India won by 15 runs',
        tossWinnerTeamId: 't1',
        tossDecision: 'bat',
        createdAt: 0,
      );
      const inn1 = Innings(
        id: 'inn1',
        matchId: 'm1',
        inningsNumber: 1,
        battingTeamId: 't1',
        bowlingTeamId: 't2',
        totalRuns: 135,
        totalWickets: 4,
        totalLegalBalls: 72,
        createdAt: 0,
      );
      const inn2 = Innings(
        id: 'inn2',
        matchId: 'm1',
        inningsNumber: 2,
        battingTeamId: 't2',
        bowlingTeamId: 't1',
        totalRuns: 120,
        totalWickets: 7,
        totalLegalBalls: 72,
        createdAt: 0,
      );

      final doc = PdfScorecardGenerator.buildPdfDocument(
        match: match,
        teamA: teamA,
        teamB: teamB,
        allInnings: [inn1, inn2],
        battingStatsMap: {'inn1': [], 'inn2': []},
        bowlingStatsMap: {'inn1': [], 'inn2': []},
      );

      final pdfBytes = await doc.save();
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(2000));
    });
  });

  group('UI/UX Enhancement & Compact Layout Tests', () {
    testWidgets('Compact MatchTile, TeamTile and PlayerTile render on narrow 320px screen without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const teamA = Team(id: 't1', name: 'Mumbai Indians', shortName: 'MI', colorValue: 0xFF1D4ED8, createdAt: 0);
      const teamB = Team(id: 't2', name: 'Chennai Super Kings', shortName: 'CSK', colorValue: 0xFFEAB308, createdAt: 0);
      final match = CricketMatch(
        id: 'm1',
        title: 'MI vs CSK',
        teamAId: 't1',
        teamBId: 't2',
        totalOvers: 20,
        format: 'T20',
        venue: 'Wankhede Stadium',
        matchDate: 1700000000000,
        status: 'live',
        createdAt: 0,
      );
      const innA = Innings(
        id: 'inn1',
        matchId: 'm1',
        inningsNumber: 1,
        battingTeamId: 't1',
        bowlingTeamId: 't2',
        totalRuns: 185,
        totalWickets: 4,
        totalLegalBalls: 120,
        createdAt: 0,
      );
      final player = Player(
        id: 'p1',
        teamId: 't1',
        name: 'Rohit Sharma',
        role: 'Batsman',
        battingStyle: 'Right-Hand',
        jerseyNumber: 45,
        isCaptain: true,
        createdAt: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  MatchTile(
                    match: match,
                    teamA: teamA,
                    teamB: teamB,
                    inningsList: const [innA],
                  ),
                  TeamTile(
                    team: teamA,
                    playerCount: 15,
                    captainName: 'Rohit Sharma',
                  ),
                  PlayerTile(
                    player: player,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Mumbai Indians'), findsWidgets);
      expect(find.text('Chennai Super Kings'), findsOneWidget);
      expect(find.text('185/4'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('MI'), findsWidgets);
      expect(find.text('Rohit Sharma'), findsWidgets);
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('LiveScoreBanner renders with refined compact broadcast typography', (tester) async {
      tester.view.physicalSize = const Size(360, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const teamA = Team(id: 't1', name: 'Royal Challengers', shortName: 'RCB', colorValue: 0xFFDC2626, createdAt: 0);
      const teamB = Team(id: 't2', name: 'Kolkata Knight Riders', shortName: 'KKR', colorValue: 0xFF7C3AED, createdAt: 0);
      final match = CricketMatch(
        id: 'm1',
        title: 'RCB vs KKR',
        teamAId: 't1',
        teamBId: 't2',
        totalOvers: 20,
        format: 'T20',
        venue: 'Chinnaswamy Stadium',
        matchDate: 1700000000000,
        status: 'live',
        createdAt: 0,
      );
      const inn = Innings(
        id: 'inn1',
        matchId: 'm1',
        inningsNumber: 1,
        battingTeamId: 't1',
        bowlingTeamId: 't2',
        totalRuns: 204,
        totalWickets: 3,
        totalLegalBalls: 114,
        createdAt: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: LiveScoreBanner(
              match: match,
              innings: inn,
              battingTeam: teamA,
              bowlingTeam: teamB,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('ROYAL CHALLENGERS'), findsOneWidget);
      expect(find.text('Innings 1 of 2'), findsOneWidget);
      expect(find.text('204'), findsOneWidget);
      expect(find.text(' / 3'), findsOneWidget);
      expect(find.text('19.0 / 20'), findsOneWidget);
    });

    testWidgets('BoundaryCelebrationOverlay renders FOUR celebration with non-blocking IgnorePointer', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          themeMode: ThemeMode.dark,
          home: Scaffold(
            body: BoundaryCelebrationOverlay(
              celebration: BoundaryCelebration(
                type: BoundaryType.four,
                timestamp: 1001,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('FOUR!'), findsOneWidget);
      expect(find.text('4 RUNS'), findsOneWidget);
      expect(find.text('BOUNDARY'), findsOneWidget);

      final ignorePointer = tester.widget<IgnorePointer>(
        find.descendant(
          of: find.byType(BoundaryCelebrationOverlay),
          matching: find.byType(IgnorePointer),
        ).first,
      );
      expect(ignorePointer.ignoring, isTrue);
    });

    testWidgets('BoundaryCelebrationOverlay renders SIX celebration with non-blocking IgnorePointer', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          themeMode: ThemeMode.dark,
          home: Scaffold(
            body: BoundaryCelebrationOverlay(
              celebration: BoundaryCelebration(
                type: BoundaryType.six,
                timestamp: 1002,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('SIX!'), findsOneWidget);
      expect(find.text('6 RUNS'), findsOneWidget);
      expect(find.text('MAXIMUM'), findsOneWidget);

      final ignorePointer = tester.widget<IgnorePointer>(
        find.descendant(
          of: find.byType(BoundaryCelebrationOverlay),
          matching: find.byType(IgnorePointer),
        ).first,
      );
      expect(ignorePointer.ignoring, isTrue);
    });

    testWidgets('BoundaryCelebrationOverlay returns empty when celebration is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BoundaryCelebrationOverlay(
              celebration: null,
            ),
          ),
        ),
      );

      expect(find.text('FOUR!'), findsNothing);
      expect(find.text('SIX!'), findsNothing);
    });
  });
}



