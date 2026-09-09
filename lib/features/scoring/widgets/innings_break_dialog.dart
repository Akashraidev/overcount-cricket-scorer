import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/models/innings.dart';
import '../../../data/models/player.dart';
import '../../../data/models/team.dart';

class InningsBreakDialog extends StatefulWidget {
  final Innings completedInnings;
  final Team team1;
  final Team team2;
  final List<Player> team2Squad; // Batting in 2nd innings
  final List<Player> team1Squad; // Bowling in 2nd innings
  final Future<Player> Function(String teamId, String name, String role)? onAddNewPlayer;
  final Function(String strikerId, String nonStrikerId, String bowlerId) onStartSecondInnings;
  final VoidCallback? onReview;

  const InningsBreakDialog({
    super.key,
    required this.completedInnings,
    required this.team1,
    required this.team2,
    required this.team2Squad,
    required this.team1Squad,
    this.onAddNewPlayer,
    required this.onStartSecondInnings,
    this.onReview,
  });

  static Future<void> show(
    BuildContext context, {
    required Innings completedInnings,
    required Team team1,
    required Team team2,
    required List<Player> team2Squad,
    required List<Player> team1Squad,
    Future<Player> Function(String teamId, String name, String role)? onAddNewPlayer,
    required Function(String strikerId, String nonStrikerId, String bowlerId) onStartSecondInnings,
    VoidCallback? onReview,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => InningsBreakDialog(
        completedInnings: completedInnings,
        team1: team1,
        team2: team2,
        team2Squad: team2Squad,
        team1Squad: team1Squad,
        onAddNewPlayer: onAddNewPlayer,
        onStartSecondInnings: onStartSecondInnings,
        onReview: onReview,
      ),
    );
  }

  @override
  State<InningsBreakDialog> createState() => _InningsBreakDialogState();
}

class _InningsBreakDialogState extends State<InningsBreakDialog> {
  late String _strikerId;
  late String _nonStrikerId;
  late String _bowlerId;
  late List<Player> _team2Squad;
  late List<Player> _team1Squad;

  @override
  void initState() {
    super.initState();
    _team2Squad = List<Player>.from(widget.team2Squad);
    _team1Squad = List<Player>.from(widget.team1Squad);

    _strikerId = _team2Squad.isNotEmpty ? _team2Squad[0].id : '';
    _nonStrikerId = _team2Squad.length > 1 ? _team2Squad[1].id : (_team2Squad.isNotEmpty ? _team2Squad[0].id : '');
    _bowlerId = _team1Squad.isNotEmpty ? _team1Squad[0].id : '';
  }

