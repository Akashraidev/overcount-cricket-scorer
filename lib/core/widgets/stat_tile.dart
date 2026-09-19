import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import 'app_card.dart';

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? accentColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.icon,
    this.accentColor,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accentColor ?? AppColors.primary;

    return AppCard(
      onTap: onTap,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isHeightConstrained = constraints.maxHeight.isFinite;
          final valueWidget = FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.scoreDisplay.copyWith(
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          );

          return ClipRect(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: isHeightConstrained ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
              mainAxisSize: isHeightConstrained ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        label.toUpperCase(),
                        style: AppTextStyles.label.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (icon != null)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          icon,
                          size: 13,
                          color: color,
                        ),
                      ),
                  ],
                ),
                if (isHeightConstrained)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: valueWidget,
                    ),
                  )
                else ...[
                  const SizedBox(height: 2),
                  valueWidget,
                ],
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
