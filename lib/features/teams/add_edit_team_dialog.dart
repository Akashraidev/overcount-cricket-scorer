import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/team.dart';
import 'team_provider.dart';

class AddEditTeamDialog extends StatefulWidget {
  final Team? teamToEdit;

  const AddEditTeamDialog({super.key, this.teamToEdit});

  static Future<Team?> show(BuildContext context, {Team? teamToEdit}) {
    return showDialog<Team>(
      context: context,
      builder: (context) => AddEditTeamDialog(teamToEdit: teamToEdit),
    );
  }

  @override
  State<AddEditTeamDialog> createState() => _AddEditTeamDialogState();
}

class _AddEditTeamDialogState extends State<AddEditTeamDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _shortNameController;
  late int _selectedColor;

  final List<int> _colorPalette = const [
    0xFF1D4ED8, // Blue
    0xFFEAB308, // Gold
    0xFFDC2626, // Red
    0xFF059669, // Green
    0xFF7C3AED, // Purple
    0xFFEA580C, // Orange
    0xFF0891B2, // Cyan
    0xFFDB2777, // Pink
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.teamToEdit?.name ?? '');
    _shortNameController = TextEditingController(text: widget.teamToEdit?.shortName ?? '');
    _selectedColor = widget.teamToEdit?.colorValue ?? _colorPalette.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.teamToEdit != null;

    return AppDialog(
      title: isEditing ? 'Edit Team' : 'Create New Team',
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: 'Team Name',
              hint: 'e.g. Royal Challengers',
              controller: _nameController,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Team name is required' : null,
              onChanged: (v) {
                if (!isEditing && _shortNameController.text.isEmpty && v.trim().isNotEmpty) {
                  final words = v.trim().split(' ');
                  if (words.length > 1) {
                    _shortNameController.text = words.map((w) => w.isNotEmpty ? w[0] : '').take(3).join().toUpperCase();
                  } else if (v.length >= 3) {
                    _shortNameController.text = v.substring(0, 3).toUpperCase();
                  }
                }
              },
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Short Name / Code',
              hint: 'e.g. RCB (Max 4 chars)',
              controller: _shortNameController,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Short code is required' : null,
            ),
            const SizedBox(height: 16),
            const Text('Team Color', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colorPalette.map((c) {
                final isSelected = _selectedColor == c;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = c),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Color(c).withValues(alpha: 0.6),
                                blurRadius: 8,
                              )
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
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
          label: isEditing ? 'Save Changes' : 'Create Team',
          height: 40,
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            final teamProv = context.read<TeamProvider>();

            if (isEditing) {
              final updated = widget.teamToEdit!.copyWith(
                name: _nameController.text.trim(),
                shortName: _shortNameController.text.trim().toUpperCase(),
                colorValue: _selectedColor,
              );
              await teamProv.updateTeam(updated);
              if (mounted) Navigator.of(context).pop(updated);
            } else {
              final created = await teamProv.createTeam(
                name: _nameController.text.trim(),
                shortName: _shortNameController.text.trim().toUpperCase(),
                colorValue: _selectedColor,
              );
              if (mounted) Navigator.of(context).pop(created);
            }
          },
        ),
      ],
    );
  }
}
