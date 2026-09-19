import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/models/match.dart';

class CancelMatchDialog extends StatefulWidget {
  final CricketMatch match;

  const CancelMatchDialog({
    super.key,
    required this.match,
  });

  static Future<String?> show(
    BuildContext context, {
    required CricketMatch match,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => CancelMatchDialog(match: match),
    );
  }

  @override
  State<CancelMatchDialog> createState() => _CancelMatchDialogState();
}

class _CancelMatchDialogState extends State<CancelMatchDialog> {
  static const List<Map<String, dynamic>> _reasons = [
    {
      'title': 'Rain Interruption',
      'icon': Icons.water_drop_outlined,
    },
    {
      'title': 'Fog / Poor Visibility',
      'icon': Icons.visibility_off_outlined,
    },
    {
      'title': 'Ground Conditions',
      'icon': Icons.landscape_outlined,
    },
    {
      'title': 'Technical Issue',
      'icon': Icons.build_circle_outlined,
    },
    {
      'title': 'Other',
      'icon': Icons.edit_note_outlined,
    },
  ];

  String _selectedReason = 'Rain Interruption';
  final TextEditingController _customReasonController = TextEditingController();
  final FocusNode _customReasonFocusNode = FocusNode();

  @override
  void dispose() {
    _customReasonController.dispose();
    _customReasonFocusNode.dispose();
    super.dispose();
  }

  void _onConfirm() {
    String finalReason = _selectedReason;
    if (_selectedReason == 'Other') {
      final customText = _customReasonController.text.trim();
      finalReason = customText.isNotEmpty ? customText : 'Unspecified Reason';
    }
    Navigator.of(context).pop(finalReason);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppDialog(
      title: 'Cancel Match?',
      subtitle: widget.match.title,
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.cancel_outlined,
          color: AppColors.error,
          size: 32,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Warning & explanation banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.lightSurfaceElevated,
                borderRadius: AppRadius.roundedMd,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This match will be stopped and marked as Cancelled. All scored balls, overs, runs, and player statistics up to this point will be safely preserved in history. The match will not be decided as a win or loss.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Select reason label
            Text(
              'Reason for Cancellation',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 10),

            // Predefined options
            ...List.generate(_reasons.length, (index) {
              final reason = _reasons[index];
              final String title = reason['title'] as String;
              final IconData icon = reason['icon'] as IconData;
              final bool isSelected = _selectedReason == title;

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedReason = title;
                    });
                    if (title == 'Other') {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _customReasonFocusNode.requestFocus();
                      });
                    }
                  },
                  borderRadius: AppRadius.roundedMd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.error.withValues(alpha: 0.12)
                          : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated),
                      borderRadius: AppRadius.roundedMd,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.error
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          size: 18,
                          color: isSelected
                              ? AppColors.error
                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.error
                                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: AppColors.error,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // Custom reason text field if "Other" is chosen
            if (_selectedReason == 'Other') ...[
              const SizedBox(height: 8),
              AppTextField(
                controller: _customReasonController,
                focusNode: _customReasonFocusNode,
                hint: 'Specify reason (e.g. Bad light, Pitch damage)...',
                maxLength: 60,
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
      actions: [
        AppButton(
          label: 'Go Back / Keep Match Running',
          variant: AppButtonVariant.secondary,
          isFullWidth: true,
          onPressed: () => Navigator.of(context).pop(null),
        ),
        const SizedBox(height: 8),
        AppButton(
          label: 'Cancel Match',
          icon: Icons.cancel_outlined,
          variant: AppButtonVariant.danger,
          isFullWidth: true,
          onPressed: _onConfirm,
        ),
      ],
    );
  }
}
