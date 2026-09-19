import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/team_tile.dart';
import 'add_edit_team_dialog.dart';
import 'team_detail_screen.dart';
import 'team_provider.dart';

class TeamsScreen extends StatelessWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final teams = teamProv.teams;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teams Directory'),
        actions: [
          AppHeaderActionButton(
            label: 'Add Team',
            icon: Icons.add_rounded,
            margin: const EdgeInsets.only(right: 14),
            onPressed: () => AddEditTeamDialog.show(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: AppTextField(
              hint: 'Search teams by name or code...',
              prefixIcon: const Icon(Icons.search, size: 20),
              onChanged: (v) => teamProv.setSearchQuery(v),
            ),
          ),

          // Team List
          Expanded(
            child: teamProv.isLoading
                ? const LoadingState(message: 'Loading teams...')
                : teams.isEmpty
                    ? EmptyState(
                        title: 'No teams found',
                        message: 'Create teams to configure squads and schedule matches.',
                        actionLabel: 'Create New Team',
                        onAction: () => AddEditTeamDialog.show(context),
                      )
                    : RefreshIndicator(
                        onRefresh: () => teamProv.loadTeams(),
                        child: ListView.builder(
                          padding: AppSpacing.screenPadding,
                          itemCount: teams.length,
                          itemBuilder: (context, index) {
                            final team = teams[index];
                            return FutureBuilder<int>(
                              future: teamProv.getPlayerCount(team.id),
                              builder: (context, snapshot) {
                                final count = snapshot.data ?? 0;
                                return TeamTile(
                                  team: team,
                                  playerCount: count,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => TeamDetailScreen(teamId: team.id),
                                      ),
                                    );
                                  },
                                  trailing: const Icon(
                                    Icons.chevron_right,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
