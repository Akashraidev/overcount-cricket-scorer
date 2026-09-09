import 'package:flutter/material.dart';
import '../../../core/widgets/score_button.dart';

class ScoringKeypad extends StatelessWidget {
  final ValueChanged<int> onRunsPressed;
  final VoidCallback onWidePressed;
  final VoidCallback onNoBallPressed;
  final VoidCallback onByePressed;
  final VoidCallback onLegByePressed;
  final VoidCallback onPenaltyPressed;
  final VoidCallback onWicketPressed;
  final VoidCallback onUndoPressed;
  final VoidCallback onSwapStrike;
  final bool isEnabled;
  final bool isUndoEnabled;

  const ScoringKeypad({
    super.key,
    required this.onRunsPressed,
    required this.onWidePressed,
    required this.onNoBallPressed,
    required this.onByePressed,
    required this.onLegByePressed,
    required this.onPenaltyPressed,
    required this.onWicketPressed,
    required this.onUndoPressed,
    required this.onSwapStrike,
    this.isEnabled = true,
    this.isUndoEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row 1: [ 0 ] [ 1 ] [ 2 ]
        Row(
          children: [
            Expanded(child: ScoreButton(label: '0', subtitle: 'DOT', isEnabled: isEnabled, onPressed: () => onRunsPressed(0))),
            const SizedBox(width: 8),
            Expanded(child: ScoreButton(label: '1', subtitle: 'SINGLE', isEnabled: isEnabled, onPressed: () => onRunsPressed(1))),
            const SizedBox(width: 8),
            Expanded(child: ScoreButton(label: '2', subtitle: 'DOUBLE', isEnabled: isEnabled, onPressed: () => onRunsPressed(2))),
          ],
        ),
        const SizedBox(height: 8),

        // Row 2: [ 3 ] [ 4 ] [ 6 ]
        Row(
          children: [
            Expanded(child: ScoreButton(label: '3', subtitle: 'THREE', isEnabled: isEnabled, onPressed: () => onRunsPressed(3))),
            const SizedBox(width: 8),
            Expanded(
              child: ScoreButton(
                label: '4',
                subtitle: 'FOUR',
                type: ScoreButtonType.boundary4,
                isEnabled: isEnabled,
                onPressed: () => onRunsPressed(4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ScoreButton(
                label: '6',
                subtitle: 'SIX',
                type: ScoreButtonType.boundary6,
                isEnabled: isEnabled,
                onPressed: () => onRunsPressed(6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Row 3: Extras [ WD ] [ NB ] [ BYE ] [ LB ]
        Row(
          children: [
            Expanded(
              child: ScoreButton(
                label: 'WD',
                subtitle: 'WIDE',
                type: ScoreButtonType.extra,
                isEnabled: isEnabled,
                onPressed: onWidePressed,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ScoreButton(
                label: 'NB',
                subtitle: 'NO BALL',
                type: ScoreButtonType.extra,
                isEnabled: isEnabled,
                onPressed: onNoBallPressed,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ScoreButton(
                label: 'BYE',
                subtitle: 'EXTRA',
                type: ScoreButtonType.utility,
                isEnabled: isEnabled,
                onPressed: onByePressed,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ScoreButton(
                label: 'LB',
                subtitle: 'LEG BYE',
                type: ScoreButtonType.utility,
                isEnabled: isEnabled,
                onPressed: onLegByePressed,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Row 4: [ 5 ] [ PENALTY ] [ SWAP STRIKE ]
        Row(
          children: [
            Expanded(
              flex: 1,
              child: ScoreButton(
                label: '5',
                subtitle: 'FIVE',
                type: ScoreButtonType.normal,
                isEnabled: isEnabled,
                onPressed: () => onRunsPressed(5),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: ScoreButton(
                label: '5 PENALTY',
                subtitle: 'AWARD',
                type: ScoreButtonType.extra,
                isEnabled: isEnabled,
                onPressed: onPenaltyPressed,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: ScoreButton(
                label: 'SWAP',
                subtitle: 'STRIKE',
                icon: Icons.swap_vert,
                type: ScoreButtonType.utility,
                isEnabled: isEnabled,
                onPressed: onSwapStrike,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Row 5: [ WICKET ] [ UNDO ]
        Row(
          children: [
            Expanded(
              flex: 3,
              child: ScoreButton(
                label: 'WICKET !',
                type: ScoreButtonType.wicket,
                height: 56,
                isEnabled: isEnabled,
                onPressed: onWicketPressed,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: ScoreButton(
                label: 'UNDO',
                icon: Icons.undo_rounded,
                type: ScoreButtonType.undo,
                height: 56,
                isEnabled: isUndoEnabled,
                onPressed: onUndoPressed,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
