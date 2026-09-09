import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/responsive/responsive_breakpoints.dart';
import '../dashboard/dashboard_screen.dart';
import '../matches/create_match_wizard.dart';
import '../matches/matches_screen.dart';
import '../players/players_screen.dart';
import '../settings/settings_screen.dart';
import '../statistics/statistics_screen.dart';
import '../teams/teams_screen.dart';
import '../tournaments/tournaments_screen.dart';

class AppShell extends StatefulWidget {
  final int initialIndex;
  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _selectedIndex;

  final List<Widget> _screens = const [
    DashboardScreen(),
    MatchesScreen(),
    TeamsScreen(),
    PlayersScreen(),
    TournamentsScreen(),
    StatisticsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isTablet = ResponsiveBreakpoints.isTablet(context);

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // Desktop Sidebar
            _buildDesktopSidebar(isDark),
            const VerticalDivider(width: 1),
            // Main Content Area
            Expanded(child: _screens[_selectedIndex]),
          ],
        ),
      );
    }

    if (isTablet) {
      return Scaffold(
        body: Row(
          children: [
            // Tablet Navigation Rail
            _buildTabletNavRail(isDark),
            const VerticalDivider(width: 1),
            // Content
            Expanded(child: _screens[_selectedIndex]),
          ],
        ),
      );
    }

    // Mobile Layout: Bottom Navigation
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex > 4 ? 4 : _selectedIndex,
        onDestinationSelected: (index) {
          if (index == 4) {
            // Show more menu on mobile
            _showMobileMoreMenu(context);
          } else {
            _onDestinationSelected(index);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_cricket_outlined),
            selectedIcon: Icon(Icons.sports_cricket),
            label: 'Matches',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Teams',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar(bool isDark) {
    return Container(
      width: 250,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Column(
        children: [
          // Sidebar Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: AppRadius.roundedMd,
                  ),
                  child: const Text('🏏', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cricket Scorer',
                      style: AppTextStyles.h3.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Offline Edition',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Quick New Match Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CreateMatchWizard()),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Match'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: const RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
              ),
            ),
          ),

          const Divider(height: 24),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _sidebarItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
                _sidebarItem(1, Icons.sports_cricket_outlined, Icons.sports_cricket, 'Matches'),
                _sidebarItem(2, Icons.groups_outlined, Icons.groups, 'Teams'),
                _sidebarItem(3, Icons.person_outline, Icons.person, 'Players'),
                _sidebarItem(4, Icons.emoji_events_outlined, Icons.emoji_events, 'Tournaments'),
                _sidebarItem(5, Icons.analytics_outlined, Icons.analytics, 'Statistics'),
                _sidebarItem(6, Icons.settings_outlined, Icons.settings, 'Settings'),
              ],
            ),
          ),

          // Offline indicator at bottom
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                borderRadius: AppRadius.roundedMd,
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    '100% Offline Mode',
                    style: AppTextStyles.label.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, IconData icon, IconData activeIcon, String title) {
    final isSelected = _selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: AppRadius.roundedMd,
      ),
      child: ListTile(
        onTap: () => _onDestinationSelected(index),
        dense: true,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
        leading: Icon(
          isSelected ? activeIcon : icon,
          size: 20,
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
        title: Text(
          title,
          style: AppTextStyles.button.copyWith(
            fontSize: 13,
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTabletNavRail(bool isDark) {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onDestinationSelected,
      labelType: NavigationRailLabelType.all,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: AppRadius.roundedMd,
          ),
          child: const Text('🏏', style: TextStyle(fontSize: 20)),
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.sports_cricket_outlined),
          selectedIcon: Icon(Icons.sports_cricket),
          label: Text('Matches'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.groups_outlined),
          selectedIcon: Icon(Icons.groups),
          label: Text('Teams'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: Text('Players'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.emoji_events_outlined),
          selectedIcon: Icon(Icons.emoji_events),
          label: Text('Tournaments'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: Text('Stats'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
      ],
    );
  }

  void _showMobileMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Players'),
                onTap: () {
                  Navigator.pop(context);
                  _onDestinationSelected(3);
                },
              ),
              ListTile(
                leading: const Icon(Icons.emoji_events_outlined),
                title: const Text('Tournaments'),
                onTap: () {
                  Navigator.pop(context);
                  _onDestinationSelected(4);
                },
              ),
              ListTile(
                leading: const Icon(Icons.analytics_outlined),
                title: const Text('Statistics'),
                onTap: () {
                  Navigator.pop(context);
                  _onDestinationSelected(5);
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  _onDestinationSelected(6);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
