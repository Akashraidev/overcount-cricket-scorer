import 'package:flutter/material.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';

class ExtrasBottomSheet extends StatefulWidget {
  final Function(int runsBat, int extraRuns, String extraType, bool isLegal) onConfirm;

  const ExtrasBottomSheet({super.key, required this.onConfirm});

  static Future<void> show(
    BuildContext context, {
    required Function(int runsBat, int extraRuns, String extraType, bool isLegal) onConfirm,
  }) {
    return AppBottomSheet.show(
      context: context,
      title: 'CUSTOM EXTRAS',
      subtitle: 'Configure wide/no-ball with boundary or byes',
      child: ExtrasBottomSheet(onConfirm: onConfirm),
    );
  }

  @override
  State<ExtrasBottomSheet> createState() => _ExtrasBottomSheetState();
}

class _ExtrasBottomSheetState extends State<ExtrasBottomSheet> {
  String _selectedType = 'Wide';
  int _extraRuns = 1;
  int _batRuns = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Extra Type
        const Text('Extra Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        Row(
          children: ['Wide', 'No Ball', 'Bye', 'Leg Bye'].map((t) {
            final isSelected = _selectedType == t;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(t),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedType = t;
                      if (t == 'Wide') {
                        _extraRuns = 1;
                        _batRuns = 0;
                      } else if (t == 'No Ball') {
                        _extraRuns = 1;
                        _batRuns = 0;
                      } else {
                        _extraRuns = 1;
                        _batRuns = 0;
                      }
                    });
                  },
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        if (_selectedType == 'Wide') ...[
          const Text('Additional Runs (Byes on Wide)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [1, 2, 3, 4, 5].map((r) {
              final isSelected = _extraRuns == r;
              return ChoiceChip(
                label: Text('$r Wd Total'),
                selected: isSelected,
                onSelected: (_) => setState(() => _extraRuns = r),
              );
            }).toList(),
          ),
        ] else if (_selectedType == 'No Ball') ...[
          const Text('Runs scored by Batsman off No Ball', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [0, 1, 2, 3, 4, 6].map((r) {
              final isSelected = _batRuns == r;
              return ChoiceChip(
                label: Text(r == 0 ? 'No Bat Run' : '+$r Runs (Bat)'),
                selected: isSelected,
                onSelected: (_) => setState(() => _batRuns = r),
              );
            }).toList(),
          ),
        ] else ...[
          const Text('Byes / Leg Byes Taken', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [1, 2, 3, 4].map((r) {
              final isSelected = _extraRuns == r;
              return ChoiceChip(
                label: Text('$r Runs'),
                selected: isSelected,
                onSelected: (_) => setState(() => _extraRuns = r),
              );
            }).toList(),
          ),
        ],

        const SizedBox(height: 28),

        AppButton(
          label: 'Record Extra',
          icon: Icons.check,
          isFullWidth: true,
          onPressed: () {
            Navigator.of(context).pop();
            final isLegal = _selectedType == 'Bye' || _selectedType == 'Leg Bye';
            final extraTypeKey = _selectedType.toLowerCase().replaceAll(' ', '');

            widget.onConfirm(
              _batRuns,
              _extraRuns,
              extraTypeKey,
              isLegal,
            );
          },
        ),
      ],
    );
  }
}
