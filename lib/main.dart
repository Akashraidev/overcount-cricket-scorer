import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/theme/app_theme.dart';
import 'data/database/database_service.dart';
import 'features/matches/match_provider.dart';
import 'features/players/player_provider.dart';
import 'features/scorecard/scorecard_provider.dart';
import 'features/scoring/local_scoring_provider.dart';
import 'features/scoring/scoring_provider.dart';
import 'features/settings/settings_provider.dart';
import 'features/splash/splash_screen.dart';
import 'features/statistics/statistics_provider.dart';
import 'features/teams/team_provider.dart';
import 'features/tournaments/tournament_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite FFI on Desktop platforms
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Ensure DB initialized and populate realistic sample cricket data if fresh install
  try {
    await DatabaseService.instance.database;
    // await SampleDataSeeder.seedIfEmpty();
  } catch (e) {
    debugPrint('Database initialization notice: $e');
  }

  runApp(const CricketScorecardApp());
}

class CricketScorecardApp extends StatelessWidget {
  const CricketScorecardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => TeamProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => TournamentProvider()),
        ChangeNotifierProvider(create: (_) => MatchProvider()),
        ChangeNotifierProvider(create: (_) => ScoringProvider()),
        ChangeNotifierProvider(create: (_) => ScorecardProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
        ChangeNotifierProvider(create: (_) => LocalScoringProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: 'Cricket Scorer',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
