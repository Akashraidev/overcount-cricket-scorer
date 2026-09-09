import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/models/bowling_stat.dart';
import '../../../data/models/player.dart';

class EndOverDialog extends StatefulWidget {
  final int completedOverNumber;
  final Player previousBowler;
  final List<Player> availableBowlers;
  final List<BowlingStat> bowlingStats;
  final int maxOversPerBowler;
  final String teamId;
  final ValueChanged<String> onBowlerSelected;
  final Future<Player> Function(String name, String bowlingStyle) onAddNewBowler;
  final VoidCallback onDeclareInnings;
  final ValueChanged<int?>? onChangeBowlerLimit;

  const EndOverDialog({
    super.key,
    required this.completedOverNumber,
    required this.previousBowler,
    required this.availableBowlers,
    required this.bowlingStats,
    required this.maxOversPerBowler,
    required this.teamId,
    required this.onBowlerSelected,
    required this.onAddNewBowler,
    required this.onDeclareInnings,
    this.onChangeBowlerLimit,
  });

  static Future<void> show(
    BuildContext context, {
    required int completedOverNumber,
    required Player previousBowler,
    required List<Player> availableBowlers,
    required List<BowlingStat> bowlingStats,
    required int maxOversPerBowler,
    required String teamId,
    required ValueChanged<String> onBowlerSelected,
    required Future<Player> Function(String name, String bowlingStyle) onAddNewBowler,
    required VoidCallback onDeclareInnings,
    ValueChanged<int?>? onChangeBowlerLimit,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EndOverDialog(
        completedOverNumber: completedOverNumber,
        previousBowler: previousBowler,
        availableBowlers: availableBowlers,
        bowlingStats: bowlingStats,
        maxOversPerBowler: maxOversPerBowler,
        teamId: teamId,
        onBowlerSelected: onBowlerSelected,
        onAddNewBowler: onAddNewBowler,
        onDeclareInnings: onDeclareInnings,
        onChangeBowlerLimit: onChangeBowlerLimit,
      ),
    );
  }

  @override
  State<EndOverDialog> createState() => _EndOverDialogState();
}

class _EndOverDialogState extends State<EndOverDialog> {
  late String _selectedBowlerId;
  late List<Player> _bowlers;
  late int _currentLimit;

  bool get isUnlimited => _currentLimit <= 0;

  @override
  void initState() {
    super.initState();
    _bowlers = List<Player>.from(widget.availableBowlers);
    _currentLimit = widget.maxOversPerBowler;

    // Pick first eligible bowler who didn't bowl last over and hasn't finished quota
    final eligible = _bowlers.where((b) => _isEligible(b.id)).toList();
    if (eligible.isNotEmpty) {
      _selectedBowlerId = eligible.first.id;
    } else if (_bowlers.isNotEmpty) {
      _selectedBowlerId = _bowlers.first.id;
    } else {
      _selectedBowlerId = '';
    }
  }

  BowlingStat? _getStat(String playerId) {
    try {
      return widget.bowlingStats.firstWhere((s) => s.playerId == playerId);
    } catch (_) {
      return null;
    }
  }

  int _getCompletedOvers(String playerId) {
    final stat = _getStat(playerId);
    return (stat?.totalLegalBalls ?? 0) ~/ 6;
  }

  bool _isConsecutive(String playerId) {
    return _bowlers.length > 1 && widget.previousBowler.id == playerId;
  }

  bool _isQuotaExceeded(String playerId) {
    if (isUnlimited) return false;
    final completed = _getCompletedOvers(playerId);
    return completed >= _currentLimit;
  }

  bool _isEligible(String playerId) {
    return !_isConsecutive(playerId) && !_isQuotaExceeded(playerId);
  }

