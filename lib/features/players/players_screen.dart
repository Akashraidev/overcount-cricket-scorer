import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_dropdown.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/player.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/player_tile.dart';
import '../teams/team_provider.dart';
import 'add_edit_player_dialog.dart';
import 'player_profile_screen.dart';
import 'player_provider.dart';

class PlayersScreen extends StatelessWidget {
  const PlayersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProv = context.watch<PlayerProvider>();
    final teamProv = context.watch<TeamProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final roles = ['All', 'Batter', 'Bowler', 'All Rounder', 'Wicketkeeper'];
    final players = playerProv.players;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Players Directory'),
        actions: [
          AppHeaderActionButton(
            label: 'Add Player',
            icon: Icons.person_add_rounded,
            margin: const EdgeInsets.only(right: 14),
            onPressed: () => AddEditPlayerDialog.show(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Team Filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                AppTextField(
                  hint: 'Search players by name or jersey...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  onChanged: (v) => playerProv.setSearchQuery(v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: AppDropdown<String?>(
                        value: playerProv.selectedTeamFilter,
                        hint: 'All Teams',
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Teams')),
                          ...teamProv.teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
                        ],
                        onChanged: (v) => playerProv.setTeamFilter(v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Role Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: roles.map((r) {
                final isSelected = playerProv.selectedRoleFilter == r;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(r),
                    selected: isSelected,
                    onSelected: (_) => playerProv.setRoleFilter(r),
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: AppTextStyles.label.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedFull),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Players List
          Expanded(
            child: playerProv.isLoading
                ? const LoadingState(message: 'Loading players...')
                : players.isEmpty
                    ? EmptyState(
                        title: 'No players found',
                        message: 'Try adjusting filters or add a new player to the roster.',
                        actionLabel: 'Add Player',
                        onAction: () => AddEditPlayerDialog.show(context),
                      )
                    : RefreshIndicator(
                        onRefresh: () => playerProv.loadPlayers(),
                        child: ListView.builder(
                          padding: AppSpacing.screenPadding,
                          itemCount: players.length,
                          itemBuilder: (context, index) {
                            final p = players[index];
                            return PlayerTile(
                              player: p,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => PlayerProfileScreen(playerId: p.id),
                                  ),
                                );
                              },
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 20),
                                tooltip: 'Player options',
                                onSelected: (val) {
                                  if (val == 'change_team') {
                                    _showChangeTeamDialog(context, p);
                                  } else if (val == 'edit') {
                                    AddEditPlayerDialog.show(context, playerToEdit: p);
                                  } else if (val == 'profile') {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => PlayerProfileScreen(playerId: p.id),
                                      ),
                                    );
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'change_team',
                                    child: Row(
                                      children: [
                                        Icon(Icons.swap_horiz_rounded, size: 18, color: AppColors.primary),
                                        SizedBox(width: 8),
                                        Text('Change Team'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 18),
                                        SizedBox(width: 8),
                                        Text('Edit Player'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'profile',
                                    child: Row(
                                      children: [
                                        Icon(Icons.person_outline, size: 18),
                                        SizedBox(width: 8),
                                        Text('View Profile'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showChangeTeamDialog(BuildContext context, Player player) {
    final teams = context.read<TeamProvider>().teams;
    final currentTeam = teams.cast<dynamic>().firstWhere(
          (t) => t.id == player.teamId,
          orElse: () => null,
        );
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
                'Current Team: ${currentTeam?.name ?? 'None'}',
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
