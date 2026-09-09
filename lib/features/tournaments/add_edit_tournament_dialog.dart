import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_dropdown.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/tournament.dart';
import '../teams/team_provider.dart';
import 'tournament_provider.dart';

class AddEditTournamentDialog extends StatefulWidget {
  final Tournament? tournamentToEdit;

  const AddEditTournamentDialog({super.key, this.tournamentToEdit});

  static Future<Tournament?> show(BuildContext context, {Tournament? tournamentToEdit}) {
    return showDialog<Tournament>(
      context: context,
      builder: (context) => AddEditTournamentDialog(tournamentToEdit: tournamentToEdit),
    );
  }

  @override
  State<AddEditTournamentDialog> createState() => _AddEditTournamentDialogState();
}

class _AddEditTournamentDialogState extends State<AddEditTournamentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String _format;
  late DateTime _startDate;
  DateTime? _endDate;
  final Set<String> _selectedTeamIds = {};

  final List<String> _formats = const ['T20', 'T10', 'ODI', 'Test', 'Custom'];

  @override
  void initState() {
    super.initState();
    final t = widget.tournamentToEdit;
    _nameController = TextEditingController(text: t?.name ?? '');
    _format = t?.format ?? 'T20';
    _startDate = t != null ? DateTime.fromMillisecondsSinceEpoch(t.startDate) : DateTime.now();
    if (t?.endDate != null) {
      _endDate = DateTime.fromMillisecondsSinceEpoch(t!.endDate!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.tournamentToEdit != null;
    final teams = context.watch<TeamProvider>().teams;

    return AppDialog(
      title: isEditing ? 'Edit Tournament' : 'Create Tournament',
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: 'Tournament Name',
              hint: 'e.g. Champions Trophy 2026',
              controller: _nameController,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Tournament name is required' : null,
            ),
            const SizedBox(height: 14),

            AppDropdown<String>(
              label: 'Format',
              value: _format,
              items: _formats.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _format = v);
              },
            ),
            const SizedBox(height: 14),

            // Start Date Picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Text(DateFormatter.formatDate(_startDate)),
              trailing: const Icon(Icons.calendar_today, size: 20),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
            ),

            if (!isEditing && teams.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Select Participating Teams', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView(
                  shrinkWrap: true,
                  children: teams.map((t) {
                    final isChecked = _selectedTeamIds.contains(t.id);
                    return CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(t.name),
                      value: isChecked,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedTeamIds.add(t.id);
                          } else {
                            _selectedTeamIds.remove(t.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
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
          label: isEditing ? 'Save' : 'Create',
          height: 40,
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            final tourneyProv = context.read<TournamentProvider>();

            if (isEditing) {
              final updated = widget.tournamentToEdit!.copyWith(
                name: _nameController.text.trim(),
                format: _format,
                startDate: _startDate.millisecondsSinceEpoch,
                endDate: _endDate?.millisecondsSinceEpoch,
              );
              await tourneyProv.updateTournament(updated);
              if (mounted) Navigator.of(context).pop(updated);
            } else {
              final created = await tourneyProv.createTournament(
                name: _nameController.text.trim(),
                format: _format,
                startDate: _startDate,
                endDate: _endDate,
                teamIds: _selectedTeamIds.toList(),
              );
              if (mounted) Navigator.of(context).pop(created);
            }
          },
        ),
      ],
    );
  }
}
