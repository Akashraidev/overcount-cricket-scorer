import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_text_styles.dart';

class ScoreBadge extends StatelessWidget {
  final String label;
  final double size;
  final bool isWicket;
  final bool isBoundary;
  final bool isExtra;
  final Color? customColor;
  final Color? customTextColor;

  const ScoreBadge({
    super.key,
    required this.label,
    this.size = 32,
    this.isWicket = false,
    this.isBoundary = false,
    this.isExtra = false,
    this.customColor,
    this.customTextColor,
  });

  factory ScoreBadge.fromBall({
    required int runs,
    required String extraType,
    required bool isWicket,
    double size = 32,
  }) {
    String text;
    Color color;
    Color textColor = Colors.white;

    if (isWicket) {
      text = 'W';
      color = AppColors.wicket;
    } else if (extraType.isNotEmpty && extraType != 'none') {
      switch (extraType.toLowerCase()) {
        case 'wide':
          text = runs > 1 ? '${runs}Wd' : 'Wd';
          color = AppColors.extraWide;
          break;
        case 'noball':
        case 'no ball':
          text = runs > 1 ? '${runs}Nb' : 'Nb';
          color = AppColors.extraNoBall;
          break;
        case 'bye':
          text = '${runs}B';
          color = AppColors.dotBall;
          break;
        case 'legbye':
        case 'leg bye':
          text = '${runs}Lb';
          color = AppColors.dotBall;
          break;
        case 'penalty':
          text = '${runs}P';
          color = AppColors.accent;
          break;
        default:
          text = '$runs';
          color = AppColors.dotBall;
      }
    } else {
      switch (runs) {
        case 0:
          text = '•';
          color = const Color(0xFF475569);
          break;
        case 1:
          text = '1';
          color = AppColors.single;
          break;
        case 2:
          text = '2';
          color = const Color(0xFF0D9488);
          break;
        case 3:
          text = '3';
          color = const Color(0xFF0284C7);
          break;
        case 4:
          text = '4';
          color = AppColors.boundary4;
          break;
        case 5:
          text = '5';
          color = const Color(0xFF0D9488);
          break;
        case 6:
          text = '6';
          color = AppColors.boundary6;
          break;
        default:
          text = '$runs';
          color = AppColors.dotBall;
      }
    }

    return ScoreBadge(
      label: text,
      size: size,
      customColor: color,
      customTextColor: textColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    Color bg = customColor ?? AppColors.dotBall;
    Color fg = customTextColor ?? Colors.white;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.roundedFull,
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: AppTextStyles.badgeText.copyWith(
          color: fg,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}
