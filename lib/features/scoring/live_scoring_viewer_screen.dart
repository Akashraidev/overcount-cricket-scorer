import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/cricket_calc.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/ball.dart';
import '../../../data/models/batting_stat.dart';
import '../../../data/models/bowling_stat.dart';
import '../../../data/models/local_scoring_models.dart';
import 'local_scoring_provider.dart';

class LiveScoringViewerScreen extends StatefulWidget {
  const LiveScoringViewerScreen({super.key});

  @override
  State<LiveScoringViewerScreen> createState() => _LiveScoringViewerScreenState();
}

class _LiveScoringViewerScreenState extends State<LiveScoringViewerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _confirmLeaveMatch(BuildContext context, LocalScoringProvider localProv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Live Match?'),
        content: const Text('Are you sure you want to disconnect and exit the live viewer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Stay'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.of(ctx).pop();
              localProv.leaveViewerSession();
              Navigator.of(context).pop();
            },
            child: const Text('Disconnect & Leave'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localProv = context.watch<LocalScoringProvider>();
    final snapshot = localProv.liveSnapshot;
    final status = localProv.viewerStatus;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _confirmLeaveMatch(context, localProv);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _confirmLeaveMatch(context, localProv),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                snapshot?.match.title ?? 'Live Viewer',
                style: AppTextStyles.h3.copyWith(fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Row(
                children: [
                  Icon(Icons.visibility_rounded, size: 12, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text(
                    'Spectator Mode (Read-Only)',
                    style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              icon: const Icon(Icons.exit_to_app_rounded, size: 18),
              label: const Text('Leave', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _confirmLeaveMatch(context, localProv),
            ),
          ],
        ),
        body: Column(
          children: [
            // 1. Connection Status Banner
            _buildConnectionStatusBar(context, status, localProv.viewerError),

            if (snapshot == null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        status == ViewerConnectionStatus.connecting
                            ? 'Connecting to Host...'
                            : 'Waiting for match data from Host...',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    // Match Victory Banner if Complete
                    if (snapshot.isMatchComplete)
                      _buildMatchVictoryBanner(snapshot, isDark),

                    // 2. Score Summary Card
                    _buildScoreCard(snapshot, isDark),
                    const SizedBox(height: 12),

                    // 3. Batters Card
                    _buildBattersCard(snapshot, isDark),
                    const SizedBox(height: 12),

                    // 4. Bowler Card
                    _buildBowlerCard(snapshot, isDark),
                    const SizedBox(height: 12),

                    // 5. Recent Balls of Over
                    _buildRecentBalls(snapshot, isDark),
                    const SizedBox(height: 16),

                    // 6. Scorecard Tables Card
                    _buildFullScorecardCard(snapshot, isDark),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatusBar(BuildContext context, ViewerConnectionStatus status, String? error) {
    switch (status) {
      case ViewerConnectionStatus.connected:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: AppColors.success.withValues(alpha: 0.15),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_rounded, size: 16, color: AppColors.success),
              SizedBox(width: 8),
              Text(
                'Live Wi-Fi Connected • Synchronized with Host',
                style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        );
      case ViewerConnectionStatus.reconnecting:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.accent.withValues(alpha: 0.15),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
              ),
              SizedBox(width: 10),
              Text(
                'Connection Lost • Reconnecting to Host...',
                style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        );
      case ViewerConnectionStatus.disconnected:
      case ViewerConnectionStatus.rejected:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.danger.withValues(alpha: 0.15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 16, color: AppColors.danger),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  error ?? 'Disconnected from Host',
                  style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      case ViewerConnectionStatus.connecting:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: AppColors.primary.withValues(alpha: 0.12),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
              SizedBox(width: 8),
              Text(
                'Establishing Wi-Fi handshake...',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildMatchVictoryBanner(LiveMatchSnapshot snap, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: AppColors.accent, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MATCH FINISHED 🏆', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.accent)),
                Text(
                  snap.matchResultSummary ?? 'Match has ended.',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(LiveMatchSnapshot snap, bool isDark) {
    final inn = snap.currentInnings;
    final batTeam = snap.battingTeam;
    final bowlTeam = snap.bowlingTeam;

    String? targetText;
    if (snap.firstInnings != null && inn.inningsNumber == 2) {
      final target = (snap.firstInnings!.totalRuns) + 1;
      final runsNeeded = target - inn.totalRuns;
      final ballsLeft = (snap.match.totalOvers * snap.match.ballsPerOver) - inn.totalLegalBalls;
      if (runsNeeded > 0 && ballsLeft > 0) {
        targetText = '${batTeam.shortName} needs $runsNeeded runs in $ballsLeft balls';
      } else if (runsNeeded <= 0) {
        targetText = '${batTeam.name} won the match!';
      }
    }

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Teams Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Color(batTeam.colorValue),
                    child: Text(batTeam.shortName.characters.take(2).toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Text(batTeam.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 6),
                  const Text('• Batting', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                ],
              ),
              Text(
                'vs ${bowlTeam.shortName}',
                style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Big Score Display
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${inn.totalRuns}/${inn.totalWickets}',
                style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -1),
              ),
              const SizedBox(width: 12),
              Text(
                '(${inn.oversDisplay} / ${snap.match.totalOvers} ov)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Run Rates Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'CRR: ${inn.currentRunRate.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              if (targetText != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    targetText,
                    style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBattersCard(LiveMatchSnapshot snap, bool isDark) {
    final strikerStat = snap.striker != null
        ? snap.battingStats.cast<BattingStat?>().firstWhere((s) => s?.playerId == snap.striker!.id, orElse: () => null)
        : null;
    final nonStrikerStat = snap.nonStriker != null
        ? snap.battingStats.cast<BattingStat?>().firstWhere((s) => s?.playerId == snap.nonStriker!.id, orElse: () => null)
        : null;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sports_cricket_rounded, size: 16, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Batters On Crease', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const Divider(height: 16),
          // Striker Row
          _buildBatterRow(
            name: snap.striker?.name ?? 'No Striker',
            isOnStrike: true,
            runs: strikerStat?.runs ?? 0,
            balls: strikerStat?.balls ?? 0,
            fours: strikerStat?.fours ?? 0,
            sixes: strikerStat?.sixes ?? 0,
            sr: strikerStat?.strikeRate ?? 0.0,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          // Non-Striker Row
          _buildBatterRow(
            name: snap.nonStriker?.name ?? 'No Non-Striker',
            isOnStrike: false,
            runs: nonStrikerStat?.runs ?? 0,
            balls: nonStrikerStat?.balls ?? 0,
            fours: nonStrikerStat?.fours ?? 0,
            sixes: nonStrikerStat?.sixes ?? 0,
            sr: nonStrikerStat?.strikeRate ?? 0.0,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildBatterRow({
    required String name,
    required bool isOnStrike,
    required int runs,
    required int balls,
    required int fours,
    required int sixes,
    required double sr,
    required bool isDark,
  }) {
    return Row(
      children: [
        if (isOnStrike)
          const Padding(
            padding: EdgeInsets.only(right: 6),
            child: Icon(Icons.arrow_right_rounded, color: AppColors.primary, size: 20),
          )
        else
          const SizedBox(width: 20),
        Expanded(
          child: Text(
            '$name ${isOnStrike ? "*" : ""}',
            style: TextStyle(
              fontWeight: isOnStrike ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '$runs ($balls)',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(width: 14),
        Text(
          '4s:$fours 6s:$sixes',
          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
        const SizedBox(width: 14),
        Text(
          'SR: ${sr.toStringAsFixed(1)}',
          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
      ],
    );
  }

  Widget _buildBowlerCard(LiveMatchSnapshot snap, bool isDark) {
    final bowlerStat = snap.currentBowler != null
        ? snap.bowlingStats.cast<BowlingStat?>().firstWhere((s) => s?.playerId == snap.currentBowler!.id, orElse: () => null)
        : null;

    final balls = bowlerStat?.totalLegalBalls ?? 0;
    final oversStr = CricketCalc.ballsToOversString(balls);
    final maidens = bowlerStat?.maidens ?? 0;
    final runsConceded = bowlerStat?.runsConceded ?? 0;
    final wickets = bowlerStat?.wickets ?? 0;
    final econ = bowlerStat?.economy ?? 0.0;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.sports_baseball_rounded, size: 18, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  snap.currentBowler?.name ?? 'No Bowler Selected',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Bowler • Economy: ${econ.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
              ],
            ),
          ),
          Text(
            '$oversStr - $maidens - $runsConceded - $wickets',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBalls(LiveMatchSnapshot snap, bool isDark) {
    final recent = snap.recentBalls.reversed.take(12).toList().reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RECENT BALLS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          const Text('No balls bowled in this innings yet.', style: TextStyle(fontSize: 12, color: Colors.grey))
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: recent.map((b) => _buildBallBadge(b)).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildBallBadge(Ball b) {
    Color bg = Colors.grey.withValues(alpha: 0.2);
    Color textColor = Colors.black87;
    String text = '${b.totalRuns}';

    if (b.isWicket) {
      bg = AppColors.danger;
      textColor = Colors.white;
      text = 'W';
    } else if (b.totalRuns == 4) {
      bg = AppColors.boundary4;
      textColor = Colors.white;
      text = '4';
    } else if (b.totalRuns == 6) {
      bg = AppColors.boundary6;
      textColor = Colors.white;
      text = '6';
    } else if (b.extraType == 'wide') {
      bg = Colors.amber.shade700;
      textColor = Colors.white;
      text = 'Wd';
    } else if (b.extraType == 'noball') {
      bg = Colors.orange.shade700;
      textColor = Colors.white;
      text = 'Nb';
    }

    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildFullScorecardCard(LiveMatchSnapshot snap, bool isDark) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.table_chart_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Innings Scorecard (${snap.battingTeam.shortName})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          const Divider(height: 1),

          // Batting Table
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    columnSpacing: 16,
                    columns: const [
                      DataColumn(label: Text('Batter', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(numeric: true, label: Text('R', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(numeric: true, label: Text('B', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(numeric: true, label: Text('4s', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(numeric: true, label: Text('6s', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(numeric: true, label: Text('SR', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: snap.battingStats.map((s) {
                      final pName = snap.battingSquad.cast<dynamic>().firstWhere(
                            (p) => p.id == s.playerId,
                            orElse: () => null,
                          )?.name ?? 'Batter';
                      return DataRow(cells: [
                        DataCell(Text(pName, style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text('${s.runs}', style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text('${s.balls}')),
                        DataCell(Text('${s.fours}')),
                        DataCell(Text('${s.sixes}')),
                        DataCell(Text(s.strikeRate.toStringAsFixed(1))),
                      ]);
                    }).toList(),
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),

          // Bowling Table
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 12, bottom: 6),
            child: Text('Bowling Figures (${snap.bowlingTeam.shortName})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    columnSpacing: 18,
                    columns: const [
                      DataColumn(label: Text('Bowler', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(numeric: true, label: Text('O', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(numeric: true, label: Text('M', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(numeric: true, label: Text('R', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(numeric: true, label: Text('W', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(numeric: true, label: Text('Eco', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: snap.bowlingStats.map((b) {
                      final pName = snap.bowlingSquad.cast<dynamic>().firstWhere(
                            (p) => p.id == b.playerId,
                            orElse: () => null,
                          )?.name ?? 'Bowler';
                      return DataRow(cells: [
                        DataCell(Text(pName, style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(CricketCalc.ballsToOversString(b.totalLegalBalls))),
                        DataCell(Text('${b.maidens}')),
                        DataCell(Text('${b.runsConceded}')),
                        DataCell(Text('${b.wickets}', style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(b.economy.toStringAsFixed(1))),
                      ]);
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
