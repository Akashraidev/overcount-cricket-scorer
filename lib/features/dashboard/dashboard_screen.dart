import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/responsive/responsive_breakpoints.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/match_tile.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_tile.dart';
import '../matches/create_match_wizard.dart';
import '../matches/match_provider.dart';
import '../players/add_edit_player_dialog.dart';
import '../players/player_provider.dart';
import '../scorecard/match_detail_screen.dart';
import '../scoring/live_scoring_screen.dart';
import '../scoring/widgets/join_match_dialog.dart';
import '../../main.dart';
import '../teams/add_edit_team_dialog.dart';
import '../teams/team_provider.dart';
import '../tournaments/add_edit_tournament_dialog.dart';
import '../tournaments/tournament_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with RouteAware {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MatchProvider>().loadMatches(silent: true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    // Automatically called when returning to dashboard from scoring or any screen
    if (mounted) {
      context.read<MatchProvider>().loadMatches(silent: true);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 👋';
    if (hour < 17) return 'Good Afternoon 👋';
    return 'Good Evening 👋';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    final matchProv = context.watch<MatchProvider>();
    final teamProv = context.watch<TeamProvider>();
    final playerProv = context.watch<PlayerProvider>();
    final tourneyProv = context.watch<TournamentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            Text(
              'Cricket Scorer',
              style: AppTextStyles.h2.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
        actions: [
          AppHeaderActionButton(
            label: 'New Match',
            icon: Icons.add_rounded,
            margin: const EdgeInsets.only(right: 14),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CreateMatchWizard()),
              );
              if (!mounted) return;
              this.context.read<MatchProvider>().loadMatches(silent: true);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await matchProv.loadMatches();
          await teamProv.loadTeams();
          await playerProv.loadPlayers();
          await tourneyProv.loadTournaments();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Summary Metric Tiles Grid
              _buildMetricsGrid(
                context,
                matchesCount: matchProv.matchCounts['total'] ?? 0,
                teamsCount: teamProv.teams.length,
                playersCount: playerProv.players.length,
                tourneysCount: tourneyProv.tournaments.length,
                isDesktop: isDesktop,
              ),
              const SizedBox(height: 24),

              // 2. Continue Live Match Card (if available)
              if (matchProv.activeMatch != null) ...[
                _buildContinueMatchCard(context, matchProv, teamProv),
                const SizedBox(height: 24),
              ],

              // 3. Quick Actions
              _buildQuickActions(context),
              const SizedBox(height: 24),

              // 4. Recent Matches List
              SectionHeader(
                title: 'Recent Matches',
                actionLabel: 'View All',
                onAction: () {
                  // Navigate to Matches tab in shell or list
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const Scaffold(
                        body: SafeArea(child: Text('Matches')),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              if (matchProv.recentMatches.isEmpty)
                AppCard(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.sports_cricket_outlined, size: 36, color: AppColors.primary),
                        const SizedBox(height: 8),
                        Text(
                          'No matches recorded yet',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppButton(
                          label: 'Create First Match',
                          icon: Icons.add,
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const CreateMatchWizard()),
                            );
                            if (!mounted) return;
                            this.context.read<MatchProvider>().loadMatches(silent: true);
                          },
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...matchProv.recentMatches.map((m) {
                  final teamA = teamProv.teams.firstWhere(
                    (t) => t.id == m.teamAId,
                    orElse: () => teamProv.teams.isNotEmpty ? teamProv.teams.first : teamProv.teams.first,
                  );
                  final teamB = teamProv.teams.firstWhere(
                    (t) => t.id == m.teamBId,
                    orElse: () => teamProv.teams.length > 1 ? teamProv.teams[1] : teamProv.teams.first,
                  );

                  return MatchTile(
                    match: m,
                    teamA: teamA,
                    teamB: teamB,
                    inningsList: matchProv.getInningsForMatch(m.id),
                    onContinueScoring: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => LiveScoringScreen(matchId: m.id),
                        ),
                      );
                      if (!mounted) return;
                      this.context.read<MatchProvider>().loadMatches(silent: true);
                    },
                    onViewScorecard: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => MatchDetailScreen(matchId: m.id),
                        ),
                      );
                      if (!mounted) return;
                      this.context.read<MatchProvider>().loadMatches(silent: true);
                    },
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(
    BuildContext context, {
    required int matchesCount,
    required int teamsCount,
    required int playersCount,
    required int tourneysCount,
    required bool isDesktop,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: constraints.maxWidth > 800 ? 2.2 : 1.6,
          children: [
            StatTile(
              label: 'Matches',
              value: '$matchesCount',
              icon: Icons.sports_cricket,
              accentColor: AppColors.primary,
            ),
            StatTile(
              label: 'Teams',
              value: '$teamsCount',
              icon: Icons.groups,
              accentColor: AppColors.accent,
            ),
            StatTile(
              label: 'Players',
              value: '$playersCount',
              icon: Icons.person,
              accentColor: AppColors.boundary4,
            ),
            StatTile(
              label: 'Tournaments',
              value: '$tourneysCount',
              icon: Icons.emoji_events,
              accentColor: AppColors.boundary6,
            ),
          ],
        );
      },
    );
  }

  Widget _buildContinueMatchCard(
    BuildContext context,
    MatchProvider matchProv,
    TeamProvider teamProv,
  ) {
    final active = matchProv.activeMatch!;
    final inn = matchProv.activeMatchCurrentInnings;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final teamA = teamProv.teams.firstWhere(
      (t) => t.id == active.teamAId,
      orElse: () => teamProv.teams.first,
    );
    final teamB = teamProv.teams.firstWhere(
      (t) => t.id == active.teamBId,
      orElse: () => teamProv.teams.length > 1 ? teamProv.teams[1] : teamProv.teams.first,
    );

    return AppCard(
      gradient: isDark ? AppColors.heroCardGradient : null,
      backgroundColor: isDark ? null : const Color(0xFFE8F5E9),
      borderColor: AppColors.primary,
      hasGlow: true,
      glowColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.liveRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ONGOING MATCH',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: AppRadius.roundedSm,
                ),
                child: Text(
                  active.format,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${teamA.name} vs ${teamB.name}',
            style: AppTextStyles.h3.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          Text(
            active.title,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          if (inn != null) ...[
            Row(
              children: [
                Text(
                  '${inn.totalRuns}/${inn.totalWickets}',
                  style: AppTextStyles.scoreMedium.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${inn.oversDisplay} ov',
                        style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '•  CRR ${inn.currentRunRate.toStringAsFixed(2)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          AppButton(
            label: 'Continue Scoring',
            icon: Icons.play_arrow_rounded,
            height: 40,
            isFullWidth: true,
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LiveScoringScreen(matchId: active.id),
                ),
              );
              if (!mounted) return;
              this.context.read<MatchProvider>().loadMatches(silent: true);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Quick Actions'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _quickActionBtn(
                context,
                icon: Icons.sports_cricket,
                label: 'New Match',
                color: AppColors.primary,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const CreateMatchWizard()),
                  );
                  if (!mounted) return;
                  this.context.read<MatchProvider>().loadMatches(silent: true);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _quickActionBtn(
                context,
                icon: Icons.group_add,
                label: 'Add Team',
                color: AppColors.accent,
                onTap: () => AddEditTeamDialog.show(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _quickActionBtn(
                context,
                icon: Icons.person_add,
                label: 'Add Player',
                color: AppColors.boundary4,
                onTap: () => AddEditPlayerDialog.show(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _quickActionBtn(
                context,
                icon: Icons.emoji_events,
                label: 'Tournament',
                color: AppColors.boundary6,
                onTap: () => AddEditTournamentDialog.show(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Join Wi-Fi Live Match Action Card
        InkWell(
          onTap: () => JoinMatchDialog.show(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.wifi_tethering_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Join Live Match on Wi-Fi',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        'Enter 6-digit code to spectate live scorecard (Read-Only)',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _quickActionBtn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: AppRadius.roundedSm,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
