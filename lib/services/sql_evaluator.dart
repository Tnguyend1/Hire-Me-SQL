class SqlEvaluator {
  static String normalize(String sql) {
    return sql
        .toLowerCase()
        .replaceAll(';', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool isCorrect({
    required String userAnswer,
    required List<String> acceptedAnswers,
    List<String> requiredKeywords = const [],
  }) {
    final normalizedUser = normalize(userAnswer);

    for (final answer in acceptedAnswers) {
      final normalizedExpected = normalize(answer);
      if (normalizedUser == normalizedExpected) {
        return true;
      }
    }

    if (requiredKeywords.isNotEmpty) {
      final hasAllKeywords = requiredKeywords.every(
            (keyword) => normalizedUser.contains(keyword.toLowerCase()),
      );
      if (hasAllKeywords) {
        return true;
      }
    }

    return false;
  }
}