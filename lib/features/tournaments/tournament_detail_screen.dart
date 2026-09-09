import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/match_tile.dart';
import '../matches/create_match_wizard.dart';
import '../scorecard/match_detail_screen.dart';
import '../scoring/live_scoring_screen.dart';
import '../teams/team_provider.dart';
import 'add_edit_tournament_dialog.dart';
import 'tournament_provider.dart';

class TournamentDetailScreen extends StatefulWidget {
  final String tournamentId;

  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TournamentProvider>().loadTournamentDetails(widget.tournamentId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tourneyProv = context.watch<TournamentProvider>();
    final teamProv = context.watch<TeamProvider>();
    final tourney = tourneyProv.selectedTournament;

    if (tourneyProv.isLoading || tourney == null) {
      return const Scaffold(body: LoadingState(message: 'Loading tournament standings...'));
    }

    final standings = tourneyProv.selectedTournamentStandings;
    final matches = tourneyProv.selectedTournamentMatches;

    return Scaffold(
      appBar: AppBar(
        title: Text(tourney.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => AddEditTournamentDialog.show(context, tournamentToEdit: tourney),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => _confirmDelete(context, tourney.id, tourney.name),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Standings (Points Table)'),
            Tab(text: 'Matches & Fixtures'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Standings Tab
          _buildStandingsTab(context, standings, isDark),

          // 2. Matches Tab
          _buildMatchesTab(context, matches, teamProv),
        ],
      ),
    );
  }

  Widget _buildStandingsTab(BuildContext context, List standings, bool isDark) {
    if (standings.isEmpty) {
      return const EmptyState(
        title: 'No standings data',
        message: 'Add teams and play matches to calculate points and net run rates.',
        icon: Icons.leaderboard_outlined,
      );
    }

    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            padding: EdgeInsets.zero,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 18,
                headingRowColor: WidgetStateProperty.all(
                  isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                ),
                columns: const [
                  DataColumn(label: Text('TEAM', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(numeric: true, label: Text('M', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(numeric: true, label: Text('W', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(numeric: true, label: Text('L', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(numeric: true, label: Text('PTS', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
                  DataColumn(numeric: true, label: Text('NRR', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: standings.map<DataRow>((s) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Color(s.colorValue),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(s.teamShortName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      DataCell(Text('${s.matchesPlayed}')),
                      DataCell(Text('${s.won}')),
                      DataCell(Text('${s.lost}')),
                      DataCell(Text('${s.points}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
                      DataCell(Text(s.formattedNRR)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesTab(BuildContext context, List matches, TeamProvider teamProv) {
    if (matches.isEmpty) {
      return EmptyState(
        title: 'No matches in tournament',
        message: 'Schedule and play matches for this tournament.',
        actionLabel: 'Schedule Match',
        onAction: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CreateMatchWizard()),
          );
        },
      );
    }

    return ListView.builder(
      padding: AppSpacing.screenPadding,
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final m = matches[index];
        final teamA = teamProv.teams.firstWhere(
          (t) => t.id == m.teamAId,
          orElse: () => teamProv.teams.first,
        );
        final teamB = teamProv.teams.firstWhere(
          (t) => t.id == m.teamBId,
          orElse: () => teamProv.teams.length > 1 ? teamProv.teams[1] : teamProv.teams.first,
        );

        return MatchTile(
          match: m,
          teamA: teamA,
          teamB: teamB,
          onContinueScoring: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => LiveScoringScreen(matchId: m.id)),
            );
          },
          onViewScorecard: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => MatchDetailScreen(matchId: m.id)),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String tourneyId, String name) {
    AppDialog.show(
      context: context,
      title: 'Delete Tournament?',
      content: Text('Are you sure you want to delete "$name"?'),
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      isDestructive: true,
      onConfirm: () async {
        await context.read<TournamentProvider>().deleteTournament(tourneyId);
        if (context.mounted) {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        }
      },
    );
  }
}