  void _showAddPlayerDialog(String teamId, String teamName, bool isBatting) {
    final nameCtrl = TextEditingController();
    String role = isBatting ? 'Batter' : 'Bowler';

    AppDialog.show(
      context: context,
      title: 'Add Player to $teamName',
      content: StatefulBuilder(
        builder: (context, setDlgState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Player Name',
                hint: 'e.g. David Warner',
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
            ],
          );
        },
      ),
      confirmLabel: 'Add & Select',
      onConfirm: () async {
        final name = nameCtrl.text.trim();
        if (name.isNotEmpty && widget.onAddNewPlayer != null) {
          Navigator.of(context).pop();
          final created = await widget.onAddNewPlayer!(teamId, name, role);
          if (mounted) {
            setState(() {
              if (isBatting) {
                _team2Squad.add(created);
                if (_strikerId.isEmpty) {
                  _strikerId = created.id;
                } else if (_nonStrikerId.isEmpty || _nonStrikerId == _strikerId) {
                  _nonStrikerId = created.id;
                }
              } else {
                _team1Squad.add(created);
                if (_bowlerId.isEmpty) {
                  _bowlerId = created.id;
                }
              }
            });
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.completedInnings.totalRuns + 1;

    return AppDialog(
      title: 'Innings Break! 🎯',
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              borderColor: AppColors.primary,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '${widget.team1.name}: ${widget.completedInnings.totalRuns}/${widget.completedInnings.totalWickets} (${widget.completedInnings.oversDisplay} ov)',
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'TARGET: $target RUNS',
                    style: AppTextStyles.scoreMedium.copyWith(color: AppColors.accent),
                  ),
                  Text(
                    '${widget.team2.name} needs $target runs to win.',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Configure 2nd Innings Openers', style: TextStyle(fontWeight: FontWeight.bold)),
                if (widget.onAddNewPlayer != null)
                  TextButton.icon(
                    icon: const Icon(Icons.person_add, size: 14),
                    label: const Text('Add Batter'),
                    onPressed: () => _showAddPlayerDialog(widget.team2.id, widget.team2.shortName, true),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Striker
            if (_team2Squad.isNotEmpty) ...[
              AppDropdown<String>(
                label: 'Opening Striker (Batting *)',
                prefixIcon: Icons.sports_cricket_rounded,
                value: _strikerId.isNotEmpty ? _strikerId : _team2Squad.first.id,
                items: _team2Squad.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _strikerId = v);
                },
              ),
              const SizedBox(height: 8),

              // Swap Button
              Center(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      final temp = _strikerId;
                      _strikerId = _nonStrikerId;
                      _nonStrikerId = temp;
                    });
                  },
                  icon: const Icon(Icons.swap_vert, size: 16),
                  label: const Text('Swap Striker & Non-Striker'),
                ),
              ),
              const SizedBox(height: 8),

              // Non-Striker
              AppDropdown<String>(
                label: 'Opening Non-Striker (Batting)',
                prefixIcon: Icons.sports_cricket_outlined,
                value: _nonStrikerId.isNotEmpty ? _nonStrikerId : _team2Squad.last.id,
                items: _team2Squad.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _nonStrikerId = v);
                },
              ),
            ] else
              AppButton(
                label: 'Add Batters to ${widget.team2.shortName}',
                icon: Icons.person_add,
                onPressed: () => _showAddPlayerDialog(widget.team2.id, widget.team2.shortName, true),
              ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Opening Bowler', style: TextStyle(fontWeight: FontWeight.bold)),
                if (widget.onAddNewPlayer != null)
                  TextButton.icon(
                    icon: const Icon(Icons.person_add, size: 14),
                    label: const Text('Add Bowler'),
                    onPressed: () => _showAddPlayerDialog(widget.team1.id, widget.team1.shortName, false),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Opening Bowler
            if (_team1Squad.isNotEmpty)
              AppDropdown<String>(
                label: 'Opening Bowler (${widget.team1.shortName})',
                prefixIcon: Icons.sports_baseball_outlined,
                value: _bowlerId.isNotEmpty ? _bowlerId : _team1Squad.first.id,
                items: _team1Squad.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.name} (${p.bowlingStyle})'))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _bowlerId = v);
                },
              )
            else
              AppButton(
                label: 'Add Bowlers to ${widget.team1.shortName}',
                icon: Icons.person_add,
                onPressed: () => _showAddPlayerDialog(widget.team1.id, widget.team1.shortName, false),
              ),
          ],
        ),
      ),
      actions: [
        AppButton(
          label: 'Start 2nd Innings 🏏',
          icon: Icons.play_arrow_rounded,
          isFullWidth: true,
          onPressed: () {
            if (_strikerId == _nonStrikerId && _team2Squad.length > 1) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Striker and Non-Striker must be different players')),
              );
              return;
            }
            if (_strikerId.isEmpty || _nonStrikerId.isEmpty || _bowlerId.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please configure striker, non-striker, and bowler')),
              );
              return;
            }
            Navigator.of(context).pop();
            widget.onStartSecondInnings(_strikerId, _nonStrikerId, _bowlerId);
          },
        ),
        if (widget.onReview != null) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
              label: const Text('Review Scorecard / Not Yet'),
              onPressed: () {
                Navigator.of(context).pop();
                widget.onReview!();
              },
            ),
          ),
        ],
      ],
    );
  }
}
