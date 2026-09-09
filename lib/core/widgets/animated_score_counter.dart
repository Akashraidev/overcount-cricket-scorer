import 'package:flutter/material.dart';
import '../constants/app_text_styles.dart';

class AnimatedScoreCounter extends StatelessWidget {
  final int count;
  final TextStyle? style;
  final Duration duration;

  const AnimatedScoreCounter({
    super.key,
    required this.count,
    this.style,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: Text(
        '$count',
        key: ValueKey<int>(count),
        style: style ?? AppTextStyles.scoreDisplay,
      ),
    );
  }
}
