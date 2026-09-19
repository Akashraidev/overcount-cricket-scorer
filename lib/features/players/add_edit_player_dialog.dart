import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/photo_picker_helper.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_dropdown.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/player_avatar.dart';
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
  String? _photoUrl;

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
    final playerProv = context.read<PlayerProvider>();

    _teamId = p?.teamId ?? widget.initialTeamId ?? (teams.isNotEmpty ? teams.first.id : '');
    _nameController = TextEditingController(text: p?.name ?? '');

    // Auto-assign unique random jersey number 1-100 if new player or invalid
    if (p != null && p.jerseyNumber >= 1 && p.jerseyNumber <= 100) {
      _jerseyController = TextEditingController(text: '${p.jerseyNumber}');
    } else {
      final randomJersey = playerProv.generateRandomJerseyNumber(_teamId);
      _jerseyController = TextEditingController(text: '$randomJersey');
    }

    _role = p?.role ?? 'Batter';
    _battingStyle = p?.battingStyle ?? 'Right-hand bat';
    _bowlingStyle = p?.bowlingStyle ?? 'None';
    _isCaptain = p?.isCaptain ?? false;
    _isWicketKeeper = p?.isWicketKeeper ?? false;
    _photoUrl = p?.photoUrl;
  }

  void _regenerateJersey() {
    final playerProv = context.read<PlayerProvider>();
    final randomJersey = playerProv.generateRandomJerseyNumber(
      _teamId,
      excludePlayerId: widget.playerToEdit?.id,
    );
    setState(() {
      _jerseyController.text = '$randomJersey';
    });
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
    final playerProv = context.watch<PlayerProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final currentTeamObj = teams.cast<dynamic>().firstWhere(
          (t) => t.id == (widget.playerToEdit?.teamId ?? _teamId),
          orElse: () => null,
        );

    return AppDialog(
      title: isEditing ? 'Edit Player' : 'Add New Player',
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Player Photo Selector
            Center(
              child: PlayerAvatar(
                name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Player',
                photoUrl: _photoUrl,
                jerseyNumber: int.tryParse(_jerseyController.text.trim()) ?? 0,
                size: 72,
                showCameraBadge: true,
                onTap: () async {
                  final newPath = await PhotoPickerHelper.showPhotoSourceSheet(
                    context: context,
                    playerId: widget.playerToEdit?.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
                    currentPhotoUrl: _photoUrl,
                  );
                  if (newPath != null) {
                    setState(() {
                      _photoUrl = newPath.isEmpty ? null : newPath;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 14),

            if (isEditing && widget.playerToEdit != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                          children: [
                            const TextSpan(text: 'Player: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: widget.playerToEdit!.name),
                            const TextSpan(text: '   •   Current Team: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: currentTeamObj?.name ?? 'None'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Team Selector
            AppDropdown<String>(
              label: isEditing ? 'Assign Team' : 'Team',
              value: _teamId.isNotEmpty ? _teamId : (teams.isNotEmpty ? teams.first.id : null),
              items: teams.map((t) {
                return DropdownMenuItem(
                  value: t.id,
                  child: Text('${t.name} (${t.shortName})'),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null && v != _teamId) {
                  setState(() {
                    _teamId = v;
                    // If new player or if jersey conflicts in the newly chosen team, generate new unique jersey
                    final currentNum = int.tryParse(_jerseyController.text.trim()) ?? 0;
                    if (!isEditing || playerProv.isJerseyNumberTaken(v, currentNum, excludePlayerId: widget.playerToEdit?.id)) {
                      final newJersey = playerProv.generateRandomJerseyNumber(v, excludePlayerId: widget.playerToEdit?.id);
                      _jerseyController.text = '$newJersey';
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 14),

            // Player Name
            AppTextField(
              label: 'Full Name',
              hint: 'e.g. Rohit Sharma',
              controller: _nameController,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Player name is required';
                final clean = v.trim();
                if (playerProv.isPlayerNameTaken(_teamId, clean, excludePlayerId: widget.playerToEdit?.id)) {
                  return 'Player "$clean" already exists in this team';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Jersey Number & Role Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: AppTextField(
                    label: 'Jersey # (1-100)',
                    hint: '1-100',
                    keyboardType: TextInputType.number,
                    controller: _jerseyController,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.casino_outlined, size: 20, color: AppColors.primary),
                      tooltip: 'Randomize jersey number (1-100)',
                      onPressed: _regenerateJersey,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required (1-100)';
                      final num = int.tryParse(v.trim());
                      if (num == null || num < 1 || num > 100) return 'Must be 1 - 100';
                      if (playerProv.isJerseyNumberTaken(_teamId, num, excludePlayerId: widget.playerToEdit?.id)) {
                        return 'Already taken in team';
                      }
                      return null;
                    },
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
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) => setState(() => _isCaptain = v),
                  ),
                ),
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Wicketkeeper', style: TextStyle(fontSize: 13)),
                    value: _isWicketKeeper,
                    activeThumbColor: AppColors.info,
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
            int jersey = int.tryParse(_jerseyController.text.trim()) ?? 0;
            if (jersey < 1 || jersey > 100) {
              jersey = playerProv.generateRandomJerseyNumber(_teamId, excludePlayerId: widget.playerToEdit?.id);
            }

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
                photoUrl: _photoUrl,
              );
              await playerProv.updatePlayer(updated);
              if (!mounted) return;
              Navigator.of(this.context).pop(updated);
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
                photoUrl: _photoUrl,
              );
              if (!mounted) return;
              Navigator.of(this.context).pop(created);
            }
          },
        ),
      ],
    );
  }
}
