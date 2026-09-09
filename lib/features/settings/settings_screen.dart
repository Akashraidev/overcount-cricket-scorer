import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/section_header.dart';
import '../matches/match_provider.dart';
import '../players/player_provider.dart';
import '../teams/team_provider.dart';
import '../tournaments/tournament_provider.dart';
import 'settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences & Settings'),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          // 1. Theme Configuration Card
          const SectionHeader(title: 'Appearance'),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme Mode',
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _themeOption(
                        context,
                        title: 'Dark Mode',
                        icon: Icons.dark_mode_outlined,
                        isSelected: settings.themeMode == ThemeMode.dark,
                        onTap: () => settings.setThemeMode(ThemeMode.dark),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _themeOption(
                        context,
                        title: 'Light Mode',
                        icon: Icons.light_mode_outlined,
                        isSelected: settings.themeMode == ThemeMode.light,
                        onTap: () => settings.setThemeMode(ThemeMode.light),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _themeOption(
                        context,
                        title: 'System',
                        icon: Icons.settings_brightness_outlined,
                        isSelected: settings.themeMode == ThemeMode.system,
                        onTap: () => settings.setThemeMode(ThemeMode.system),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Scoring Preferences
          const SectionHeader(title: 'Live Scoring Options'),
          const SizedBox(height: 12),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Touch Haptic Feedback'),
                  subtitle: const Text('Vibrate subtly on score pad and boundary taps'),
                  value: settings.hapticsEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (v) => settings.setHapticsEnabled(v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Dynamic Ball Commentary'),
                  subtitle: const Text('Auto-generate cricket commentary for deliveries and wickets'),
                  value: settings.autoCommentaryEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (v) => settings.setAutoCommentaryEnabled(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. Database & Offline Storage
          const SectionHeader(title: 'Data & Database Management'),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.storage_rounded, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SQLite Local Database', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                        Text('100% Offline • Zero Internet Required', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Re-Seed Sample Demo Data',
                  icon: Icons.restore_page_outlined,
                  variant: AppButtonVariant.secondary,
                  isFullWidth: true,
                  isLoading: settings.isLoading,
                  onPressed: () => _confirmReseed(context, settings),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. App Info
          Center(
            child: Column(
              children: [
                Text(
                  '🏏 Cricket Scorecard App',
                  style: AppTextStyles.label.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Production Offline Edition • v1.0.0',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _themeOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.roundedMd,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated),
          borderRadius: AppRadius.roundedMd,
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: isSelected ? AppColors.primary : null),
            const SizedBox(height: 6),
            Text(
              title,
              style: AppTextStyles.label.copyWith(
                color: isSelected ? AppColors.primary : null,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReseed(BuildContext context, SettingsProvider settings) {
    AppDialog.show(
      context: context,
      title: 'Reset & Re-seed Data?',
      content: const Text(
        'This will reset the local database and populate realistic international tournaments, teams (IND, AUS, ENG, SA), squads, and sample live/completed matches.',
      ),
      confirmLabel: 'Re-seed Data',
      cancelLabel: 'Cancel',
      isDestructive: true,
      onConfirm: () async {
        Navigator.of(context).pop();
        await settings.resetAndReseedDatabase();
        if (context.mounted) {
          await context.read<TeamProvider>().loadTeams();
          await context.read<PlayerProvider>().loadPlayers();
          await context.read<TournamentProvider>().loadTournaments();
          await context.read<MatchProvider>().loadMatches();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sample data seeded successfully!')),
          );
        }
      },
    );
  }
}
