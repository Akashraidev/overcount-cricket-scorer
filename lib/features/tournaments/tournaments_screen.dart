import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_state.dart';
import 'add_edit_tournament_dialog.dart';
import 'tournament_detail_screen.dart';
import 'tournament_provider.dart';

class TournamentsScreen extends StatelessWidget {
  const TournamentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tourneyProv = context.watch<TournamentProvider>();
    final tournaments = tourneyProv.tournaments;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournaments & Leagues'),
        actions: [
          AppHeaderActionButton(
            label: 'New Tournament',
            icon: Icons.add_rounded,
            margin: const EdgeInsets.only(right: 14),
            onPressed: () => AddEditTournamentDialog.show(context),
          ),
        ],
      ),
      body: tourneyProv.isLoading
          ? const LoadingState(message: 'Loading tournaments...')
          : tournaments.isEmpty
              ? EmptyState(
                  title: 'No tournaments found',
                  message: 'Create a cricket tournament or league to manage standings and fixtures.',
                  actionLabel: 'Create Tournament',
                  onAction: () => AddEditTournamentDialog.show(context),
                )
              : RefreshIndicator(
                  onRefresh: () => tourneyProv.loadTournaments(),
                  child: ListView.builder(
                    padding: AppSpacing.screenPadding,
                    itemCount: tournaments.length,
                    itemBuilder: (context, index) {
                      final t = tournaments[index];
                      final isActive = t.status.toLowerCase() == 'active';

                      return AppCard(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => TournamentDetailScreen(tournamentId: t.id),
                            ),
                          );
                        },
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.boundary6.withValues(alpha: 0.15),
                                borderRadius: AppRadius.roundedMd,
                                border: Border.all(color: AppColors.boundary6),
                              ),
                              child: const Icon(
                                Icons.emoji_events,
                                color: AppColors.boundary6,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          t.name,
                                          style: AppTextStyles.h3.copyWith(
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: (isActive ? AppColors.success : AppColors.dotBall).withValues(alpha: 0.15),
                                          borderRadius: AppRadius.roundedSm,
                                        ),
                                        child: Text(
                                          t.format,
                                          style: AppTextStyles.label.copyWith(
                                            color: isActive ? AppColors.success : AppColors.dotBall,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Started: ${DateFormatter.formatShortDate(DateTime.fromMillisecondsSinceEpoch(t.startDate))}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right, size: 20, color: AppColors.primary),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
