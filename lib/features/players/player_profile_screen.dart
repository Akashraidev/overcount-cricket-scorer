import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/photo_picker_helper.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_dropdown.dart';
import '../../core/widgets/player_avatar.dart';
import '../../data/models/player.dart';
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

  Future<void> _handlePhotoChange(BuildContext context, Player player) async {
    final playerProv = context.read<PlayerProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final newPhoto = await PhotoPickerHelper.showPhotoSourceSheet(
      context: context,
      playerId: player.id,
      currentPhotoUrl: player.photoUrl,
    );

    if (newPhoto != null && mounted) {
      if (newPhoto.isEmpty) {
        await playerProv.updatePlayerPhoto(player.id, null);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Profile photo removed'),
            backgroundColor: AppColors.primary,
          ),
        );
      } else {
        await playerProv.updatePlayerPhoto(player.id, newPhoto);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      await playerProv.loadPlayerProfile(player.id);
    }
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
            icon: const Icon(Icons.add_a_photo_outlined),
            tooltip: 'Change Photo',
            onPressed: () => _handlePhotoChange(context, player),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Player Options',
            onSelected: (value) {
              switch (value) {
                case 'photo':
                  _handlePhotoChange(context, player);
                  break;
                case 'team':
                  _showChangeTeamDialog(context, player, team.name);
                  break;
                case 'edit':
                  AddEditPlayerDialog.show(context, playerToEdit: player);
                  break;
                case 'delete':
                  _confirmDelete(context, player.id, player.name);
                  break;
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'photo',
                child: Row(
                  children: [
                    Icon(Icons.camera_alt_outlined, size: 20, color: AppColors.primary),
                    SizedBox(width: 10),
                    Text('Edit / Change Photo'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'team',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Change Team'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 10),
                    Text('Edit Player Details'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                    SizedBox(width: 10),
                    Text('Delete Player', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
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
              child: Column(
                children: [
                  Row(
                    children: [
                      PlayerAvatar(
                        name: player.name,
                        photoUrl: player.photoUrl,
                        jerseyNumber: player.jerseyNumber,
                        size: 70,
                        colorValue: team.colorValue,
                        showCameraBadge: true,
                        onTap: () => _handlePhotoChange(context, player),
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
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  // Team assignment row with direct change button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.groups_outlined, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Current Team: ',
                            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            team.name,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                        label: const Text('Change Team', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () => _showChangeTeamDialog(context, player, team.name),
                      ),
                    ],
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

  void _showChangeTeamDialog(BuildContext context, Player player, String currentTeamName) {
    final teams = context.read<TeamProvider>().teams;
    String selectedTeamId = player.teamId;

    AppDialog.show(
      context: context,
      title: 'Change Player Team',
      content: StatefulBuilder(
        builder: (context, setDlgState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Player: ${player.name}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Current Team: $currentTeamName',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              AppDropdown<String>(
                label: 'New Team',
                value: selectedTeamId,
                items: teams.map((t) {
                  return DropdownMenuItem(
                    value: t.id,
                    child: Text('${t.name} (${t.shortName})'),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) {
                    setDlgState(() => selectedTeamId = v);
                  }
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'Jersey number will be kept if available, or automatically reallocated (1-100) if occupied in the new team.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          );
        },
      ),
      confirmLabel: 'Update Team',
      cancelLabel: 'Cancel',
      onConfirm: () async {
        if (selectedTeamId == player.teamId) {
          Navigator.of(context).pop();
          return;
        }
        final playerProv = context.read<PlayerProvider>();
        final updated = await playerProv.changePlayerTeam(player.id, selectedTeamId);
        if (context.mounted) {
          Navigator.of(context).pop();
          final newTeam = teams.cast<dynamic>().firstWhere(
                (t) => t.id == selectedTeamId,
                orElse: () => null,
              );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${player.name} moved to ${newTeam?.name ?? 'new team'} (Jersey #${updated?.jerseyNumber ?? player.jerseyNumber})',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
    );
  }
}
