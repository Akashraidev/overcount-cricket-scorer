import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_text_styles.dart';

enum ScoreButtonType { normal, boundary4, boundary6, wicket, extra, utility, undo }

class ScoreButton extends StatefulWidget {
  final String label;
  final String? subtitle;
  final VoidCallback onPressed;
  final ScoreButtonType type;
  final double? height;
  final double? width;
  final IconData? icon;
  final bool isEnabled;

  const ScoreButton({
    super.key,
    required this.label,
    this.subtitle,
    required this.onPressed,
    this.type = ScoreButtonType.normal,
    this.height,
    this.width,
    this.icon,
    this.isEnabled = true,
  });

  @override
  State<ScoreButton> createState() => _ScoreButtonState();
}

class _ScoreButtonState extends State<ScoreButton> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (!widget.isEnabled) return;
    _animController.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    if (!widget.isEnabled) return;
    _animController.reverse();
    widget.onPressed();
  }

  void _handleTapCancel() {
    if (!widget.isEnabled) return;
    _animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;
    Border? border;

    switch (widget.type) {
      case ScoreButtonType.normal:
        bg = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated;
        fg = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        border = Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder);
        break;

      case ScoreButtonType.boundary4:
        bg = AppColors.boundary4;
        fg = Colors.white;
        break;

      case ScoreButtonType.boundary6:
        bg = AppColors.boundary6;
        fg = Colors.white;
        break;

      case ScoreButtonType.wicket:
        bg = AppColors.wicket;
        fg = Colors.white;
        break;

      case ScoreButtonType.extra:
        bg = isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7);
        fg = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
        border = Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4));
        break;

      case ScoreButtonType.utility:
        bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
        fg = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
        border = Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder);
        break;

      case ScoreButtonType.undo:
        bg = isDark ? const Color(0xFF3B1E28) : const Color(0xFFFFE4E6);
        fg = isDark ? const Color(0xFFFDA4AF) : const Color(0xFFE11D48);
        border = Border.all(color: const Color(0xFFF43F5E).withValues(alpha: 0.4));
        break;
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Opacity(
        opacity: widget.isEnabled ? 1.0 : 0.4,
        child: Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: Container(
            height: widget.height ?? 54,
            width: widget.width,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: AppRadius.roundedMd,
              border: border,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: widget.icon != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.icon, size: 20, color: fg),
                        const SizedBox(width: 6),
                        Text(
                          widget.label,
                          style: AppTextStyles.scoreSmall.copyWith(color: fg),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.label,
                          style: AppTextStyles.scoreMedium.copyWith(color: fg, fontSize: 20),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle!,
                            style: AppTextStyles.label.copyWith(
                              color: fg.withValues(alpha: 0.8),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    ),
  );
  }
}
