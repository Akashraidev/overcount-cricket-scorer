import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/player_tile.dart';
import '../../core/widgets/section_header.dart';
import '../players/add_edit_player_dialog.dart';
import '../players/player_profile_screen.dart';
import 'add_edit_team_dialog.dart';
import 'team_provider.dart';

class TeamDetailScreen extends StatefulWidget {
  final String teamId;

  const TeamDetailScreen({super.key, required this.teamId});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeamProvider>().loadTeamDetails(widget.teamId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final teamProv = context.watch<TeamProvider>();
    final team = teamProv.selectedTeam;

    if (teamProv.isLoading || team == null) {
      return const Scaffold(body: LoadingState(message: 'Loading team details...'));
    }

    final teamColor = Color(team.colorValue);
    final players = teamProv.selectedTeamPlayers;

    return Scaffold(
      appBar: AppBar(
        title: Text(team.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => AddEditTeamDialog.show(context, teamToEdit: team),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => _confirmDelete(context, team.id, team.name),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team Banner Card
            AppCard(
              backgroundColor: teamColor.withValues(alpha: 0.15),
              borderColor: teamColor.withValues(alpha: 0.5),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: teamColor,
                      borderRadius: AppRadius.roundedMd,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      team.shortName,
                      style: AppTextStyles.scoreMedium.copyWith(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style: AppTextStyles.h2.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${players.length} Squad Players',
                          style: AppTextStyles.bodyMedium.copyWith(
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

            // Squad Header
            SectionHeader(
              title: 'Squad Roster (${players.length})',
              trailing: AppHeaderActionButton(
                label: 'Add Player',
                icon: Icons.person_add_rounded,
                onPressed: () => AddEditPlayerDialog.show(context, initialTeamId: team.id),
              ),
            ),
            const SizedBox(height: 12),

            if (players.isEmpty)
              EmptyState(
                title: 'No players in squad',
                message: 'Add players to this team to begin playing matches.',
                actionLabel: 'Add First Player',
                onAction: () => AddEditPlayerDialog.show(context, initialTeamId: team.id),
              )
            else
              ...players.map((p) {
                return PlayerTile(
                  player: p,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PlayerProfileScreen(playerId: p.id),
                      ),
                    );
                  },
                  trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.primary),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String teamId, String teamName) {
    AppDialog.show(
      context: context,
      title: 'Delete Team?',
      content: Text('Are you sure you want to delete "$teamName"? This will also delete all associated squad players and historical matches.'),
      confirmLabel: 'Delete Team',
      cancelLabel: 'Cancel',
      isDestructive: true,
      onConfirm: () async {
        await context.read<TeamProvider>().deleteTeam(teamId);
        if (context.mounted) {
          Navigator.of(context).pop(); // Close dialog
          Navigator.of(context).pop(); // Exit screen
        }
      },
    );
  }
}
