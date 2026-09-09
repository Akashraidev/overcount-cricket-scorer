import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_dropdown.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/player.dart';
import '../teams/team_provider.dart';
import 'player_provider.dart';

class AddEditPlayerDialog extends StatefulWidget {
  final Player? playerToEdit;
  final String? initialTeamId;

  const AddEditPlayerDialog({super.key, this.playerToEdit, this.initialTeamId});

  static Future<Player?> show(BuildContext context, {Player? playerToEdit, String? initialTeamId}) {
    return showDialog<Player>(
      context: context,
      builder: (context) => AddEditPlayerDialog(
        playerToEdit: playerToEdit,
        initialTeamId: initialTeamId,
      ),
    );
  }

  @override
  State<AddEditPlayerDialog> createState() => _AddEditPlayerDialogState();
}

class _AddEditPlayerDialogState extends State<AddEditPlayerDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _jerseyController;
  late String _role;
  late String _battingStyle;
  late String _bowlingStyle;
  late String _teamId;
  late bool _isCaptain;
  late bool _isWicketKeeper;

  final List<String> _roles = const ['Batter', 'Bowler', 'All Rounder', 'Wicketkeeper'];
  final List<String> _battingStyles = const ['Right-hand bat', 'Left-hand bat'];
  final List<String> _bowlingStyles = const [
    'None',
    'Right-arm fast',
    'Right-arm medium',
    'Right-arm off break',
    'Right-arm leg break',
    'Left-arm fast',
    'Slow left-arm orthodox',
    'Left-arm wrist spin',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.playerToEdit;
    final teams = context.read<TeamProvider>().teams;

    _nameController = TextEditingController(text: p?.name ?? '');
    _jerseyController = TextEditingController(text: p != null && p.jerseyNumber > 0 ? '${p.jerseyNumber}' : '');
    _role = p?.role ?? 'Batter';
    _battingStyle = p?.battingStyle ?? 'Right-hand bat';
    _bowlingStyle = p?.bowlingStyle ?? 'None';
    _teamId = p?.teamId ?? widget.initialTeamId ?? (teams.isNotEmpty ? teams.first.id : '');
    _isCaptain = p?.isCaptain ?? false;
    _isWicketKeeper = p?.isWicketKeeper ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _jerseyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.playerToEdit != null;
    final teams = context.watch<TeamProvider>().teams;

    return AppDialog(
      title: isEditing ? 'Edit Player' : 'Add New Player',
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team Selector
            AppDropdown<String>(
              label: 'Team',
              value: _teamId.isNotEmpty ? _teamId : (teams.isNotEmpty ? teams.first.id : null),
              items: teams.map((t) {
                return DropdownMenuItem(
                  value: t.id,
                  child: Text('${t.name} (${t.shortName})'),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _teamId = v);
              },
            ),
            const SizedBox(height: 14),

            // Player Name
            AppTextField(
              label: 'Full Name',
              hint: 'e.g. Rohit Sharma',
              controller: _nameController,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Player name is required' : null,
            ),
            const SizedBox(height: 14),

            // Jersey Number & Role Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: AppTextField(
                    label: 'Jersey #',
                    hint: 'e.g. 45',
                    keyboardType: TextInputType.number,
                    controller: _jerseyController,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: AppDropdown<String>(
                    label: 'Role',
                    value: _role,
                    items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _role = v;
                          if (v == 'Wicketkeeper') _isWicketKeeper = true;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Batting Style
            AppDropdown<String>(
              label: 'Batting Style',
              value: _battingStyle,
              items: _battingStyles.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _battingStyle = v);
              },
            ),
            const SizedBox(height: 14),

            // Bowling Style
            AppDropdown<String>(
              label: 'Bowling Style',
              value: _bowlingStyle,
              items: _bowlingStyles.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _bowlingStyle = v);
              },
            ),
            const SizedBox(height: 14),

            // Captain & Wicketkeeper Switches
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Captain', style: TextStyle(fontSize: 13)),
                    value: _isCaptain,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _isCaptain = v),
                  ),
                ),
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Wicketkeeper', style: TextStyle(fontSize: 13)),
                    value: _isWicketKeeper,
                    activeColor: AppColors.info,
                    onChanged: (v) => setState(() => _isWicketKeeper = v),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        AppButton(
          label: 'Cancel',
          variant: AppButtonVariant.outline,
          height: 40,
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 8),
        AppButton(
          label: isEditing ? 'Save' : 'Add Player',
          height: 40,
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            if (_teamId.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select or create a team first')),
              );
              return;
            }

            final playerProv = context.read<PlayerProvider>();
            final jersey = int.tryParse(_jerseyController.text.trim()) ?? 0;

            if (isEditing) {
              final updated = widget.playerToEdit!.copyWith(
                name: _nameController.text.trim(),
                teamId: _teamId,
                jerseyNumber: jersey,
                role: _role,
                battingStyle: _battingStyle,
                bowlingStyle: _bowlingStyle,
                isCaptain: _isCaptain,
                isWicketKeeper: _isWicketKeeper,
              );
              await playerProv.updatePlayer(updated);
              if (mounted) Navigator.of(context).pop(updated);
            } else {
              final created = await playerProv.createPlayer(
                teamId: _teamId,
                name: _nameController.text.trim(),
                jerseyNumber: jersey,
                role: _role,
                battingStyle: _battingStyle,
                bowlingStyle: _bowlingStyle,
                isCaptain: _isCaptain,
                isWicketKeeper: _isWicketKeeper,
              );
              if (mounted) Navigator.of(context).pop(created);
            }
          },
        ),
      ],
    );
  }
}
