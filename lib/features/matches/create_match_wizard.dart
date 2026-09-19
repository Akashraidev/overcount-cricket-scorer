import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_dropdown.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/suggestion_text_field.dart';
import '../../data/models/team.dart';
import '../../data/models/player.dart';
import '../players/player_provider.dart';
import '../scoring/live_scoring_screen.dart';
import '../scoring/scoring_provider.dart';
import '../teams/add_edit_team_dialog.dart';
import '../teams/team_provider.dart';
import '../tournaments/tournament_provider.dart';
import 'match_provider.dart';

class CreateMatchWizard extends StatefulWidget {
  const CreateMatchWizard({super.key});

  @override
  State<CreateMatchWizard> createState() => _CreateMatchWizardState();
}

class _CreateMatchWizardState extends State<CreateMatchWizard> {
  int _currentStep = 0;
  final _formKeyStep1 = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _venueController;
  late TextEditingController _oversController;
  late TextEditingController _wicketsController;
  late TextEditingController _bowlerLimitController;

  final List<String> _formats = const ['T20', 'T10', 'ODI', 'Test', 'Custom'];

  final List<String> _defaultTitles = const [
    'Final: Championship Match',
    'Semi Final Match',
    'League Match 1',
    'Sunday Friendly Match',
    'T20 Cup Match',
  ];

  final List<String> _defaultVenues = const [
    'Ekana Cricket Stadium, Lucknow',
    'Narendra Modi Stadium, Ahmedabad',
    'Wankhede Stadium, Mumbai',
    'Eden Gardens, Kolkata',
    'M. Chinnaswamy Stadium, Bengaluru',
    'Lord\'s Cricket Ground, London',
    'MCG, Melbourne',
    'Local Sports Ground',
  ];

