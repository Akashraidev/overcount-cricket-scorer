import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_tile.dart';
import '../teams/team_provider.dart';
import 'add_edit_player_dialog.dart';
import 'player_provider.dart';

class PlayerProfileScreen extends StatefulWidget {
  final String playerId;

  const PlayerProfileScreen({super.key, required this.playerId});

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlayerProvider>().loadPlayerProfile(widget.playerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final playerProv = context.watch<PlayerProvider>();
    final teamProv = context.watch<TeamProvider>();
    final player = playerProv.selectedPlayer;
    final stats = playerProv.selectedPlayerStats;

    if (playerProv.isLoading || player == null || stats == null) {
      return const Scaffold(body: LoadingState(message: 'Loading career profile...'));
    }

    final team = teamProv.teams.firstWhere(
      (t) => t.id == player.teamId,
      orElse: () => teamProv.teams.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(player.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => AddEditPlayerDialog.show(context, playerToEdit: player),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => _confirmDelete(context, player.id, player.name),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header Card
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: AppRadius.roundedFull,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      player.jerseyNumber > 0 ? '${player.jerseyNumber}' : player.name[0],
                      style: AppTextStyles.scoreMedium.copyWith(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: AppTextStyles.h2.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${player.role} • ${team.name}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Batting: ${player.battingStyle}\nBowling: ${player.bowlingStyle}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Batting Career Stats
            const SectionHeader(title: 'Batting Career Statistics'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.15,
              children: [
                StatTile(label: 'Runs', value: '${stats.runs}'),
                StatTile(label: 'High Score', value: '${stats.highestScore}'),
                StatTile(label: 'Average', value: stats.battingAverage.toStringAsFixed(1)),
                StatTile(label: 'Strike Rate', value: stats.strikeRate.toStringAsFixed(1)),
                StatTile(label: '4s / 6s', value: '${stats.fours} / ${stats.sixes}'),
                StatTile(label: '50s / 100s', value: '${stats.fifties} / ${stats.hundreds}'),
              ],
            ),
            const SizedBox(height: 24),

            // Bowling Career Stats
            const SectionHeader(title: 'Bowling Career Statistics'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.15,
              children: [
                StatTile(label: 'Wickets', value: '${stats.wickets}'),
                StatTile(label: 'Best Figures', value: stats.bestBowling),
                StatTile(label: 'Economy', value: stats.bowlingEconomy.toStringAsFixed(2)),
                StatTile(label: 'Average', value: stats.wickets > 0 ? stats.bowlingAverage.toStringAsFixed(1) : '-'),
                StatTile(label: 'Overs', value: (stats.totalLegalBallsBowled / 6.0).toStringAsFixed(1)),
                StatTile(label: 'Matches', value: '${stats.matches}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String playerId, String playerName) {
    AppDialog.show(
      context: context,
      title: 'Delete Player?',
      content: Text('Are you sure you want to delete "$playerName"? This action cannot be undone.'),
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      isDestructive: true,
      onConfirm: () async {
        await context.read<PlayerProvider>().deletePlayer(playerId);
        if (context.mounted) {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        }
      },
    );
  }
}
