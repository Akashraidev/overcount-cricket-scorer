import 'ball.dart';

class OverSummary {
  final int overNumber;
  final String bowlerName;
  final int runs;
  final int wickets;
  final List<Ball> balls;

  const OverSummary({
    required this.overNumber,
    required this.bowlerName,
    required this.runs,
    required this.wickets,
    required this.balls,
  });
}