  void _showChangeLimitDialog() {
    final ctrl = TextEditingController(text: isUnlimited ? '' : '$_currentLimit');
    bool setUnlimited = isUnlimited;

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
                subtitle: const Text('Any bowler can bowl any number of overs'),
                value: setUnlimited,
                onChanged: (val) {
                  setDlgState(() => setUnlimited = val ?? false);
                },
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
        setState(() {
          _currentLimit = newLimit;
        });
        widget.onChangeBowlerLimit?.call(setUnlimited ? 0 : newLimit);
      },
    );
  }

  void _showAddBowlerDialog() {
    final nameCtrl = TextEditingController();
    String style = 'Right-arm medium';

    AppDialog.show(
      context: context,
      title: 'Add New Bowler to Team',
      content: StatefulBuilder(
        builder: (context, setDlgState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Bowler Name',
                hint: 'e.g. Jasprit Bumrah',
                controller: nameCtrl,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              AppDropdown<String>(
                label: 'Bowling Style',
                value: style,
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
                  if (v != null) setDlgState(() => style = v);
                },
              ),
            ],
          );
        },
      ),
      confirmLabel: 'Add & Select',
      onConfirm: () async {
        final name = nameCtrl.text.trim();
        if (name.isNotEmpty) {
          Navigator.of(context).pop();
          final newBowler = await widget.onAddNewBowler(name, style);
          if (mounted) {
            setState(() {
              _bowlers.add(newBowler);
              _selectedBowlerId = newBowler.id;
            });
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppDialog(
      title: 'Over ${widget.completedOverNumber} Finished! 🏏',
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Previous Bowler Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: AppRadius.roundedSm,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sports_baseball, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isUnlimited
                          ? '${widget.previousBowler.name} bowled over ${widget.completedOverNumber}. (No bowler limit)'
                          : '${widget.previousBowler.name} bowled over ${widget.completedOverNumber}. Max $_currentLimit overs/bowler.',
                      style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.tune_rounded, size: 14, color: AppColors.primary),
                    label: Text(
                      isUnlimited ? 'No Limit' : '$_currentLimit ov',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    onPressed: _showChangeLimitDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Header with Add Bowler
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text('Choose Next Bowler:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.person_add, size: 14),
                  label: const Text('New Bowler'),
                  onPressed: _showAddBowlerDialog,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Bowlers List with figures and quota indicators
            ..._bowlers.map((b) {
              final isSelected = _selectedBowlerId == b.id;
              final stat = _getStat(b.id);
              final overs = stat?.oversDisplay ?? '0.0';
              final wickets = stat?.wickets ?? 0;
              final runs = stat?.runsConceded ?? 0;
              final isCon = _isConsecutive(b.id);
              final isQuota = _isQuotaExceeded(b.id);
              final isEligible = !isCon && !isQuota;

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: isEligible
                      ? () => setState(() => _selectedBowlerId = b.id)
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isCon
                                    ? '${b.name} bowled the previous over (consecutive overs not allowed).'
                                    : '${b.name} has completed their maximum quota of ${widget.maxOversPerBowler} overs.',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                  borderRadius: AppRadius.roundedSm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated),
                      borderRadius: AppRadius.roundedSm,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : (isEligible
                                ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                                : Colors.red.withValues(alpha: 0.3)),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : (isEligible ? Icons.radio_button_unchecked : Icons.block),
                          size: 18,
                          color: isSelected
                              ? AppColors.primary
                              : (isEligible ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted) : Colors.red),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.name,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isEligible ? null : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                                ),
                              ),
                              Text(
                                '${b.bowlingStyle} • $overs ov ($runs r, $wickets w)',
                                style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        if (isCon)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Last Over', style: TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.bold)),
                          )
                        else if (isQuota)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Max Overs', style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold)),
                          )
                        else
                          Text(
                            isUnlimited
                                ? '${_getCompletedOvers(b.id)} ov'
                                : '${_getCompletedOvers(b.id)}/$_currentLimit ov',
                            style: AppTextStyles.label.copyWith(fontSize: 10),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 12),
            // End Innings option
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.flag_outlined, size: 16, color: AppColors.warning),
                label: const Text('End / Declare Innings Early', style: TextStyle(color: AppColors.warning, fontSize: 12)),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onDeclareInnings();
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        AppButton(
          label: 'Start Over ${widget.completedOverNumber + 1} 🏏',
          icon: Icons.play_arrow_rounded,
          isFullWidth: true,
          onPressed: () {
            if (_selectedBowlerId.isEmpty) return;
            if (!_isEligible(_selectedBowlerId)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Selected bowler is not eligible for this over')),
              );
              return;
            }
            Navigator.of(context).pop();
            widget.onBowlerSelected(_selectedBowlerId);
          },
        ),
      ],
    );
  }
}
