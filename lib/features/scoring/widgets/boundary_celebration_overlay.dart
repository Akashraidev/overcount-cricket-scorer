import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_text_styles.dart';
import '../scoring_provider.dart';

/// A polished, TV broadcast-inspired celebratory banner overlay for FOUR and SIX events.
///
/// Key design requirements:
/// - Strictly non-blocking: wrapped in [IgnorePointer] so live scoring is never interrupted or delayed.
/// - Self-dismissing after ~1200ms.
/// - Respects reduced-motion accessibility preference via [MediaQuery.disableAnimations].
/// - High-contrast broadcast ribbon styling with athletic typography and controlled red accents.
class BoundaryCelebrationOverlay extends StatefulWidget {
  final BoundaryCelebration? celebration;
  final VoidCallback? onDismiss;

  const BoundaryCelebrationOverlay({
    super.key,
    required this.celebration,
    this.onDismiss,
  });

  @override
  State<BoundaryCelebrationOverlay> createState() => _BoundaryCelebrationOverlayState();
}

class _BoundaryCelebrationOverlayState extends State<BoundaryCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _slideAnimation;
  int? _currentTimestamp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    );

    // Dynamic broadcast entrance, hold, and smooth exit
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.3, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.85)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 25,
      ),
    ]).animate(_controller);

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
    ]).animate(_controller);

    _slideAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 30.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -20.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 25,
      ),
    ]).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDismiss?.call();
      }
    });

    if (widget.celebration != null) {
      _currentTimestamp = widget.celebration!.timestamp;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant BoundaryCelebrationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.celebration != null &&
        widget.celebration!.timestamp != _currentTimestamp) {
      _currentTimestamp = widget.celebration!.timestamp;
      _controller.forward(from: 0.0);
    } else if (widget.celebration == null && oldWidget.celebration != null) {
      _currentTimestamp = null;
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.celebration == null && !_controller.isAnimating) {
      return const SizedBox.shrink();
    }

    final isReducedMotion = MediaQuery.of(context).disableAnimations;
    final celebration = widget.celebration;
    if (celebration == null) return const SizedBox.shrink();

    final isFour = celebration.type == BoundaryType.four;
    final title = isFour ? 'FOUR!' : 'SIX!';
    final subtitle = isFour ? 'BOUNDARY' : 'MAXIMUM';
    final primaryAccent = isFour ? AppColors.boundary4 : AppColors.boundary6;
    final brandRed = AppColors.primary;

    return IgnorePointer(
      ignoring: true, // Guarantees user taps ALWAYS pass through to the live scorer
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final scale = isReducedMotion ? 1.0 : _scaleAnimation.value;
            final opacity = isReducedMotion ? (_controller.isAnimating ? 1.0 : 0.0) : _fadeAnimation.value.clamp(0.0, 1.0);
            final translateY = isReducedMotion ? 0.0 : _slideAnimation.value;

            return Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(0, translateY),
                child: Transform.scale(
                  scale: scale,
                  child: child,
                ),
              ),
            );
          },
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              // Broadcast Ribbon Layering
              gradient: LinearGradient(
                colors: isFour
                    ? [
                        const Color(0xFF0F172A),
                        const Color(0xFF1E293B),
                        const Color(0xFF0F172A),
                      ]
                    : [
                        const Color(0xFF1E1035),
                        const Color(0xFF2E1065),
                        const Color(0xFF1E1035),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isFour ? AppColors.boundary4 : const Color(0xFFA855F7),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isFour ? AppColors.boundary4 : const Color(0xFFA855F7)).withValues(alpha: 0.45),
                  blurRadius: 28,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // TV Broadcast Accent Edge Ribbons
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            brandRed,
                            primaryAccent,
                            Colors.white,
                            primaryAccent,
                            brandRed,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            brandRed,
                            primaryAccent,
                            Colors.white,
                            primaryAccent,
                            brandRed,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Celebration Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Left Sports Icon
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryAccent.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primaryAccent.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            isFour ? Icons.sports_cricket_rounded : Icons.whatshot_rounded,
                            color: isFour ? Colors.white : const Color(0xFFFBBF24),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Title & Subtitle
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: AppTextStyles.scoreDisplay.copyWith(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                                shadows: [
                                  Shadow(
                                    color: (isFour ? AppColors.boundary4 : const Color(0xFFA855F7)).withValues(alpha: 0.8),
                                    blurRadius: 12,
                                  ),
                                  const Shadow(
                                    color: Colors.black,
                                    offset: Offset(1, 2),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: brandRed,
                                    borderRadius: AppRadius.roundedSm,
                                  ),
                                  child: Text(
                                    isFour ? '4 RUNS' : '6 RUNS',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  subtitle,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),

                        // Right Sports Icon / Flash
                        Icon(
                          Icons.auto_awesome,
                          color: isFour ? AppColors.primaryLight : const Color(0xFFFBBF24),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
