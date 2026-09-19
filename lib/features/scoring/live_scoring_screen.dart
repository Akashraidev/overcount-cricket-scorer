import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/responsive/responsive_breakpoints.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_dropdown.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/loading_state.dart';
import '../matches/match_provider.dart';
import '../scorecard/match_detail_screen.dart';
import 'local_scoring_provider.dart';
import 'scoring_provider.dart';
import 'widgets/current_over_track.dart';
import 'widgets/end_over_dialog.dart';
import 'widgets/extras_bottom_sheet.dart';
import 'widgets/innings_break_dialog.dart';
import 'widgets/live_batters_card.dart';
import 'widgets/live_bowler_card.dart';
import 'widgets/live_score_banner.dart';
import 'widgets/live_sharing_sheet.dart';
import 'widgets/match_complete_dialog.dart';
import 'widgets/scoring_keypad.dart';
import 'widgets/wicket_bottom_sheet.dart';

class LiveScoringScreen extends StatefulWidget {
  final String matchId;

  const LiveScoringScreen({super.key, required this.matchId});

  @override
  State<LiveScoringScreen> createState() => _LiveScoringScreenState();
}

class _LiveScoringScreenState extends State<LiveScoringScreen> {
  bool _dialogShown = false;
  bool _firstInningsConfirmDismissed = false;
  // Prevents _checkTriggers from re-opening any dialog while 2nd innings is being set up
  bool _startingSecondInnings = false;

