import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/models/player.dart';

class WicketBottomSheet extends StatefulWidget {
  final Player striker;
  final Player nonStriker;
  final Player currentBowler;
  final List<Player> fieldingSquad;
  final List<Player> availableBatters;
  final Future<Player> Function(String name)? onAddNewBatter;
  final Function({
    required String wicketType,
    required String dismissedPlayerId,
    String? fielderId,
    String? fielderName,
    required String newBatsmanId,
    int runsCompleted,
  }) onConfirm;

  const WicketBottomSheet({
    super.key,
    required this.striker,
    required this.nonStriker,
    required this.currentBowler,
    required this.fieldingSquad,
    required this.availableBatters,
    this.onAddNewBatter,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required Player striker,
    required Player nonStriker,
    required Player currentBowler,
    required List<Player> fieldingSquad,
    required List<Player> availableBatters,
    Future<Player> Function(String name)? onAddNewBatter,
    required Function({
      required String wicketType,
      required String dismissedPlayerId,
      String? fielderId,
      String? fielderName,
      required String newBatsmanId,
      int runsCompleted,
    }) onConfirm,
  }) {
    return AppBottomSheet.show(
      context: context,
      title: 'RECORD WICKET 🚨',
      subtitle: 'Select dismissal details and incoming batsman',
      child: WicketBottomSheet(
        striker: striker,
        nonStriker: nonStriker,
        currentBowler: currentBowler,
        fieldingSquad: fieldingSquad,
        availableBatters: availableBatters,
        onAddNewBatter: onAddNewBatter,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<WicketBottomSheet> createState() => _WicketBottomSheetState();
}

class _WicketBottomSheetState extends State<WicketBottomSheet> {
  late String _dismissedPlayerId;
  String _wicketType = 'Caught';
  String? _fielderId;
  String? _newBatsmanId;
  int _runsCompleted = 0;
  late List<Player> _availableBatters;

  final List<String> _wicketTypes = const [
    'Caught',
    'Bowled',
    'LBW',
    'Run Out',
    'Stumped',
    'Hit Wicket',
    'Retired Hurt',
    'Retired Out',
  ];

  @override
  void initState() {
    super.initState();
    _dismissedPlayerId = widget.striker.id;
    _availableBatters = List<Player>.from(widget.availableBatters);
    if (_availableBatters.isNotEmpty) {
      _newBatsmanId = _availableBatters.first.id;
    }
  }

  void _showAddBatterDialog() {
    final nameCtrl = TextEditingController();

    AppDialog.show(
      context: context,
      title: 'Add New Batter to Team',
      content: AppTextField(
        label: 'Batter Name',
        hint: 'e.g. Virat Kohli',
        controller: nameCtrl,
        autofocus: true,
      ),
      confirmLabel: 'Add & Select',
      onConfirm: () async {
        final name = nameCtrl.text.trim();
        if (name.isNotEmpty && widget.onAddNewBatter != null) {
          Navigator.of(context).pop();
          final created = await widget.onAddNewBatter!(name);
          if (mounted) {
            setState(() {
              _availableBatters.add(created);
              _newBatsmanId = created.id;
            });
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRunOut = _wicketType == 'Run Out';
    final isCatchOrStumping = _wicketType == 'Caught' || _wicketType == 'Stumped';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Dismissed Batter Selector
          const Text('Dismissed Batter', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _selectionChip(
                  label: '${widget.striker.name} (Striker)',
                  isSelected: _dismissedPlayerId == widget.striker.id,
                  onTap: () => setState(() => _dismissedPlayerId = widget.striker.id),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _selectionChip(
                  label: '${widget.nonStriker.name} (Non-Striker)',
                  isSelected: _dismissedPlayerId == widget.nonStriker.id,
                  onTap: () => setState(() => _dismissedPlayerId = widget.nonStriker.id),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Wicket Type Grid
          const Text('Wicket Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _wicketTypes.map((t) {
              final isSelected = _wicketType == t;
              return ChoiceChip(
                label: Text(t),
                selected: isSelected,
                onSelected: (_) => setState(() => _wicketType = t),
                selectedColor: AppColors.wicket.withValues(alpha: 0.2),
                labelStyle: AppTextStyles.label.copyWith(
                  color: isSelected ? AppColors.wicket : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // 3. Fielder Selector (if Caught, Stumped, Run Out)
          if (isCatchOrStumping || isRunOut) ...[
            AppDropdown<String?>(
              label: isCatchOrStumping ? 'Fielder / Catcher' : 'Fielder involved in Run Out',
              value: _fielderId,
              hint: 'Select Fielder',
              items: [
                const DropdownMenuItem(value: null, child: Text('Unassisted / Substitute')),
                ...widget.fieldingSquad.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name))),
              ],
              onChanged: (v) => setState(() => _fielderId = v),
            ),
            const SizedBox(height: 16),
          ],

          // 4. Runs completed before run out
          if (isRunOut) ...[
            AppDropdown<int>(
              label: 'Runs completed before dismissal',
              value: _runsCompleted,
              items: List.generate(4, (i) => DropdownMenuItem(value: i, child: Text('$i run${i == 1 ? '' : 's'}'))),
              onChanged: (v) {
                if (v != null) setState(() => _runsCompleted = v);
              },
            ),
            const SizedBox(height: 16),
          ],

          // 5. Incoming New Batter Header with Add Player action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Next Batsman In', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              if (widget.onAddNewBatter != null)
                TextButton.icon(
                  icon: const Icon(Icons.person_add, size: 14),
                  label: const Text('Add Batter'),
                  onPressed: _showAddBatterDialog,
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (_availableBatters.isNotEmpty) ...[
            AppDropdown<String>(
              label: 'Select Next Batsman',
              value: _newBatsmanId ?? _availableBatters.first.id,
              items: _availableBatters.map((b) {
                return DropdownMenuItem(value: b.id, child: Text('${b.name} (${b.role})'));
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _newBatsmanId = v);
              },
            ),
            const SizedBox(height: 24),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.wicket.withValues(alpha: 0.1),
                borderRadius: AppRadius.roundedMd,
              ),
              child: Column(
                children: [
                  Text(
                    'No more batters available in squad. Mark All Out or Add a Batter.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.wicket, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (widget.onAddNewBatter != null)
                    AppButton(
                      label: 'Add New Batter to Team',
                      icon: Icons.person_add,
                      height: 36,
                      onPressed: _showAddBatterDialog,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Confirm Button
          AppButton(
            label: 'Confirm Wicket',
            icon: Icons.check,
            isFullWidth: true,
            variant: AppButtonVariant.danger,
            onPressed: () {
              if (_newBatsmanId == null && _availableBatters.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select next batsman')),
                );
                return;
              }

              Player? fielder;
              if (_fielderId != null) {
                try {
                  fielder = widget.fieldingSquad.firstWhere((f) => f.id == _fielderId);
                } catch (_) {}
              }

              Navigator.of(context).pop();

              widget.onConfirm(
                wicketType: _wicketType,
                dismissedPlayerId: _dismissedPlayerId,
                fielderId: _fielderId,
                fielderName: fielder?.name,
                newBatsmanId: _newBatsmanId ?? '',
                runsCompleted: _runsCompleted,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _selectionChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.roundedSm,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.wicket.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: AppRadius.roundedSm,
          border: Border.all(
            color: isSelected ? AppColors.wicket : const Color(0xFF64748B),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: isSelected ? AppColors.wicket : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
