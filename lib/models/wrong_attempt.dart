import 'problem.dart';

class WrongAttempt {
  final Problem problem;
  final String userAnswer;
  final DateTime date;
  bool isRetried;

  WrongAttempt({
    required this.problem,
    required this.userAnswer,
    required this.date,
    this.isRetried = false,
  });
}