  @override
  void initState() {
    super.initState();
    final draft = context.read<MatchProvider>().draft;
    _titleController = TextEditingController(text: draft.title);
    _venueController = TextEditingController(text: draft.venue);
    _oversController = TextEditingController(text: '${draft.totalOvers}');
    _wicketsController = TextEditingController(text: '${draft.wicketsPerInnings}');
    _bowlerLimitController = TextEditingController(
      text: draft.maxOversPerBowler == 0
          ? ''
          : (draft.maxOversPerBowler != null
              ? '${draft.maxOversPerBowler}'
              : '${(draft.totalOvers / 5).ceil()}'),
    );

    // Safe default selection of teams if available
    final teams = context.read<TeamProvider>().teams;
    if (draft.teamAId == null && teams.isNotEmpty) {
      draft.teamAId = teams[0].id;
    }
    if (draft.teamBId == null && teams.length > 1) {
      draft.teamBId = teams[1].id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _venueController.dispose();
    _oversController.dispose();
    _wicketsController.dispose();
    _bowlerLimitController.dispose();
    super.dispose();
  }

  Team? _getTeam(TeamProvider teamProv, String? teamId, {int fallbackIndex = 0}) {
    final teams = teamProv.teams;
    if (teams.isEmpty) return null;
    if (teamId != null) {
      try {
        return teams.firstWhere((t) => t.id == teamId);
      } catch (_) {}
    }
    if (fallbackIndex < teams.length) {
      return teams[fallbackIndex];
    }
    return teams.first;
  }

  void _onFormatChanged(String format) {
    final draft = context.read<MatchProvider>().draft;
    draft.format = format;
    switch (format) {
      case 'T10':
        draft.totalOvers = 10;
        _oversController.text = '10';
        draft.maxOversPerBowler = 2;
        _bowlerLimitController.text = '2';
        break;
      case 'T20':
        draft.totalOvers = 20;
        _oversController.text = '20';
        draft.maxOversPerBowler = 4;
        _bowlerLimitController.text = '4';
        break;
      case 'ODI':
        draft.totalOvers = 50;
        _oversController.text = '50';
        draft.maxOversPerBowler = 10;
        _bowlerLimitController.text = '10';
        break;
      case 'Test':
        draft.totalOvers = 90;
        _oversController.text = '90';
        draft.maxOversPerBowler = 0;
        _bowlerLimitController.text = '';
        break;
      default:
        break;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final matchProv = context.watch<MatchProvider>();
    final teamProv = context.watch<TeamProvider>();
    final tourneyProv = context.watch<TournamentProvider>();
    final draft = matchProv.draft;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Match'),
      ),
      body: Column(
        children: [
          // Step Progress Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            child: Row(
              children: List.generate(5, (index) {
                final isPassed = index <= _currentStep;
                final isCurrent = index == _currentStep;
                return Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isPassed
                              ? AppColors.primary
                              : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated),
                          shape: BoxShape.circle,
                          border: isCurrent ? Border.all(color: Colors.white, width: 2) : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: AppTextStyles.label.copyWith(
                            color: isPassed
                                ? Colors.white
                                : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (index < 4)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: index < _currentStep
                                ? AppColors.primary
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),

          // Step Content
          Expanded(
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: _buildStepContent(context, draft, teamProv, tourneyProv),
            ),
          ),

          // Bottom Navigation Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                if (_currentStep > 0) ...[
                  Expanded(
                    child: AppButton(
                      label: 'Previous',
                      variant: AppButtonVariant.secondary,
                      onPressed: () => setState(() => _currentStep--),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: AppButton(
                    label: _currentStep == 4 ? 'START MATCH 🏏' : 'Next Step',
                    onPressed: () => _handleNextStep(context, draft, teamProv),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    CreateMatchDraft draft,
    TeamProvider teamProv,
    TournamentProvider tourneyProv,
  ) {
    switch (_currentStep) {
      case 0:
        return _buildStep1MatchDetails(context, draft, tourneyProv);
      case 1:
        return _buildStep2Teams(context, draft, teamProv);
      case 2:
        return _buildStep3PlayingXi(context, draft, teamProv);
      case 3:
        return _buildStep4Toss(context, draft, teamProv);
      case 4:
        return _buildStep5Summary(context, draft, teamProv);
      default:
        return const SizedBox();
    }
  }

  // --- STEP 1: MATCH DETAILS (WITH FOCUS/SUGGESTION DROPDOWNS & DELETE) ---
  Widget _buildStep1MatchDetails(
    BuildContext context,
    CreateMatchDraft draft,
    TournamentProvider tourneyProv,
  ) {
    return Form(
      key: _formKeyStep1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Step 1 — Match Information'),
          const SizedBox(height: 16),

          // Match Title with Suggestion Dropdown + Delete option + Auto-save
          SuggestionTextField(
            label: 'Match Title',
            hint: 'e.g. Final: India vs Australia',
            controller: _titleController,
            prefKey: 'saved_match_titles',
            defaultSuggestions: _defaultTitles,
            prefixIcon: Icons.sports_cricket,
            onChanged: (v) => draft.title = v,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a match title' : null,
          ),
          const SizedBox(height: 14),

          if (tourneyProv.tournaments.isNotEmpty) ...[
            AppDropdown<String?>(
              label: 'Tournament (Optional)',
              value: draft.tournamentId,
              hint: 'Select Tournament',
              items: [
                const DropdownMenuItem(value: null, child: Text('Friendly / Bilateral Series')),
                ...tourneyProv.tournaments.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
              ],
              onChanged: (v) => setState(() => draft.tournamentId = v),
            ),
            const SizedBox(height: 14),
          ],

          // Venue with Suggestion Dropdown + Delete option + Auto-save
          SuggestionTextField(
            label: 'Venue / Stadium',
            hint: 'e.g. Wankhede Stadium, Mumbai',
            controller: _venueController,
            prefKey: 'saved_venues',
            defaultSuggestions: _defaultVenues,
            prefixIcon: Icons.stadium_outlined,
            onChanged: (v) => draft.venue = v,
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: AppDropdown<String>(
                  label: 'Format',
                  value: draft.format,
                  items: _formats.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (v) {
                    if (v != null) _onFormatChanged(v);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: 'Total Overs',
                  hint: '20',
                  keyboardType: TextInputType.number,
                  controller: _oversController,
                  onChanged: (v) => draft.totalOvers = int.tryParse(v) ?? 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Wickets Per Innings',
                  hint: '10',
                  keyboardType: TextInputType.number,
                  controller: _wicketsController,
                  onChanged: (v) => draft.wicketsPerInnings = int.tryParse(v) ?? 10,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Match Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  subtitle: Text(DateFormatter.formatShortDate(draft.matchDate)),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: draft.matchDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) setState(() => draft.matchDate = picked);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Bowler Bowling Limit Setting
          Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final defaultQuota = (draft.totalOvers / 5).ceil();

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bowler Over Limit',
                          style: AppTextStyles.label.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        FilterChip(
                          label: const Text('No Limit (Unlimited)'),
                          selected: draft.maxOversPerBowler == 0,
                          onSelected: (selected) {
                            setState(() {
                              draft.maxOversPerBowler = selected ? 0 : defaultQuota;
                              _bowlerLimitController.text = selected ? '' : '$defaultQuota';
                            });
                          },
                        ),
                      ],
                    ),
                    if (draft.maxOversPerBowler != 0) ...[
                      const SizedBox(height: 8),
                      AppTextField(
                        label: 'Max Overs per Bowler',
                        hint: '$defaultQuota',
                        keyboardType: TextInputType.number,
                        controller: _bowlerLimitController,
                        onChanged: (v) {
                          draft.maxOversPerBowler = int.tryParse(v);
                        },
                      ),
                    ] else
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Any bowler can bowl unlimited overs without restriction.',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- STEP 2: TEAMS SELECTION (EASY CREATION & INSTANT DISPLAY) ---
  Widget _buildStep2Teams(BuildContext context, CreateMatchDraft draft, TeamProvider teamProv) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final teams = teamProv.teams;

    final teamA = _getTeam(teamProv, draft.teamAId, fallbackIndex: 0);
    final teamB = _getTeam(teamProv, draft.teamBId, fallbackIndex: 1);

    if (draft.teamAId == null && teamA != null) {
      draft.teamAId = teamA.id;
    }
    if (draft.teamBId == null && teamB != null && teamB.id != teamA?.id) {
      draft.teamBId = teamB.id;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionHeader(title: 'Step 2 — Select Teams'),
            AppHeaderActionButton(
              label: 'New Team',
              icon: Icons.add_rounded,
              onPressed: () async {
                final created = await AddEditTeamDialog.show(context);
                if (created != null && mounted) {
                  await teamProv.loadTeams();
                  setState(() {
                    if (draft.teamAId == null) {
                      draft.teamAId = created.id;
                    } else if (draft.teamBId == null || draft.teamBId == draft.teamAId) {
                      draft.teamBId = created.id;
                    }
                  });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Select two teams or create new teams to compete in this match.',
          style: AppTextStyles.bodySmall.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 20),

        // Team A Card
        _buildTeamCard(
          context,
          title: 'TEAM A (HOME)',
          selectedTeam: teamA,
          allTeams: teams,
          onTeamSelected: (teamId) {
            setState(() {
              draft.teamAId = teamId;
              draft.teamAPlayingXi.clear();
              draft.openingStrikerId = null;
              draft.openingNonStrikerId = null;
              draft.openingBowlerId = null;
              if (draft.teamBId == teamId) {
                final other = teams.firstWhere((t) => t.id != teamId, orElse: () => teamProv.teams.first);
                draft.teamBId = other.id;
                draft.teamBPlayingXi.clear();
              }
            });
          },
          onCreateTeam: () async {
            final created = await AddEditTeamDialog.show(context);
            if (created != null && mounted) {
              await teamProv.loadTeams();
              setState(() {
                draft.teamAId = created.id;
                draft.teamAPlayingXi.clear();
                draft.openingStrikerId = null;
                draft.openingNonStrikerId = null;
                draft.openingBowlerId = null;
              });
            }
          },
        ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(child: Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, thickness: 1.2)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.4), width: 1.2),
                  ),
                  child: Text(
                    'V E R S U S',
                    style: AppTextStyles.label.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: AppColors.accent,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              Expanded(child: Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, thickness: 1.2)),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Team B Card
        _buildTeamCard(
          context,
          title: 'TEAM B (AWAY)',
          selectedTeam: teamB != null && teamB.id != teamA?.id ? teamB : null,
          allTeams: teams.where((t) => t.id != draft.teamAId).toList(),
          onTeamSelected: (teamId) {
            setState(() {
              draft.teamBId = teamId;
              draft.teamBPlayingXi.clear();
              draft.openingStrikerId = null;
              draft.openingNonStrikerId = null;
              draft.openingBowlerId = null;
            });
          },
          onCreateTeam: () async {
            final created = await AddEditTeamDialog.show(context);
            if (created != null && mounted) {
              await teamProv.loadTeams();
              setState(() {
                draft.teamBId = created.id;
                draft.teamBPlayingXi.clear();
                draft.openingStrikerId = null;
                draft.openingNonStrikerId = null;
                draft.openingBowlerId = null;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildTeamCard(
    BuildContext context, {
    required String title,
    required Team? selectedTeam,
    required List<Team> allTeams,
    required ValueChanged<String> onTeamSelected,
    required VoidCallback onCreateTeam,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (selectedTeam == null) {
      return InkWell(
        onTap: allTeams.isNotEmpty
            ? () => _showTeamPickerModal(context, allTeams, onTeamSelected)
            : onCreateTeam,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.primary.withValues(alpha: 0.4) : AppColors.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primary.withValues(alpha: 0.18)
                      : AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
                ),
                child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Tap to select or create team',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text('Select', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final teamColor = Color(selectedTeam.colorValue);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: teamColor.withValues(alpha: 0.8), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: teamColor.withValues(alpha: 0.1),
            blurRadius: 8,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: teamColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    color: teamColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    fontSize: 11,
                  ),
                ),
              ),
              InkWell(
                onTap: () => _showTeamPickerModal(context, allTeams, onTeamSelected),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.swap_horiz, size: 16, color: AppColors.primaryLight),
                      SizedBox(width: 4),
                      Text(
                        'Change',
                        style: TextStyle(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: teamColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: teamColor.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  selectedTeam.shortName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedTeam.name,
                      style: AppTextStyles.h3.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Code: ${selectedTeam.shortName}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
            ],
          ),
        ],
      ),
    );
  }

  void _showTeamPickerModal(
    BuildContext context,
    List<Team> teams,
    ValueChanged<String> onSelected,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Select Team', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  children: teams.map((t) {
                    final color = Color(t.colorValue);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color,
                        child: Text(t.shortName, style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                      title: Text(t.name),
                      subtitle: Text(t.shortName),
                      onTap: () {
                        Navigator.pop(context);
                        onSelected(t.id);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- STEP 3: PLAYING XI / SQUAD SELECTION ---
  Widget _buildStep3PlayingXi(BuildContext context, CreateMatchDraft draft, TeamProvider teamProv) {
    final teamA = _getTeam(teamProv, draft.teamAId, fallbackIndex: 0);
    final teamB = _getTeam(teamProv, draft.teamBId, fallbackIndex: 1);

    if (teamA == null || teamB == null) {
      return const Text('Please select two teams in Step 2 first.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionHeader(title: 'Step 3 — Playing XI Squads'),
            AppHeaderActionButton(
              label: 'Add Player',
              icon: Icons.person_add_rounded,
              onPressed: () => _promptAddPlayerChoice(context, teamA, teamB),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: const Row(
            children: [
              Icon(Icons.touch_app_outlined, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tap to select/deselect. Long-press & drag a player to transfer between teams.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Team A Squad
        _buildSquadSelector(context, team: teamA, isTeamA: true, draft: draft),
        const SizedBox(height: 24),

        // Team B Squad
        _buildSquadSelector(context, team: teamB, isTeamA: false, draft: draft),
      ],
    );
  }

  Widget _buildSquadSelector(
    BuildContext context, {
    required Team team,
    required bool isTeamA,
    required CreateMatchDraft draft,
  }) {
    final playerProv = context.watch<PlayerProvider>();
    final players = playerProv.players.where((p) => p.teamId == team.id).toList();
    final playingXi = isTeamA ? draft.teamAPlayingXi : draft.teamBPlayingXi;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final teamColor = Color(team.colorValue);

    // Default select all if empty
    if (playingXi.isEmpty && players.isNotEmpty) {
      playingXi.addAll(players.map((p) => p.id));
    }

    return DragTarget<Player>(
      onWillAcceptWithDetails: (details) => details.data.teamId != team.id,
      onAcceptWithDetails: (details) async {
        await _movePlayerToTeam(context, details.data, team, isTeamA, draft);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovering ? AppColors.accent : Colors.transparent,
              width: 2,
            ),
          ),
          child: AppCard(
            borderColor: isHovering ? AppColors.accent : null,
            backgroundColor: isHovering
                ? (isDark ? AppColors.accent.withValues(alpha: 0.15) : const Color(0xFFFFF9C4))
                : null,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isHovering) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.accent, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.file_download_outlined, color: AppColors.accent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Drop here to transfer to ${team.name}',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: teamColor.withValues(alpha: 0.18),
                      child: Text(
                        team.shortName.length > 3 ? team.shortName.substring(0, 3) : team.shortName,
                        style: TextStyle(
                          color: teamColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            team.name,
                            style: AppTextStyles.h3.copyWith(
                              fontSize: 15,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${playingXi.length} of ${players.length} players selected',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.person_add_rounded, size: 15, color: AppColors.primary),
                      label: const Text(
                        'Add Player',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                      onPressed: () => _promptAddPlayer(context, team.id),
                    ),
                  ],
                ),
                if (players.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            playingXi.clear();
                            playingXi.addAll(players.map((p) => p.id));
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Text(
                            'Select All',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                        ),
                      ),
                      const Text(' • ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      InkWell(
                        onTap: () {
                          setState(() {
                            playingXi.clear();
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Text(
                            'Clear',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                if (players.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Column(
                        children: [
                          const Text('No players yet in this team.'),
                          const SizedBox(height: 8),
                          AppHeaderActionButton(
                            label: 'Add Player to ${team.shortName}',
                            icon: Icons.person_add_rounded,
                            onPressed: () => _promptAddPlayer(context, team.id),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: players.map((p) {
                      final isSelected = playingXi.contains(p.id);
                      return LongPressDraggable<Player>(
                        data: p,
                        delay: const Duration(milliseconds: 200),
                        hapticFeedbackOnStart: true,
                        feedback: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.transparent,
                          child: Transform.rotate(
                            angle: -0.04,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primary, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.drag_indicator, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    '#${p.jerseyNumber > 0 ? p.jerseyNumber : '—'} ${p.name}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      p.role,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: FilterChip(
                            label: Text('#${p.jerseyNumber > 0 ? '${p.jerseyNumber} ' : ''}${p.name}'),
                            selected: isSelected,
                            onSelected: null,
                          ),
                        ),
                        child: FilterChip(
                          avatar: const Icon(Icons.drag_indicator, size: 14, color: Colors.grey),
                          label: Text(
                            '#${p.jerseyNumber > 0 ? '${p.jerseyNumber} ' : ''}${p.name} (${p.role})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                            ),
                          ),
                          selected: isSelected,
                          showCheckmark: true,
                          checkmarkColor: AppColors.primary,
                          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          selectedColor: AppColors.primary.withValues(alpha: 0.12),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            width: isSelected ? 1.5 : 1,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                playingXi.add(p.id);
                              } else {
                                playingXi.remove(p.id);
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- STEP 4: TOSS ---
  Widget _buildStep4Toss(BuildContext context, CreateMatchDraft draft, TeamProvider teamProv) {
    final teamA = _getTeam(teamProv, draft.teamAId, fallbackIndex: 0);
    final teamB = _getTeam(teamProv, draft.teamBId, fallbackIndex: 1);

    if (teamA == null || teamB == null) {
      return const Text('Please select two teams in Step 2.');
    }

    if (draft.tossWinnerTeamId == null || (draft.tossWinnerTeamId != teamA.id && draft.tossWinnerTeamId != teamB.id)) {
      draft.tossWinnerTeamId = teamA.id;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Step 4 — Match Toss'),
        const SizedBox(height: 16),
        const Text('Who won the toss?', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _tossSelectionCard(
                label: teamA.name,
                isSelected: draft.tossWinnerTeamId == teamA.id,
                onTap: () => setState(() {
                  draft.tossWinnerTeamId = teamA.id;
                  draft.openingStrikerId = null;
                  draft.openingNonStrikerId = null;
                  draft.openingBowlerId = null;
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _tossSelectionCard(
                label: teamB.name,
                isSelected: draft.tossWinnerTeamId == teamB.id,
                onTap: () => setState(() {
                  draft.tossWinnerTeamId = teamB.id;
                  draft.openingStrikerId = null;
                  draft.openingNonStrikerId = null;
                  draft.openingBowlerId = null;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Elected to:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _tossSelectionCard(
                label: 'BAT FIRST 🏏',
                isSelected: draft.tossDecision.toLowerCase() == 'bat',
                onTap: () => setState(() {
                  draft.tossDecision = 'Bat';
                  draft.openingStrikerId = null;
                  draft.openingNonStrikerId = null;
                  draft.openingBowlerId = null;
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _tossSelectionCard(
                label: 'BOWL FIRST ⚾',
                isSelected: draft.tossDecision.toLowerCase() == 'bowl',
                onTap: () => setState(() {
                  draft.tossDecision = 'Bowl';
                  draft.openingStrikerId = null;
                  draft.openingNonStrikerId = null;
                  draft.openingBowlerId = null;
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tossSelectionCard({required String label, required bool isSelected, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      onTap: onTap,
      borderColor: isSelected ? AppColors.primary : null,
      backgroundColor: isSelected ? AppColors.primary.withValues(alpha: 0.15) : null,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      child: Center(
        child: Text(
          label,
          style: AppTextStyles.button.copyWith(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // --- STEP 5: SUMMARY & OPENERS LINEUP WITH SWAP ---
  Widget _buildStep5Summary(BuildContext context, CreateMatchDraft draft, TeamProvider teamProv) {
    final teamA = _getTeam(teamProv, draft.teamAId, fallbackIndex: 0);
    final teamB = _getTeam(teamProv, draft.teamBId, fallbackIndex: 1);

    if (teamA == null || teamB == null) {
      return const Text('Please select two teams in Step 2.');
    }

    final isTeamABatting = (draft.tossWinnerTeamId == teamA.id && draft.tossDecision == 'Bat') ||
        (draft.tossWinnerTeamId == teamB.id && draft.tossDecision == 'Bowl');
    final battingTeam = isTeamABatting ? teamA : teamB;
    final bowlingTeam = isTeamABatting ? teamB : teamA;

    final playerProv = context.watch<PlayerProvider>();
    final battingMap = <String, Player>{};
    for (final p in playerProv.players.where((p) => p.teamId == battingTeam.id)) {
      battingMap[p.id] = p;
    }
    final battingPlayers = battingMap.values.toList();

    final bowlingMap = <String, Player>{};
    for (final p in playerProv.players.where((p) => p.teamId == bowlingTeam.id)) {
      bowlingMap[p.id] = p;
    }
    final bowlingPlayers = bowlingMap.values.toList();

    // Ensure valid striker selection
    final isStrikerValid = draft.openingStrikerId != null && battingPlayers.any((p) => p.id == draft.openingStrikerId);
    if (!isStrikerValid) {
      draft.openingStrikerId = battingPlayers.isNotEmpty ? battingPlayers.first.id : null;
    }

    // Ensure valid non-striker selection
    final isNonStrikerValid = draft.openingNonStrikerId != null && battingPlayers.any((p) => p.id == draft.openingNonStrikerId);
    if (!isNonStrikerValid) {
      if (battingPlayers.length > 1) {
        draft.openingNonStrikerId = battingPlayers.firstWhere(
          (p) => p.id != draft.openingStrikerId,
          orElse: () => battingPlayers[1],
        ).id;
      } else {
        draft.openingNonStrikerId = battingPlayers.isNotEmpty ? battingPlayers.first.id : null;
      }
    } else if (draft.openingStrikerId == draft.openingNonStrikerId && battingPlayers.length > 1) {
      draft.openingNonStrikerId = battingPlayers.firstWhere(
        (p) => p.id != draft.openingStrikerId,
        orElse: () => battingPlayers.last,
      ).id;
    }

    // Ensure valid bowler selection
    final isBowlerValid = draft.openingBowlerId != null && bowlingPlayers.any((p) => p.id == draft.openingBowlerId);
    if (!isBowlerValid) {
      draft.openingBowlerId = bowlingPlayers.isNotEmpty ? bowlingPlayers.first.id : null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Step 5 — Configure Openers & Summary'),
        const SizedBox(height: 16),

        // Match Info Card
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${teamA.name} vs ${teamB.name}', style: AppTextStyles.h2),
              const SizedBox(height: 4),
              Text(
                '${draft.format} (${draft.totalOvers} Overs) • ${draft.venue.isNotEmpty ? draft.venue : 'Local Ground'}',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
              ),
              const Divider(height: 20),
              Text(
                'Toss: ${draft.tossWinnerTeamId == teamA.id ? teamA.name : teamB.name} won and chose to ${draft.tossDecision.toUpperCase()}',
                style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '1st Innings: ${battingTeam.name} batting • ${bowlingTeam.name} bowling',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Batting Openers Setup Card with SWAP option
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('1ST INNINGS BATTERS (${battingTeam.name})', style: AppTextStyles.label),
                  TextButton.icon(
                    icon: const Icon(Icons.person_add, size: 14),
                    label: const Text('Add Batter'),
                    onPressed: () => _promptAddPlayer(context, battingTeam.id),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (battingPlayers.isEmpty)
                AppButton(
                  label: 'Add Batters to ${battingTeam.shortName}',
                  icon: Icons.person_add,
                  onPressed: () => _promptAddPlayer(context, battingTeam.id),
                )
              else ...[
                // Striker
                AppDropdown<String>(
                  label: 'Opening Striker (On Strike *)',
                  value: draft.openingStrikerId,
                  items: battingPlayers.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      draft.openingStrikerId = v;
                      if (draft.openingNonStrikerId == v && battingPlayers.length > 1) {
                        draft.openingNonStrikerId = battingPlayers.firstWhere((p) => p.id != v).id;
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),

                // Swap Batters Button
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        final temp = draft.openingStrikerId;
                        draft.openingStrikerId = draft.openingNonStrikerId;
                        draft.openingNonStrikerId = temp;
                      });
                    },
                    icon: const Icon(Icons.swap_vert, size: 18),
                    label: const Text('Swap Striker & Non-Striker'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Non-Striker
                AppDropdown<String>(
                  label: 'Opening Non-Striker',
                  value: draft.openingNonStrikerId,
                  items: battingPlayers.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      draft.openingNonStrikerId = v;
                      if (draft.openingStrikerId == v && battingPlayers.length > 1) {
                        draft.openingStrikerId = battingPlayers.firstWhere((p) => p.id != v).id;
                      }
                    });
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Opening Bowler Setup Card
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('OPENING BOWLER (${bowlingTeam.name})', style: AppTextStyles.label),
                  TextButton.icon(
                    icon: const Icon(Icons.person_add, size: 14),
                    label: const Text('Add Bowler'),
                    onPressed: () => _promptAddPlayer(context, bowlingTeam.id, defaultRole: 'Bowler'),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (bowlingPlayers.isEmpty)
                AppButton(
                  label: 'Add Bowlers to ${bowlingTeam.shortName}',
                  icon: Icons.person_add,
                  onPressed: () => _promptAddPlayer(context, bowlingTeam.id, defaultRole: 'Bowler'),
                )
              else
                AppDropdown<String>(
                  label: 'Opening Bowler (Starts Over 1)',
                  value: draft.openingBowlerId,
                  items: bowlingPlayers
                      .map((p) => DropdownMenuItem(value: p.id, child: Text('${p.name} (${p.bowlingStyle})')))
                      .toList(),
                  onChanged: (v) => setState(() => draft.openingBowlerId = v),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _movePlayerToTeam(
    BuildContext context,
    Player player,
    Team destinationTeam,
    bool isDestinationTeamA,
    CreateMatchDraft draft,
  ) async {
    final playerProv = context.read<PlayerProvider>();
    final updated = await playerProv.changePlayerTeam(player.id, destinationTeam.id);

    setState(() {
      if (isDestinationTeamA) {
        draft.teamBPlayingXi.remove(player.id);
        if (draft.teamBCaptainId == player.id) draft.teamBCaptainId = null;
        if (draft.teamBWkId == player.id) draft.teamBWkId = null;
        if (!draft.teamAPlayingXi.contains(player.id)) {
          draft.teamAPlayingXi.add(player.id);
        }
      } else {
        draft.teamAPlayingXi.remove(player.id);
        if (draft.teamACaptainId == player.id) draft.teamACaptainId = null;
        if (draft.teamAWkId == player.id) draft.teamAWkId = null;
        if (!draft.teamBPlayingXi.contains(player.id)) {
          draft.teamBPlayingXi.add(player.id);
        }
      }
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${player.name} moved to ${destinationTeam.name} (Jersey #${updated?.jerseyNumber ?? player.jerseyNumber})',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _promptAddPlayerChoice(BuildContext context, Team teamA, Team teamB) {
    _promptAddPlayer(context, teamA.id, availableTeams: [teamA, teamB]);
  }

  void _promptAddPlayer(
    BuildContext context,
    String initialTeamId, {
    List<Team>? availableTeams,
    String defaultRole = 'Batter',
  }) {
    final nameCtrl = TextEditingController();
    final jerseyCtrl = TextEditingController();
    final playerProv = context.read<PlayerProvider>();
    String targetTeamId = initialTeamId;
    String role = defaultRole;

    // Auto-generate unique random jersey 1-100 for team
    jerseyCtrl.text = '${playerProv.generateRandomJerseyNumber(targetTeamId)}';

    String? errorText;

    AppDialog.show(
      context: context,
      title: 'Add Player to Match',
      content: StatefulBuilder(
        builder: (context, setDlgState) {
          final teamProv = context.read<TeamProvider>();
          final teamsList = availableTeams ??
              teamProv.teams.where((t) => t.id == targetTeamId).toList();

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (teamsList.length > 1) ...[
                  AppDropdown<String>(
                    label: 'Team',
                    value: targetTeamId,
                    items: teamsList.map((t) {
                      return DropdownMenuItem(
                        value: t.id,
                        child: Text('${t.name} (${t.shortName})'),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDlgState(() {
                          targetTeamId = v;
                          final newJersey = playerProv.generateRandomJerseyNumber(targetTeamId);
                          jerseyCtrl.text = '$newJersey';
                          errorText = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                AppTextField(
                  label: 'Player Name',
                  hint: 'e.g. John Doe',
                  controller: nameCtrl,
                  autofocus: true,
                  errorText: errorText,
                  onChanged: (v) {
                    if (errorText != null) {
                      setDlgState(() => errorText = null);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: AppTextField(
                        label: 'Jersey # (1-100)',
                        hint: '1-100',
                        keyboardType: TextInputType.number,
                        controller: jerseyCtrl,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.casino_outlined, size: 18, color: AppColors.primary),
                          tooltip: 'Randomize jersey',
                          onPressed: () {
                            setDlgState(() {
                              jerseyCtrl.text = '${playerProv.generateRandomJerseyNumber(targetTeamId)}';
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: AppDropdown<String>(
                        label: 'Role',
                        value: role,
                        items: ['Batter', 'Bowler', 'All Rounder', 'Wicketkeeper']
                            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setDlgState(() => role = v);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      confirmLabel: 'Add Player',
      onConfirm: () async {
        final name = nameCtrl.text.trim();
        if (name.isEmpty) return;

        // Validation
        if (playerProv.isPlayerNameTaken(targetTeamId, name)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Player "$name" already exists in this team'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }

        int jersey = int.tryParse(jerseyCtrl.text.trim()) ?? 0;
        if (jersey < 1 || jersey > 100 || playerProv.isJerseyNumberTaken(targetTeamId, jersey)) {
          jersey = playerProv.generateRandomJerseyNumber(targetTeamId);
        }

        Navigator.of(context).pop();
        final created = await playerProv.createPlayer(
          teamId: targetTeamId,
          name: name,
          jerseyNumber: jersey,
          role: role,
          battingStyle: 'Right-hand bat',
          bowlingStyle: role == 'Bowler' || role == 'All Rounder' ? 'Right-arm medium' : 'None',
        );

        if (!mounted) return;
        setState(() {
          final draft = context.read<MatchProvider>().draft;
          if (draft.teamAId == targetTeamId) {
            if (!draft.teamAPlayingXi.contains(created.id)) {
              draft.teamAPlayingXi.add(created.id);
            }
          } else if (draft.teamBId == targetTeamId) {
            if (!draft.teamBPlayingXi.contains(created.id)) {
              draft.teamBPlayingXi.add(created.id);
            }
          }

          // Auto-assign to opener slots if empty
          if (role == 'Bowler') {
            draft.openingBowlerId ??= created.id;
          } else {
            if (draft.openingStrikerId == null) {
              draft.openingStrikerId = created.id;
            } else if (draft.openingNonStrikerId == null || draft.openingNonStrikerId == draft.openingStrikerId) {
              draft.openingNonStrikerId = created.id;
            }
          }
        });

        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text('${created.name} (Jersey #${created.jerseyNumber}) added and included in match!'),
            backgroundColor: AppColors.success,
          ),
        );
      },
    );
  }

  Future<void> _handleNextStep(
    BuildContext context,
    CreateMatchDraft draft,
    TeamProvider teamProv,
  ) async {
    if (_currentStep == 0) {
      if (!_formKeyStep1.currentState!.validate()) return;
      draft.title = _titleController.text.trim();
      draft.venue = _venueController.text.trim();
      setState(() => _currentStep++);
    } else if (_currentStep == 1) {
      if (draft.teamAId == null || draft.teamBId == null || draft.teamAId == draft.teamBId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select two different teams to proceed')),
        );
        return;
      }
      setState(() => _currentStep++);
    } else if (_currentStep == 2) {
      setState(() => _currentStep++);
    } else if (_currentStep == 3) {
      setState(() => _currentStep++);
    } else if (_currentStep == 4) {
      if (draft.openingStrikerId != null &&
          draft.openingNonStrikerId != null &&
          draft.openingStrikerId == draft.openingNonStrikerId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Striker and Non-Striker must be different players')),
        );
        return;
      }
      final matchProv = context.read<MatchProvider>();
      final match = await matchProv.createMatchFromDraft();
      if (context.mounted) {
        final scoringProv = context.read<ScoringProvider>();
        scoringProv.clearMatchState();
        if (draft.maxOversPerBowler != null) {
          scoringProv.setMaxOversPerBowler(draft.maxOversPerBowler);
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => LiveScoringScreen(matchId: match.id),
          ),
        );
      }
    }
  }
}