  @override
  void initState() {
    super.initState();
    _dialogShown = false;
    _firstInningsConfirmDismissed = false;
    _startingSecondInnings = false;
    final scoringProv = context.read<ScoringProvider>();
    if (scoringProv.match?.id != widget.matchId) {
      scoringProv.clearMatchState();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScoringProvider>().loadLiveMatch(widget.matchId);
    });
  }

  void _checkTriggers(BuildContext context, ScoringProvider scoringProv) {
    // Blocked while transitioning to 2nd innings to avoid duplicate dialogs
    if (_dialogShown || _startingSecondInnings) return;

    // Safety guard: ensure the match loaded in provider actually matches this screen's matchId
    if (scoringProv.match?.id != widget.matchId) return;

    if (scoringProv.isMatchComplete && scoringProv.matchResultSummary != null) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        MatchCompleteDialog.show(
          context,
          title: scoringProv.match?.title ?? 'Match Finished',
          summary: scoringProv.matchResultSummary!,
          onViewScorecard: () {
            _dialogShown = false;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => MatchDetailScreen(matchId: widget.matchId),
              ),
            );
          },
          onHome: () {
            _dialogShown = false;
            context.read<MatchProvider>().loadMatches(silent: true);
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        );
      });
      return;
    }

    // 1st Innings Complete -> Open Innings Break Dialog once (with openers config & review option)
    if (scoringProv.isInningsComplete &&
        !scoringProv.isMatchComplete &&
        scoringProv.currentInnings?.inningsNumber == 1 &&
        !_firstInningsConfirmDismissed) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showInningsBreakDialog(context, scoringProv);
      });
      return;
    }

    if (scoringProv.isOverComplete && !scoringProv.isInningsComplete) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final completedOverNum = (scoringProv.currentInnings!.totalLegalBalls ~/ (scoringProv.match?.ballsPerOver ?? 6));
        EndOverDialog.show(
          context,
          completedOverNumber: completedOverNum,
          previousBowler: scoringProv.previousBowler ?? scoringProv.currentBowler!,
          availableBowlers: scoringProv.bowlingSquad,
          bowlingStats: scoringProv.bowlingStats,
          maxOversPerBowler: scoringProv.isUnlimitedBowlerOvers ? 0 : scoringProv.maxOversPerBowler,
          teamId: scoringProv.bowlingTeam!.id,
          onChangeBowlerLimit: (newLimit) {
            scoringProv.setMaxOversPerBowler(newLimit);
          },
          onBowlerSelected: (newBowlerId) async {
            _dialogShown = false;
            await scoringProv.changeBowler(newBowlerId);
          },
          onAddNewBowler: (name, style) async {
            return await scoringProv.addNewPlayerToSquad(
              teamId: scoringProv.bowlingTeam!.id,
              name: name,
              role: 'Bowler',
            );
          },
          onDeclareInnings: () {
            _dialogShown = false;
            _confirmDeclare(context, scoringProv);
          },
        );
      });
    }
  }

  void _showInningsBreakDialog(BuildContext context, ScoringProvider scoringProv) {
    _dialogShown = true;
    InningsBreakDialog.show(
      context,
      completedInnings: scoringProv.currentInnings!,
      team1: scoringProv.battingTeam!,
      team2: scoringProv.bowlingTeam!,
      team2Squad: scoringProv.bowlingSquad,
      team1Squad: scoringProv.battingSquad,
      onReview: () {
        _dialogShown = false;
        setState(() {
          _firstInningsConfirmDismissed = true;
        });
      },
      onAddNewPlayer: (teamId, name, role) async {
        return await scoringProv.addNewPlayerToSquad(
          teamId: teamId,
          name: name,
          role: role,
        );
      },
      onStartSecondInnings: (sId, nsId, bId) async {
        // Lock all auto-triggers while we transition innings
        setState(() {
          _startingSecondInnings = true;
          _dialogShown = false;
        });
        try {
          await scoringProv.startSecondInnings(
            strikerId: sId,
            nonStrikerId: nsId,
            bowlerId: bId,
          );
        } finally {
          // Only unlock after startSecondInnings fully completes.
          // At this point currentInnings.inningsNumber == 2, so
          // _checkTriggers' inningsNumber == 1 guard won't fire.
          if (mounted) {
            setState(() {
              _startingSecondInnings = false;
              _firstInningsConfirmDismissed = false;
            });
          }
        }
      },
    );
  }

  Widget _buildInningsCompleteBanner(
    BuildContext context,
    ScoringProvider scoringProv,
    dynamic match,
    dynamic innings,
  )
  {
    final target = innings.totalRuns + 1;
    final isOversLimit = scoringProv.isCurrentInningsOversCompleted;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    // Stats for the highlights strip
    final battingStats = scoringProv.battingStats;
    final bowlingStats = scoringProv.bowlingStats;

    // Top scorer
    final topScorer = battingStats.isNotEmpty
        ? battingStats.reduce((a, b) => a.runs > b.runs ? a : b)
        : null;
    // Best bowler (most wickets, then fewest runs)
    final bestBowler = bowlingStats.isNotEmpty
        ? bowlingStats.reduce((a, b) {
            if (a.wickets != b.wickets) return a.wickets > b.wickets ? a : b;
            return a.runsConceded < b.runsConceded ? a : b;
          })
        : null;

    // Boundary counts from balls
    final totalFours = scoringProv.allBalls.where((b) => b.runsBat == 4 && (b.extraType == 'none' || b.extraType.isEmpty)).length;
    final totalSixes = scoringProv.allBalls.where((b) => b.runsBat == 6 && (b.extraType == 'none' || b.extraType.isEmpty)).length;

    // RRR — required run rate for chasing team
    final totalOvers = match.totalOvers as int;
    final rrr = totalOvers > 0 ? (target / totalOvers).toStringAsFixed(2) : '—';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sports_cricket, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1st INNINGS CONCLUDED',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${scoringProv.battingTeam?.name ?? 'Batting Team'}: ${innings.totalRuns}/${innings.totalWickets} (${innings.oversDisplay} ov)',
                      style: AppTextStyles.h3.copyWith(fontSize: 16),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Target: $target',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Highlights strip: top scorer | best bowler | 4s | 6s | RRR
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (topScorer != null)
                  _inningsStat(
                    icon: Icons.emoji_events_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    label: topScorer.playerName.split(' ').first,
                    value: '${topScorer.runs}(${topScorer.balls})',
                    textSec: textSec,
                  ),
                if (bestBowler != null && bestBowler.wickets > 0)
                  _inningsStat(
                    icon: Icons.sports_baseball_outlined,
                    iconColor: AppColors.primary,
                    label: bestBowler.playerName.split(' ').first,
                    value: '${bestBowler.wickets}/${bestBowler.runsConceded}',
                    textSec: textSec,
                  ),
                _inningsStat(
                  icon: Icons.filter_4_rounded,
                  iconColor: AppColors.boundary4,
                  label: 'Fours',
                  value: '$totalFours',
                  textSec: textSec,
                ),
                _inningsStat(
                  icon: Icons.filter_6_rounded,
                  iconColor: AppColors.boundary6,
                  label: 'Sixes',
                  value: '$totalSixes',
                  textSec: textSec,
                ),
                _inningsStat(
                  icon: Icons.speed_rounded,
                  iconColor: AppColors.info,
                  label: 'Req RR',
                  value: rrr,
                  textSec: textSec,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Text(
            isOversLimit
                ? 'All ${match.totalOvers} overs completed for 1st innings. Ready for 2nd innings chase?'
                : '${scoringProv.bowlingTeam?.name ?? 'Chasing Team'} needs $target runs to win. Ready to begin 2nd innings?',
            style: AppTextStyles.bodySmall.copyWith(color: textSec),
          ),
          const SizedBox(height: 14),

          // Show loading while transitioning, otherwise show Start button
          if (_startingSecondInnings)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                    SizedBox(width: 10),
                    Text('Starting 2nd innings...', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            )
          else
            AppButton(
              label: 'Start 2nd Innings 🏏',
              icon: Icons.play_arrow_rounded,
              variant: AppButtonVariant.primary,
              isFullWidth: true,
              onPressed: () => _showInningsBreakDialog(context, scoringProv),
            ),

          if (!_startingSecondInnings && scoringProv.isUndoAvailable) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.undo_rounded, size: 16, color: AppColors.warning),
                label: const Text('Undo Last Ball', style: TextStyle(color: AppColors.warning, fontSize: 12)),
                onPressed: () => _confirmUndo(context, scoringProv),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Small stat cell used inside the innings highlights strip
  Widget _inningsStat({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color textSec,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        Text(label, style: TextStyle(fontSize: 10, color: textSec)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scoringProv = context.watch<ScoringProvider>();
    final localProv = context.watch<LocalScoringProvider>();
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    if (scoringProv.isLoading ||
        scoringProv.match == null ||
        scoringProv.match?.id != widget.matchId ||
        scoringProv.currentInnings == null) {
      return const Scaffold(body: LoadingState(message: 'Loading match scoring workspace...'));
    }

    // Check Over/Innings/Match transitions
    _checkTriggers(context, scoringProv);

    final match = scoringProv.match!;
    final innings = scoringProv.currentInnings!;
    final battingTeam = scoringProv.battingTeam!;
    final bowlingTeam = scoringProv.bowlingTeam!;
    final isMatchComplete = scoringProv.isMatchComplete;

    return PopScope(
      canPop: !isMatchComplete,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          context.read<MatchProvider>().loadMatches(silent: true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !isMatchComplete,
          title: Text(match.title, style: AppTextStyles.h3),
          actions: [
            if (!isMatchComplete) ...[
              // Live Wi-Fi Sharing Action
              IconButton(
                icon: Badge(
                  isLabelVisible: localProv.isHosting && localProv.viewers.isNotEmpty,
                  label: Text('${localProv.viewers.length}'),
                  backgroundColor: AppColors.success,
                  child: Icon(
                    Icons.wifi_tethering_rounded,
                    color: localProv.isHosting ? AppColors.success : null,
                  ),
                ),
                tooltip: localProv.isHosting
                    ? 'Wi-Fi Live Sharing Active (${localProv.viewers.length} Viewers)'
                    : 'Live Wi-Fi Sharing',
                onPressed: () => LiveSharingSheet.show(context),
              ),
              IconButton(
                icon: const Icon(Icons.receipt_long_rounded),
                tooltip: 'View Full Scorecard',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => MatchDetailScreen(matchId: widget.matchId),
                    ),
                  );
                },
              ),
              PopupMenuButton<String>(
                tooltip: 'Scoring Actions',
                icon: const Icon(Icons.more_vert),
                onSelected: (val) {
                  if (val == 'live_share') {
                    LiveSharingSheet.show(context);
                  } else if (val == 'bowler_limit') {
                    _showChangeBowlerLimitDialog(context, scoringProv);
                  } else if (val == 'declare') {
                    _confirmDeclare(context, scoringProv);
                  } else if (val == 'retire') {
                    _showRetireSheet(context, scoringProv);
                  } else if (val == 'add_bat') {
                    _promptQuickAddPlayer(context, scoringProv, isBatting: true);
                  } else if (val == 'add_bowl') {
                    _promptQuickAddPlayer(context, scoringProv, isBatting: false);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'live_share',
                    child: Row(
                      children: [
                        Icon(Icons.wifi_tethering_rounded, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Live Wi-Fi Sharing'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'bowler_limit',
                    child: Row(
                      children: [
                        const Icon(Icons.tune, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text('Bowler Limit (${scoringProv.isUnlimitedBowlerOvers ? 'No Limit' : '${scoringProv.maxOversPerBowler} ov'})'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'retire',
                    child: Row(
                      children: [
                        Icon(Icons.accessible_forward, size: 18, color: AppColors.warning),
                        SizedBox(width: 8),
                        Text('Retire Batsman (Hurt/Out)'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'add_bat',
                    child: Row(
                      children: [
                        Icon(Icons.person_add, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Add Player to Batting Team'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'add_bowl',
                    child: Row(
                      children: [
                        Icon(Icons.person_add_alt_1, size: 18, color: AppColors.info),
                        SizedBox(width: 8),
                        Text('Add Player to Bowling Team'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'declare',
                    child: Row(
                      children: [
                        const Icon(Icons.flag_outlined, size: 18, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Text(scoringProv.currentInnings?.inningsNumber == 1 ? 'End 1st Innings Early' : 'End Match Early'),
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              IconButton(
                icon: const Icon(Icons.receipt_long_rounded),
                tooltip: 'View Full Scorecard',
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => MatchDetailScreen(matchId: widget.matchId),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
        body: isDesktop
            ? _buildDesktopLayout(context, scoringProv, match, innings, battingTeam, bowlingTeam)
            : _buildMobileLayout(context, scoringProv, match, innings, battingTeam, bowlingTeam),
      ),
    );
  }

  // --- MOBILE 1-HANDED FAST SCORING LAYOUT ---
  Widget _buildMobileLayout(
    BuildContext context,
    ScoringProvider prov,
    dynamic match,
    dynamic innings,
    dynamic battingTeam,
    dynamic bowlingTeam,
  ) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        children: [
          // 1. Live Score Banner
          LiveScoreBanner(
            match: match,
            innings: innings,
            battingTeam: battingTeam,
            bowlingTeam: bowlingTeam,
          ),
          const SizedBox(height: 12),

          // 2. Batters Card
          LiveBattersCard(
            striker: prov.striker,
            strikerStat: prov.strikerStat,
            nonStriker: prov.nonStriker,
            nonStrikerStat: prov.nonStrikerStat,
            partnership: prov.currentPartnership,
            onSwapStrike: () => prov.swapStrike(),
            onChangeStriker: () => _showBatterPicker(context, prov, isStriker: true),
            onChangeNonStriker: () => _showBatterPicker(context, prov, isStriker: false),
          ),
          const SizedBox(height: 12),

          // 3. Current Bowler Card
          LiveBowlerCard(
            bowler: prov.currentBowler,
            bowlerStat: prov.currentBowlerStat,
            onChangeBowler: () => _showBowlerPicker(context, prov),
          ),
          const SizedBox(height: 12),

          // 4. Current Over Balls Stream
          CurrentOverTrack(
            balls: prov.currentOverBalls,
            overNumber: innings.totalLegalBalls ~/ (match.ballsPerOver),
          ),
          const SizedBox(height: 16),

          // If 1st innings complete, show Innings Break Banner instead of Keypad!
          if (prov.isInningsComplete && !prov.isMatchComplete && innings.inningsNumber == 1) ...[
            _buildInningsCompleteBanner(context, prov, match, innings),
            const SizedBox(height: 16),
          ] else if (prov.isMatchComplete) ...[
            _buildMatchVictoryCard(context, prov, match),
            const SizedBox(height: 16),
          ] else ...[
            // Helper prompt if players are not set up
            if (prov.striker == null || prov.nonStriker == null || prov.currentBowler == null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: AppRadius.roundedSm,
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please select or add both opening batters and the bowler above to begin scoring.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 5. Fast Scoring Keypad
            ScoringKeypad(
              isEnabled: !prov.isInningsComplete &&
                  !prov.isMatchComplete &&
                  !prov.isCurrentInningsOversCompleted &&
                  prov.striker != null &&
                  prov.nonStriker != null &&
                  prov.currentBowler != null,
              isUndoEnabled: prov.isUndoAvailable,
              onRunsPressed: (runs) => prov.recordRuns(runs),
              onWidePressed: () => prov.recordWide(),
              onNoBallPressed: () => _showExtrasSheet(context, prov),
              onByePressed: () => _showExtrasSheet(context, prov),
              onLegByePressed: () => _showExtrasSheet(context, prov),
              onPenaltyPressed: () => prov.recordPenalty(5),
              onWicketPressed: () => _showWicketSheet(context, prov),
              onUndoPressed: () => _confirmUndo(context, prov),
              onSwapStrike: () => prov.swapStrike(),
            ),
          ],
        ],
      ),
    );
  }

  // --- DESKTOP 3-PANE WORKSPACE LAYOUT ---
  Widget _buildDesktopLayout(
    BuildContext context,
    ScoringProvider prov,
    dynamic match,
    dynamic innings,
    dynamic battingTeam,
    dynamic bowlingTeam,
  ) {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: Match Details & Players
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  LiveBattersCard(
                    striker: prov.striker,
                    strikerStat: prov.strikerStat,
                    nonStriker: prov.nonStriker,
                    nonStrikerStat: prov.nonStrikerStat,
                    partnership: prov.currentPartnership,
                    onSwapStrike: () => prov.swapStrike(),
                    onChangeStriker: () => _showBatterPicker(context, prov, isStriker: true),
                    onChangeNonStriker: () => _showBatterPicker(context, prov, isStriker: false),
                  ),
                  const SizedBox(height: 16),
                  LiveBowlerCard(
                    bowler: prov.currentBowler,
                    bowlerStat: prov.currentBowlerStat,
                    onChangeBowler: () => _showBowlerPicker(context, prov),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Center Column: Live Score & Scoring Keypad
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  LiveScoreBanner(
                    match: match,
                    innings: innings,
                    battingTeam: battingTeam,
                    bowlingTeam: bowlingTeam,
                  ),
                  const SizedBox(height: 16),
                  CurrentOverTrack(
                    balls: prov.currentOverBalls,
                    overNumber: innings.totalLegalBalls ~/ (match.ballsPerOver),
                  ),
                  const SizedBox(height: 20),

                  // If 1st innings complete, show Innings Break Banner instead of Keypad!
                  if (prov.isInningsComplete && !prov.isMatchComplete && innings.inningsNumber == 1) ...[
                    _buildInningsCompleteBanner(context, prov, match, innings),
                    const SizedBox(height: 16),
                  ] else if (prov.isMatchComplete) ...[
                    _buildMatchVictoryCard(context, prov, match),
                    const SizedBox(height: 16),
                  ] else ...[
                    // Helper prompt if players are not set up
                    if (prov.striker == null || prov.nonStriker == null || prov.currentBowler == null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: AppRadius.roundedSm,
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Please select or add both opening batters and the bowler above to begin scoring.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    ScoringKeypad(
                      isEnabled: !prov.isInningsComplete &&
                          !prov.isMatchComplete &&
                          !prov.isCurrentInningsOversCompleted &&
                          prov.striker != null &&
                          prov.nonStriker != null &&
                          prov.currentBowler != null,
                      isUndoEnabled: prov.isUndoAvailable,
                      onRunsPressed: (runs) => prov.recordRuns(runs),
                      onWidePressed: () => prov.recordWide(),
                      onNoBallPressed: () => _showExtrasSheet(context, prov),
                      onByePressed: () => _showExtrasSheet(context, prov),
                      onLegByePressed: () => _showExtrasSheet(context, prov),
                      onPenaltyPressed: () => prov.recordPenalty(5),
                      onWicketPressed: () => _showWicketSheet(context, prov),
                      onUndoPressed: () => _confirmUndo(context, prov),
                      onSwapStrike: () => prov.swapStrike(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchVictoryCard(
    BuildContext context,
    ScoringProvider prov,
    dynamic match,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summary = prov.matchResultSummary ?? 'Match Finished!';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1E293B),
                  AppColors.primaryDark.withValues(alpha: 0.35),
                ]
              : [
                  Colors.white,
                  AppColors.primary.withValues(alpha: 0.08),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.3),
                  AppColors.primary.withValues(alpha: 0.2),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent, width: 2),
            ),
            child: const Icon(Icons.emoji_events_rounded, size: 40, color: AppColors.accent),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
            ),
            child: Text(
              '🏆 MATCH FINISHED',
              style: AppTextStyles.label.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            summary,
            style: AppTextStyles.h2.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            match.title,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          AppButton(
            label: 'View Complete Scorecard',
            icon: Icons.receipt_long_rounded,
            isFullWidth: true,
            variant: AppButtonVariant.primary,
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => MatchDetailScreen(matchId: widget.matchId),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (prov.isUndoAvailable)
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.undo_rounded, size: 16),
                    label: const Text('Undo Last Ball'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.warning,
                      side: BorderSide(color: AppColors.warning.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _confirmUndo(context, prov),
                  ),
                ),
              if (prov.isUndoAvailable) const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.home_rounded, size: 16),
                  label: const Text('Back to Dashboard'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showWicketSheet(BuildContext context, ScoringProvider prov) {
    if (prov.striker == null || prov.nonStriker == null || prov.currentBowler == null) return;

    WicketBottomSheet.show(
      context,
      striker: prov.striker!,
      nonStriker: prov.nonStriker!,
      currentBowler: prov.currentBowler!,
      fieldingSquad: prov.bowlingSquad,
      availableBatters: prov.availableBatters,
      onAddNewBatter: (name) async {
        return await prov.addNewPlayerToSquad(
          teamId: prov.battingTeam!.id,
          name: name,
          role: 'Batter',
        );
      },
      onConfirm: ({
        required String wicketType,
        required String dismissedPlayerId,
        String? fielderId,
        String? fielderName,
        required String newBatsmanId,
        int runsCompleted = 0,
      }) {
        prov.recordWicket(
          wicketType: wicketType,
          dismissedPlayerId: dismissedPlayerId,
          fielderId: fielderId,
          fielderName: fielderName,
          newBatsmanId: newBatsmanId,
          runsCompleted: runsCompleted,
        );
      },
    );
  }

  void _showExtrasSheet(BuildContext context, ScoringProvider prov) {
    ExtrasBottomSheet.show(
      context,
      onConfirm: (runsBat, extraRuns, extraType, isLegal) {
        prov.recordBall(
          runsBat: runsBat,
          extraRuns: extraRuns,
          extraType: extraType,
          isLegal: isLegal,
        );
      },
    );
  }

  void _showBowlerPicker(BuildContext context, ScoringProvider prov) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
            ),
            padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        prov.currentBowler == null ? 'Add / Select Bowler' : 'Change Bowler',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.person_add, size: 16),
                        label: const Text('Add Bowler'),
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _promptQuickAddPlayer(this.context, prov, isBatting: false, autoSelect: true);
                        },
                      ),
                    ],
                  ),
                ),
                // Quick Bowler Limit bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Theme.of(sheetContext).brightness == Brightness.dark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.lightSurfaceElevated,
                  child: Row(
                    children: [
                      const Icon(Icons.tune, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          prov.isUnlimitedBowlerOvers
                              ? 'Bowler Limit: Unlimited (No Limit)'
                              : 'Bowler Limit: Max ${prov.maxOversPerBowler} overs/bowler',
                          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _showChangeBowlerLimitDialog(this.context, prov);
                        },
                        child: const Text('Change Limit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: prov.bowlingSquad.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.sports_baseball, size: 48, color: AppColors.accent),
                                const SizedBox(height: 12),
                                const Text(
                                  'No bowlers available in squad',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Add a bowler to get started',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.person_add),
                                  label: const Text('Add Bowler Now'),
                                  onPressed: () {
                                    Navigator.pop(sheetContext);
                                    _promptQuickAddPlayer(this.context, prov, isBatting: false, autoSelect: true);
                                  },
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView(
                          children: prov.bowlingSquad.map((b) {
                            final isCurrent = b.id == prov.currentBowler?.id;
                            final completedOvers = prov.getBowlerCompletedOvers(b.id);
                            final isEligible = prov.canBowlerBowl(b.id);

                            return ListTile(
                              title: Text(b.name, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                              subtitle: Text(
                                '${b.role} • ${b.bowlingStyle} • '
                                '${prov.isUnlimitedBowlerOvers ? '$completedOvers ov (No Limit)' : '$completedOvers/${prov.maxOversPerBowler} ov'}'
                                '${!isEligible && !isCurrent ? (!prov.isUnlimitedBowlerOvers && completedOvers >= prov.maxOversPerBowler ? ' (Max Quota Reached)' : ' (Bowled Previous Over)') : ''}',
                              ),
                              trailing: isCurrent ? const Icon(Icons.check, color: AppColors.primary) : null,
                              enabled: isEligible || isCurrent,
                              onTap: () {
                                if (!isEligible && !isCurrent) {
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        !prov.isUnlimitedBowlerOvers && completedOvers >= prov.maxOversPerBowler
                                            ? '${b.name} has completed their maximum quota of ${prov.maxOversPerBowler} overs'
                                            : '${b.name} bowled the previous over and cannot bowl consecutive overs',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                Navigator.pop(sheetContext);
                                prov.changeBowler(b.id);
                              },
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBatterPicker(BuildContext context, ScoringProvider prov, {required bool isStriker}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
            ),
            padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isStriker
                            ? (prov.striker == null ? 'Select Opening Striker (*)' : 'Change Striker (*)')
                            : (prov.nonStriker == null ? 'Select Opening Non-Striker' : 'Change Non-Striker'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.person_add, size: 16),
                        label: Text(isStriker ? 'Add Striker' : 'Add Non-Striker'),
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _promptQuickAddPlayer(
                            this.context,
                            prov,
                            isBatting: true,
                            isStriker: isStriker,
                            autoSelect: true,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: prov.battingSquad.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.sports_cricket, size: 48, color: AppColors.primary),
                                const SizedBox(height: 12),
                                const Text(
                                  'No batters available in squad',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Add a player to ${prov.battingTeam?.name ?? 'batting squad'}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.person_add),
                                  label: Text(isStriker ? 'Add Striker Now' : 'Add Non-Striker Now'),
                                  onPressed: () {
                                    Navigator.pop(sheetContext);
                                    _promptQuickAddPlayer(
                                      this.context,
                                      prov,
                                      isBatting: true,
                                      isStriker: isStriker,
                                      autoSelect: true,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView(
                          children: prov.battingSquad.map((b) {
                            final currentId = isStriker ? prov.striker?.id : prov.nonStriker?.id;
                            final isCurrent = b.id == currentId;
                            final isOtherEnd = isStriker ? (b.id == prov.nonStriker?.id) : (b.id == prov.striker?.id);
                            return ListTile(
                              title: Text(
                                b.name + (isCurrent ? ' (Current)' : '') + (isOtherEnd ? ' (At Other End)' : ''),
                                style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal),
                              ),
                              subtitle: Text('${b.role} • ${b.battingStyle}'),
                              trailing: isCurrent ? const Icon(Icons.check, color: AppColors.primary) : null,
                              onTap: () {
                                Navigator.pop(sheetContext);
                                if (isStriker) {
                                  if (prov.nonStriker?.id == b.id) {
                                    prov.swapStrike();
                                  } else {
                                    prov.changeStriker(b.id);
                                  }
                                } else {
                                  if (prov.striker?.id == b.id) {
                                    prov.swapStrike();
                                  } else {
                                    prov.changeNonStriker(b.id);
                                  }
                                }
                              },
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRetireSheet(BuildContext context, ScoringProvider prov) {
    if (prov.striker == null || prov.nonStriker == null) return;

    String dismissedId = prov.striker!.id;
    bool isOut = false;
    String? newBatterId = prov.availableBatters.isNotEmpty ? prov.availableBatters.first.id : null;

    AppBottomSheet.show(
      context: context,
      title: 'RETIRE BATSMAN ⚠️',
      subtitle: 'Mark batsman retired hurt (not out) or retired out',
      child: StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Batter to Retire:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text('${prov.striker!.name} (Striker)'),
                      selected: dismissedId == prov.striker!.id,
                      onSelected: (_) => setSheetState(() => dismissedId = prov.striker!.id),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: Text('${prov.nonStriker!.name} (Non-Striker)'),
                      selected: dismissedId == prov.nonStriker!.id,
                      onSelected: (_) => setSheetState(() => dismissedId = prov.nonStriker!.id),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Retirement Reason:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Retired Hurt (Not Out)'),
                      selected: !isOut,
                      onSelected: (_) => setSheetState(() => isOut = false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Retired Out'),
                      selected: isOut,
                      onSelected: (_) => setSheetState(() => isOut = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (prov.availableBatters.isNotEmpty) ...[
                AppDropdown<String>(
                  label: 'Next Batsman In',
                  value: newBatterId ?? prov.availableBatters.first.id,
                  items: prov.availableBatters.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                  onChanged: (v) => setSheetState(() => newBatterId = v),
                ),
                const SizedBox(height: 20),
              ],
              AppButton(
                label: 'Confirm Retirement',
                isFullWidth: true,
                variant: AppButtonVariant.danger,
                onPressed: () {
                  Navigator.pop(sheetContext);
                  prov.recordRetiredHurt(
                    dismissedPlayerId: dismissedId,
                    newBatsmanId: newBatterId ?? '',
                    isOut: isOut,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _promptQuickAddPlayer(
    BuildContext context,
    ScoringProvider prov, {
    required bool isBatting,
    bool? isStriker,
    bool autoSelect = true,
  }) {
    final team = isBatting ? prov.battingTeam : prov.bowlingTeam;
    if (team == null) return;

    final nameCtrl = TextEditingController();
    String role = isBatting ? 'Batter' : 'Bowler';
    String bowlingStyle = 'Right-arm medium';

    AppDialog.show(
      context: context,
      title: 'Add Player to ${team.name}',
      content: StatefulBuilder(
        builder: (dialogCtx, setDlgState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Player Name',
                hint: isBatting ? 'e.g. Virat Kohli' : 'e.g. Jasprit Bumrah',
                controller: nameCtrl,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              AppDropdown<String>(
                label: 'Role',
                value: role,
                items: ['Batter', 'Bowler', 'All Rounder', 'Wicket Keeper']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDlgState(() => role = v);
                },
              ),
              if (!isBatting || role == 'Bowler' || role == 'All Rounder') ...[
                const SizedBox(height: 12),
                AppDropdown<String>(
                  label: 'Bowling Style',
                  value: bowlingStyle,
                  items: [
                    'Right-arm fast',
                    'Right-arm medium',
                    'Right-arm off spin',
                    'Right-arm leg spin',
                    'Left-arm fast',
                    'Left-arm medium',
                    'Left-arm orthodox',
                  ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) {
                    if (v != null) setDlgState(() => bowlingStyle = v);
                  },
                ),
              ],
            ],
          );
        },
      ),
      confirmLabel: autoSelect ? (isBatting ? 'Add & Set Batter' : 'Add & Set Bowler') : 'Add Player',
      onConfirm: () async {
        final name = nameCtrl.text.trim();
        if (name.isNotEmpty) {
          Navigator.of(this.context, rootNavigator: true).pop();
          final created = await prov.addNewPlayerToSquad(
            teamId: team.id,
            name: name,
            role: role,
            bowlingStyle: bowlingStyle,
          );

          if (!isBatting && autoSelect) {
            await prov.changeBowler(created.id);
            if (mounted) {
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text('$name added and set as current bowler!'),
                  backgroundColor: AppColors.primary,
                ),
              );
            }
          } else if (isBatting && autoSelect) {
            if (isStriker == true) {
              await prov.changeStriker(created.id);
            } else if (isStriker == false) {
              await prov.changeNonStriker(created.id);
            } else {
              if (prov.striker == null) {
                await prov.changeStriker(created.id);
              } else if (prov.nonStriker == null) {
                await prov.changeNonStriker(created.id);
              }
            }
            if (mounted) {
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text('$name added and set to bat!'),
                  backgroundColor: AppColors.primary,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(content: Text('$name added to ${team.name}!')),
              );
            }
          }
        }
      },
    );
  }

  void _confirmUndo(BuildContext context, ScoringProvider prov) {
    if (!prov.isUndoAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No balls recorded yet to undo')),
      );
      return;
    }

    AppDialog.show(
      context: context,
      title: 'Undo Last Ball? ↩️',
      content: const Text(
        'This will revert:\n• Total score & extras\n• Batsman runs & balls\n• Bowler figures & economy\n• Over count & strike position\n• Wickets & fall-of-wicket',
      ),
      confirmLabel: 'Yes, Undo',
      cancelLabel: 'Cancel',
      isDestructive: true,
      onConfirm: () async {
        Navigator.of(context).pop();
        setState(() {
          _firstInningsConfirmDismissed = false;
          _dialogShown = false;
        });
        await prov.undoLastBall();
      },
    );
  }

  void _confirmDeclare(BuildContext context, ScoringProvider prov) {
    final isInnings1 = prov.currentInnings?.inningsNumber == 1;
    AppDialog.show(
      context: context,
      title: isInnings1 ? 'End 1st Innings Early?' : 'End Match Early?',
      content: Text(
        'Are you sure you want to end this innings at ${prov.currentInnings?.totalRuns}/${prov.currentInnings?.totalWickets}?\n\n'
        '${isInnings1 ? "This will conclude the 1st innings and start the 2nd innings break." : "This will conclude the match with current scores."}',
      ),
      confirmLabel: isInnings1 ? 'End 1st Innings' : 'End Match',
      cancelLabel: 'Cancel',
      isDestructive: true,
      onConfirm: () async {
        Navigator.of(context).pop();
        setState(() {
          _firstInningsConfirmDismissed = true;
        });
        await prov.declareInnings();
        if (isInnings1 && mounted) {
          _showInningsBreakDialog(this.context, prov);
        }
      },
    );
  }

  void _showChangeBowlerLimitDialog(BuildContext context, ScoringProvider prov) {
    final ctrl = TextEditingController(text: prov.isUnlimitedBowlerOvers ? '' : '${prov.maxOversPerBowler}');
    bool setUnlimited = prov.isUnlimitedBowlerOvers;

    AppDialog.show(
      context: context,
      title: 'Bowler Over Limit ⚙️',
      content: StatefulBuilder(
        builder: (ctx, setDlgState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: const Text('No Limit (Unlimited Overs)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Any bowler can bowl unlimited overs'),
                value: setUnlimited,
                onChanged: (val) => setDlgState(() => setUnlimited = val ?? false),
              ),
              if (!setUnlimited) ...[
                const SizedBox(height: 10),
                AppTextField(
                  label: 'Max Overs per Bowler',
                  hint: 'e.g. 4',
                  keyboardType: TextInputType.number,
                  controller: ctrl,
                ),
              ],
            ],
          );
        },
      ),
      confirmLabel: 'Apply Limit',
      onConfirm: () {
        Navigator.pop(context);
        final newLimit = setUnlimited ? 0 : (int.tryParse(ctrl.text.trim()) ?? 4);
        prov.setMaxOversPerBowler(newLimit);
        if (mounted) {
          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(
              content: Text(setUnlimited ? 'Bowler over limit removed (Unlimited)' : 'Bowler limit set to $newLimit overs per bowler'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      },
    );
  }
}
