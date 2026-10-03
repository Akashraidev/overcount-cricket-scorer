import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/photo_picker_helper.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/player_avatar.dart';
import '../../data/models/player.dart';
import '../../data/repositories/player_repository.dart';
import '../../core/widgets/loading_state.dart';
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
                  _openTeamSelectionSheet(context, player, team.id);
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
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      PlayerAvatar(
                        name: player.name,
                        photoUrl: player.photoUrl,
                        jerseyNumber: player.jerseyNumber,
                        size: 68,
                        colorValue: team.colorValue,
                        showCameraBadge: true,
                        onTap: () => _handlePhotoChange(context, player),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              player.name,
                              style: AppTextStyles.h2.copyWith(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              player.role,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Bat: ${player.battingStyle}  •  Bowl: ${player.bowlingStyle}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  const SizedBox(height: 14),

                  // Team Selection Component (Redesigned & Overflow-free)
                  Text(
                    'ASSIGNED TEAM',
                    style: AppTextStyles.label.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _openTeamSelectionSheet(context, player, team.id),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Color(team.colorValue).withValues(alpha: 0.08)
                            : Color(team.colorValue).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(team.colorValue).withValues(alpha: isDark ? 0.35 : 0.25),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Team Crest Badge
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Color(team.colorValue).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Color(team.colorValue), width: 1.5),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              team.shortName,
                              style: TextStyle(
                                color: Color(team.colorValue),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Team Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  team.name,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: AppColors.success,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        'Current Team • Jersey #${player.jerseyNumber}',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          fontSize: 11,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // "Change" Action Button
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Change',
                                  style: AppTextStyles.label.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.swap_horiz_rounded, size: 15, color: AppColors.primary),
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
            const SizedBox(height: 24),

            // Batting Career Stats
            _buildBattingCareerSection(context, stats, isDark),
            const SizedBox(height: 24),

            // Bowling Career Stats
            _buildBowlingCareerSection(context, stats, isDark),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBattingCareerSection(BuildContext context, PlayerCareerStats stats, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sports_cricket, size: 16, color: Color(0xFFF59E0B)),
            ),
            const SizedBox(width: 8),
            Text(
              'Batting Career Statistics',
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Hero Row: Runs & High Score
        Row(
          children: [
            Expanded(
              child: _buildHeroStatCard(
                title: 'TOTAL RUNS',
                value: '${stats.runs}',
                subtitle: '${stats.innings} Innings • ${stats.notOuts} NO',
                icon: Icons.local_fire_department_rounded,
                accentColor: const Color(0xFFF59E0B),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildHeroStatCard(
                title: 'HIGH SCORE',
                value: '${stats.highestScore}',
                subtitle: '${stats.ballsFaced} Balls Faced',
                icon: Icons.emoji_events_rounded,
                accentColor: const Color(0xFFD97706),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 4 Key Rate & Metric Cards (2x2 Grid)
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                label: 'AVERAGE',
                value: stats.battingAverage.toStringAsFixed(1),
                icon: Icons.trending_up_rounded,
                color: const Color(0xFF2563EB),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                label: 'STRIKE RATE',
                value: stats.strikeRate.toStringAsFixed(1),
                icon: Icons.speed_rounded,
                color: const Color(0xFF8B5CF6),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                label: '4s / 6s',
                value: '${stats.fours} / ${stats.sixes}',
                subtitle: '${stats.fours * 4 + stats.sixes * 6} boundary runs',
                icon: Icons.flash_on_rounded,
                color: const Color(0xFFF43F5E),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                label: '50s / 100s',
                value: '${stats.fifties} / ${stats.hundreds}',
                subtitle: '${stats.matches} matches played',
                icon: Icons.military_tech_rounded,
                color: const Color(0xFF10B981),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBowlingCareerSection(BuildContext context, PlayerCareerStats stats, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sports_baseball_rounded, size: 16, color: Color(0xFFDC2626)),
            ),
            const SizedBox(width: 8),
            Text(
              'Bowling Career Statistics',
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Hero Row: Wickets & Best Figures
        Row(
          children: [
            Expanded(
              child: _buildHeroStatCard(
                title: 'WICKETS',
                value: '${stats.wickets}',
                subtitle: stats.wickets > 0
                    ? 'SR: ${(stats.totalLegalBallsBowled / (stats.wickets * 1.0)).toStringAsFixed(1)}'
                    : '${stats.runsConceded} Runs Conceded',
                icon: Icons.sports_baseball_rounded,
                accentColor: const Color(0xFFDC2626),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildHeroStatCard(
                title: 'BEST FIGURES',
                value: stats.bestBowling,
                subtitle: '${stats.runsConceded} Runs Conceded',
                icon: Icons.stars_rounded,
                accentColor: const Color(0xFF059669),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 4 Key Rate & Metric Cards (2x2 Grid)
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                label: 'ECONOMY',
                value: stats.bowlingEconomy.toStringAsFixed(2),
                icon: Icons.speed_rounded,
                color: const Color(0xFF3B82F6),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                label: 'AVERAGE',
                value: stats.wickets > 0 ? stats.bowlingAverage.toStringAsFixed(1) : '-',
                icon: Icons.auto_graph_rounded,
                color: const Color(0xFF7C3AED),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                label: 'OVERS BOWLED',
                value: (stats.totalLegalBallsBowled / 6.0).toStringAsFixed(1),
                subtitle: '${stats.totalLegalBallsBowled} legal balls',
                icon: Icons.replay_rounded,
                color: const Color(0xFF0284C7),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                label: 'MATCHES',
                value: '${stats.matches}',
                subtitle: 'Career appearances',
                icon: Icons.stadium_rounded,
                color: const Color(0xFF0D9488),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? accentColor.withValues(alpha: 0.12)
            : accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                    letterSpacing: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.scoreDisplay.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 10.5,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? color.withValues(alpha: 0.3)
              : color.withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.05 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.6,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 12, color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.scoreSmall.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 9.5,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
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

  void _openTeamSelectionSheet(BuildContext context, Player player, String currentTeamId) {
    final teamProv = context.read<TeamProvider>();
    final playerProv = context.read<PlayerProvider>();
    final teams = teamProv.teams;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        String searchQuery = '';
        String selectedId = currentTeamId;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filteredTeams = searchQuery.isEmpty
                ? teams
                : teams.where((t) {
                    final q = searchQuery.toLowerCase();
                    return t.name.toLowerCase().contains(q) ||
                        t.shortName.toLowerCase().contains(q);
                  }).toList();

            final screenHeight = MediaQuery.of(sheetContext).size.height;
            final maxSheetHeight = screenHeight * 0.8;

            return SafeArea(
              child: Container(
                constraints: BoxConstraints(maxHeight: maxSheetHeight),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle Bar
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black26,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.groups_rounded, size: 20, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Select Team',
                                  style: AppTextStyles.h3.copyWith(
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                Text(
                                  'Assign ${player.name} to a squad',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.of(sheetContext).pop(),
                          ),
                        ],
                      ),
                    ),

                    // Search Bar (if more than 3 teams)
                    if (teams.length > 3)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search teams...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 18),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              ),
                            ),
                            isDense: true,
                          ),
                          onChanged: (val) => setSheetState(() => searchQuery = val),
                        ),
                      ),

                    const Divider(height: 1),

                    // Teams List
                    Flexible(
                      child: filteredTeams.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: Text('No teams match your search'),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              itemCount: filteredTeams.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 8),
                              itemBuilder: (ctx, i) {
                                final t = filteredTeams[i];
                                final isSelected = t.id == selectedId;
                                final isCurrent = t.id == currentTeamId;
                                final tColor = Color(t.colorValue);

                                return InkWell(
                                  onTap: () async {
                                    if (isSelected && isCurrent) {
                                      Navigator.of(sheetContext).pop();
                                      return;
                                    }
                                    setSheetState(() => selectedId = t.id);
                                    Navigator.of(sheetContext).pop();

                                    final updated = await playerProv.changePlayerTeam(player.id, t.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${player.name} moved to ${t.name} (Jersey #${updated?.jerseyNumber ?? player.jerseyNumber})',
                                          ),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08)
                                          : (isDark ? AppColors.darkSurfaceElevated : Colors.white),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                        width: isSelected ? 1.8 : 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Team Crest
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: tColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: tColor, width: 1.5),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            t.shortName,
                                            style: TextStyle(
                                              color: tColor,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Name & Subtitle
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                t.name,
                                                style: AppTextStyles.bodyMedium.copyWith(
                                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                isCurrent ? 'Current Team' : 'Tap to transfer player',
                                                style: AppTextStyles.bodySmall.copyWith(
                                                  fontSize: 11,
                                                  color: isCurrent
                                                      ? AppColors.primary
                                                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Selected Indicator
                                        if (isSelected)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(Icons.check, size: 13, color: Colors.white),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Selected',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          Icon(
                                            Icons.radio_button_unchecked_rounded,
                                            size: 20,
                                            color: isDark ? Colors.white30 : Colors.black26,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
