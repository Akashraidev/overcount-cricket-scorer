import 'dart:math';

class CommentaryGenerator {
  CommentaryGenerator._();

  static final Random _rnd = Random();

  static String generateCommentary({
    required String bowlerName,
    required String batsmanName,
    required int runs,
    required String extraType,
    required int extraRuns,
    required bool isWicket,
    String? wicketType,
    String? fielderName,
  }) {
    if (isWicket) {
      switch (wicketType?.toLowerCase()) {
        case 'bowled':
          final options = [
            'OUT! Clean bowled! Timber! $bowlerName rattles the stumps and $batsmanName has to walk back.',
            'WICKET! Bowled him! What a peach of a delivery from $bowlerName! Middle stump knocked out.',
            'OUT! Chopped on! $batsmanName inside edges it straight onto the off stump. Huge blow!',
          ];
          return options[_rnd.nextInt(options.length)];

        case 'caught':
          if (fielderName != null && fielderName.isNotEmpty) {
            return 'OUT! Caught by $fielderName! $batsmanName looks to go big, but mistimes it straight to the fielder. $bowlerName strikes!';
          }
          return 'OUT! In the air and taken! $batsmanName is caught out, sharp fielding dismissal off $bowlerName.';

        case 'lbw':
          return 'OUT! Plumb in front! Huge appeal for LBW and the umpire raises the finger. $batsmanName is trapped right in front of middle stump.';

        case 'run out':
          final fielderText = (fielderName != null && fielderName.isNotEmpty) ? ' by $fielderName' : '';
          return 'OUT! RUN OUT$fielderText! Direct hit or quick glovework ends the stay of $batsmanName. Massive breakthrough!';

        case 'stumped':
          return 'OUT! Stumped! $batsmanName dances down the pitch, misses the turn and the wicketkeeper whips the bails off in a flash.';

        case 'hit wicket':
          return 'OUT! Hit wicket! $batsmanName steps too deep into the crease and dislodges the bails with the bat/heel.';

        case 'retired hurt':
          return '$batsmanName is retiring hurt due to injury and walks off the field.';

        case 'retired out':
          return '$batsmanName has retired out and walks off.';

        default:
          return 'OUT! WICKET! $batsmanName has been dismissed off the bowling of $bowlerName!';
      }
    }

    if (extraType.isNotEmpty && extraType != 'none') {
      switch (extraType.toLowerCase()) {
        case 'wide':
          return extraRuns > 1
              ? 'WIDE! Slipped down the leg side, runs away for ${extraRuns - 1} extra byes too.'
              : 'WIDE ball called by the umpire. Straying well outside the tramlines from $bowlerName.';
        case 'noball':
        case 'no ball':
          return 'NO BALL! Overstepping from $bowlerName. Free hit coming up!';
        case 'bye':
          return 'BYE! Misses bat and pad, the batters scamper through for $extraRuns bye${extraRuns > 1 ? 's' : ''}.';
        case 'legbye':
        case 'leg bye':
          return 'LEG BYE! Deflected off the pads into the gap for $extraRuns leg bye${extraRuns > 1 ? 's' : ''}.';
        case 'penalty':
          return 'PENALTY! 5 penalty runs awarded.';
      }
    }

    switch (runs) {
      case 0:
        final dots = [
          'No run. Good length ball on off stump, defended solidly by $batsmanName.',
          'Dot ball. Beaten outside off! $bowlerName beats the outside edge.',
          'No run. Pushed gently towards the cover fielder.',
          'Dot ball. Back of a length delivery, tucked straight to midwicket.',
          'No run. Well left outside off by $batsmanName.',
        ];
        return dots[_rnd.nextInt(dots.length)];

      case 1:
        final singles = [
          '1 run. Tucked away to square leg for a quick single.',
          '1 run. Pushed down to long-on for a comfortable single.',
          '1 run. Steered down to third man to rotate the strike.',
          '1 run. Dropped into the off-side gap and they hustle through for one.',
        ];
        return singles[_rnd.nextInt(singles.length)];

      case 2:
        final doubles = [
          '2 runs. Clipped into the deep mid-wicket pocket, excellent running between the wickets for a brace.',
          '2 runs. Driven through extra cover, good fielding prevents the boundary.',
        ];
        return doubles[_rnd.nextInt(doubles.length)];

      case 3:
        return '3 runs. Superb placement through backward point, long chase for the outfielders.';

      case 4:
        final fours = [
          'FOUR! Glorious cover drive! Timed to perfection, races away across the turf for four runs.',
          'FOUR! Hammered through mid-wicket! That made a delightful sound off the sweet spot.',
          'FOUR! Short and punished! $batsmanName rocks back and pulls it fiercely to the fence.',
          'FOUR! Edged and past the slips! Runs away to third man boundary.',
        ];
        return fours[_rnd.nextInt(fours.length)];

      case 5:
        return '5 runs! Overthrow at the striker end results in extra boundary runs!';

      case 6:
        final sixes = [
          'SIX! Out of the park! Clean swing of the willow and that clears the boundary with ease!',
          'SIX! Maximum! $batsmanName steps out and launches $bowlerName high into the stands!',
          'SIX! Magnificent pull shot! Dispatched deep over deep square leg for a massive six!',
        ];
        return sixes[_rnd.nextInt(sixes.length)];

      default:
        return '$runs runs scored by $batsmanName off $bowlerName.';
    }
  }
}
